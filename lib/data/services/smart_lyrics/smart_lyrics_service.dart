import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_consensus.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_lrc.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/data/services/stream_url_resolver.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/utils/logger.dart';

/// Why a run came home without a sheet.
enum SmartLyricsFailure {
  /// The audio never arrived: no local file, no copy, no stream to pull.
  noAudio,

  /// The channels that were asked did not answer.
  uploadFailed,

  /// The channels heard no words — the silence of an instrumental.
  emptyResult,
}

/// How a run ended.
class SmartLyricsOutcome {
  final bool saved;
  final bool cancelled;
  final int votes;
  final List<String> origins;
  final int disputed;
  final SmartLyricsFailure? failure;

  const SmartLyricsOutcome({
    required this.saved,
    this.cancelled = false,
    this.votes = 0,
    this.origins = const [],
    this.disputed = 0,
    this.failure,
  });

  const SmartLyricsOutcome.cancelled() : this(saved: false, cancelled: true);

  const SmartLyricsOutcome.failed(SmartLyricsFailure failure)
    : this(saved: false, failure: failure);
}

/// The single-song loop of the smart lyrics pipeline (docs/smart-lyrics.md
/// §7.1): the human pool first, the machine channels next, the knowledge
/// vote as the last ball, and one write at the very end — a run that dies
/// on the way leaves no half sheet behind.
class SmartLyricsService {
  final List<SmartLyricsEngine> engines;

  /// The sheets people wrote: one vote each, the heaviest ones.
  final List<({String name, LyricsProvider provider})> humanPool;
  final LibraryPaths paths;

  /// The text side: the correction of a draft and the knowledge vote.
  /// `null` when no text model is configured — the pool then votes on the
  /// drafts as they were read.
  final SmartTextAssist? assist;
  final StreamUrlResolver? resolver;
  final Dio _dio;

  SmartLyricsService({
    required this.engines,
    required this.humanPool,
    required this.paths,
    this.assist,
    this.resolver,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Writes the agreed lines, and answers with the account of the vote.
  Future<SmartLyricsOutcome> _save(
    Song song,
    SmartConsensus consensus,
    List<String> origins,
    bool Function() stopped,
  ) async {
    if (stopped()) return const SmartLyricsOutcome.cancelled();
    final disputed = consensus.lines.where((line) => line.disputed).length;
    await paths.saveSmartLyrics(
      song,
      buildSmartLrc(consensus, origins: origins, at: DateTime.now()),
    );
    return SmartLyricsOutcome(
      saved: true,
      votes: consensus.votesCounted,
      origins: origins,
      disputed: disputed,
    );
  }

  Future<SmartLyricsOutcome> generate(
    Song song, {
    bool Function()? cancelled,
  }) async {
    final stopped = cancelled ?? () => false;
    final (audio, temporary) = await _audioFor(song);
    if (audio == null) {
      return const SmartLyricsOutcome.failed(SmartLyricsFailure.noAudio);
    }

    try {
      final origins = <String>[];
      final votes = await _humanVotes(song, origins);

      // Enough human votes that agree on every line: the cheap way home.
      if (votes.length >= 3) {
        final consensus = voteOn(votes);
        if (!_hasDisputed(consensus)) {
          return await _save(song, consensus, origins, stopped);
        }
      }

      final machine = await _machineVotes(song, audio, origins, stopped);
      votes.addAll(machine.votes);
      if (stopped()) return const SmartLyricsOutcome.cancelled();

      final knowledge = await _knowledgeVote(song, origins, stopped);
      if (machine.votes.isEmpty) return _silenceOf(machine);
      if (stopped()) return const SmartLyricsOutcome.cancelled();

      final consensus = voteOn(votes, knowledge: knowledge);
      if (consensus.lines.isEmpty) {
        return const SmartLyricsOutcome.failed(SmartLyricsFailure.emptyResult);
      }
      return await _save(song, consensus, origins, stopped);
    } finally {
      if (temporary) await _discard(audio);
    }
  }

  /// The human pool, one sheet each. A source that fails or hands in a
  /// sheet without a timeline stays out — untimed words cannot vote on the
  /// lines of a timed song.
  Future<List<LyricsBallot>> _humanVotes(Song song, List<String> origins) async {
    final votes = <LyricsBallot>[];
    for (final source in humanPool) {
      try {
        final raw = await source.provider.lookup(song);
        if (raw == null || raw.trim().isEmpty) continue;
        final ballot = _timedBallot(source.name, BallotKind.human, raw);
        if (ballot == null) continue;
        votes.add(ballot);
        origins.add(source.name);
      } catch (error, stackTrace) {
        Log.error('人写票源 ${source.name} 失败: $error', stackTrace);
      }
    }
    return votes;
  }

  /// The machine channels, one pass each, every draft corrected before it
  /// joins the pool. A channel that fails is skipped — the others still
  /// vote, and a run with no channel left is reported, not hidden.
  Future<({List<LyricsBallot> votes, int empty, int failed})> _machineVotes(
    Song song,
    File audio,
    List<String> origins,
    bool Function() stopped,
  ) async {
    final votes = <LyricsBallot>[];
    var empty = 0;
    var failed = 0;
    for (final engine in engines) {
      if (stopped()) break;
      try {
        final result = await engine.transcribe(
          SmartAudioInput(
            audio: audio,
            title: song.title,
            artist: song.artist,
          ),
        );
        if (result.segments.isEmpty) {
          empty++;
          continue;
        }

        final drafts = [
          for (final segment in result.segments) segment.text,
        ];
        final corrected = await _correctedDrafts(song, drafts);
        votes.add(
          LyricsBallot(
            origin: engine.id,
            kind: BallotKind.machine,
            lines: [
              for (var index = 0; index < result.segments.length; index++)
                BallotLine(
                  start: result.segments[index].start,
                  text: corrected[index],
                ),
            ],
          ),
        );
        origins.add(engine.id);
      } catch (error, stackTrace) {
        failed++;
        Log.error('通道 ${engine.id} 转写失败: $error', stackTrace);
      }
    }
    return (votes: votes, empty: empty, failed: failed);
  }

  /// The correction pass; when it cannot keep the line count, the draft
  /// votes as it was read — a correction is an improvement, never a gate.
  Future<List<String>> _correctedDrafts(Song song, List<String> drafts) async {
    final corrector = assist;
    if (corrector == null || drafts.isEmpty) return drafts;
    try {
      return await corrector.correctLines(
        title: song.title,
        artist: song.artist,
        lines: drafts,
      );
    } catch (error, stackTrace) {
      Log.error('纠错失败，按原稿入池: $error', stackTrace);
      return drafts;
    }
  }

  /// The knowledge vote: text only, never the audio. A rebuild that says
  /// nothing, or says what cannot be read, keeps out of the pool.
  Future<LyricsBallot?> _knowledgeVote(
    Song song,
    List<String> origins,
    bool Function() stopped,
  ) async {
    final corrector = assist;
    if (corrector == null || stopped()) return null;
    try {
      final lines = await corrector.rebuildLyrics(
        title: song.title,
        artist: song.artist,
      );
      if (lines.isEmpty) return null;
      origins.add('knowledge');
      return LyricsBallot(
        origin: 'knowledge',
        kind: BallotKind.knowledge,
        lines: [
          for (final line in lines)
            BallotLine(start: Duration.zero, text: line),
        ],
      );
    } catch (error, stackTrace) {
      Log.error('知识票重建失败: $error', stackTrace);
      return null;
    }
  }

  /// What it means that no vote came home: a channel that answered with
  /// silence heard an instrumental; a channel that never answered failed.
  SmartLyricsOutcome _silenceOf(
    ({List<LyricsBallot> votes, int empty, int failed}) machine,
  ) => machine.empty > 0
      ? const SmartLyricsOutcome.failed(SmartLyricsFailure.emptyResult)
      : const SmartLyricsOutcome.failed(SmartLyricsFailure.uploadFailed);

  /// A ballot of the timed lines of a sheet; `null` when none carry a time.
  LyricsBallot? _timedBallot(String origin, BallotKind kind, String raw) {
    final document = LyricsDocument.parse(raw);
    final timed = [
      for (final line in document.lines)
        if (line.time != null)
          BallotLine(start: line.time!, text: line.text),
    ];
    if (timed.isEmpty) return null;
    return LyricsBallot(origin: origin, kind: kind, lines: timed);
  }

  bool _hasDisputed(SmartConsensus consensus) =>
      consensus.lines.any((line) => line.disputed);

  /// The audio of [song]: the file it is on this machine, or the stream
  /// pulled into a temporary file that the run deletes when it is done.
  Future<(File?, bool)> _audioFor(Song song) async {
    final local = song.localFile;
    if (local != null && local.isNotEmpty) return (File(local), false);

    try {
      final fresh = await resolver?.refresh(song) ?? song;
      final url = fresh.streamUrl ?? song.streamUrl;
      if (url == null || url.isEmpty) return (null, false);
      final folder = await Directory.systemTemp.createTemp('tune_smart_audio');
      final file = File(path.join(folder.path, 'audio'));
      await _dio.download(url, file.path);
      return (file, true);
    } catch (error, stackTrace) {
      Log.error('取音频失败: $error', stackTrace);
      return (null, false);
    }
  }

  Future<void> _discard(File audio) async {
    try {
      final folder = audio.parent;
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (error) {
      Log.error('临时音频清理失败: $error');
    }
  }
}
