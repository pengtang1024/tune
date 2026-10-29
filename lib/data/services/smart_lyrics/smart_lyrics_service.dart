import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission_audit.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_lrc.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/features/smart_lyrics/domain/channel_health.dart';
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

  /// The line numbers the pool still cannot agree on — where a system
  /// mark is made (docs/smart-lyrics.md §7.4).
  final List<int> disputedLines;

  /// The leave-one-out audit of this run's admitted lines: how many went
  /// on trial and how many rotations the machines caught wrong
  /// (docs/smart-lyrics.md §7.6, M11b). Zero trials is not a pass — it
  /// means no line had the four voices the audit needs.
  final int auditChecked;
  final int auditMismatched;

  final SmartLyricsFailure? failure;

  const SmartLyricsOutcome({
    required this.saved,
    this.cancelled = false,
    this.votes = 0,
    this.origins = const [],
    this.disputedLines = const [],
    this.auditChecked = 0,
    this.auditMismatched = 0,
    this.failure,
  });

  /// How many lines are left in dispute.
  int get disputed => disputedLines.length;

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

  /// The channel health rings: asked before every question, fed after
  /// every answer — a channel that keeps failing waits out the rounds
  /// without a reader tending the list (docs/smart-lyrics.md §7.2, M9).
  final ChannelHealthLedger? health;

  /// The text side: the correction of a draft and the knowledge vote.
  /// `null` when no text model is configured — the pool then votes on the
  /// drafts as they were read.
  final SmartTextAssist? assist;

  /// The chat models the knowledge rebuilds run on — one ballot each, so
  /// two different families can cross-prove a line (docs/smart-lyrics.md
  /// §7.6, M11c).
  final List<String> knowledgeModels;

  final StreamUrlResolver? resolver;
  final Dio _dio;

  SmartLyricsService({
    required this.engines,
    required this.humanPool,
    required this.paths,
    this.assist,
    this.knowledgeModels = const [],
    this.resolver,
    this.health,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Writes the agreed lines, and answers with the account of the vote.
  Future<SmartLyricsOutcome> _save(
    Song song,
    SmartConsensus consensus,
    List<String> origins,
    bool Function() stopped, {
    int auditChecked = 0,
    int auditMismatched = 0,
  }) async {
    if (stopped()) return const SmartLyricsOutcome.cancelled();
    final disputedLines = [
      for (var index = 0; index < consensus.lines.length; index++)
        if (consensus.lines[index].disputed) index,
    ];
    await paths.saveSmartLyrics(
      song,
      buildSmartLrc(consensus, origins: origins, at: DateTime.now()),
    );
    return SmartLyricsOutcome(
      saved: true,
      votes: consensus.votesCounted,
      origins: origins,
      disputedLines: disputedLines,
      auditChecked: auditChecked,
      auditMismatched: auditMismatched,
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

      final machine = await _machineVotes(song, audio, origins, stopped);
      votes.addAll(machine.votes);
      if (stopped()) return const SmartLyricsOutcome.cancelled();

      final knowledges = await _knowledgeVotes(song, origins, stopped);
      if (machine.votes.isEmpty) return _silenceOf(machine);
      if (stopped()) return const SmartLyricsOutcome.cancelled();

      final consensus = admit(votes, knowledge: knowledges);
      if (consensus.lines.isEmpty) {
        return const SmartLyricsOutcome.failed(SmartLyricsFailure.emptyResult);
      }
      // The leave-one-out audit rides along on every save: machines
      // judging machines, its account carried out with the sheet
      // (docs/smart-lyrics.md §7.6, M11b).
      final audit = auditAdmission(votes, knowledge: knowledges);
      Log.info(
        '准入审计: 受审=${audit.checked} 抓错=${audit.mismatched} '
        '上界=${audit.missRateUpperBound.toStringAsFixed(4)}',
      );
      return await _save(
        song,
        consensus,
        origins,
        stopped,
        auditChecked: audit.checked,
        auditMismatched: audit.mismatched,
      );
    } finally {
      if (temporary) await _discard(audio);
    }
  }

  /// The human pool, one sheet each. A source that fails or hands in a
  /// sheet without a timeline stays out — untimed words cannot vote on the
  /// lines of a timed song. A source under the health threshold is not
  /// asked at all this round.
  Future<List<LyricsBallot>> _humanVotes(Song song, List<String> origins) async {
    final votes = <LyricsBallot>[];
    for (final source in humanPool) {
      if (!_usable(source.name)) continue;
      try {
        final raw = await source.provider.lookup(song);
        if (raw == null || raw.trim().isEmpty) {
          _record(source.name, ChannelOutcome.empty);
          continue;
        }
        final ballot = _timedBallot(source.name, BallotKind.human, raw);
        if (ballot == null) {
          _record(source.name, ChannelOutcome.empty);
          continue;
        }
        votes.add(ballot);
        origins.add(source.name);
        _record(source.name, ChannelOutcome.success);
      } catch (error, stackTrace) {
        _record(source.name, ChannelOutcome.failure);
        Log.error('人写票源 ${source.name} 失败: $error', stackTrace);
      }
    }
    return votes;
  }

  /// Whether the health rings let [channelId] be asked this round.
  bool _usable(String channelId) =>
      health?.healthOf(channelId).usable ?? true;

  /// One answer lands in the ring.
  void _record(String channelId, ChannelOutcome outcome) =>
      health?.record(channelId, outcome);

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
      if (!_usable(engine.id)) continue;
      try {
        final result = await engine.transcribe(
          SmartAudioInput(
            audio: audio,
            title: song.title,
            artist: song.artist,
          ),
        );
        if (result.segments.isEmpty) {
          _record(engine.id, ChannelOutcome.empty);
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
        _record(engine.id, ChannelOutcome.success);
      } catch (error, stackTrace) {
        _record(engine.id, ChannelOutcome.failure);
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

  /// The knowledge votes: text only, never the audio — one ballot per
  /// configured chat model, so rebuilds of two different families can
  /// cross-prove a line (§7.6). A rebuild that says nothing, or says
  /// what cannot be read, keeps out of the pool.

  Future<List<LyricsBallot>> _knowledgeVotes(
    Song song,
    List<String> origins,
    bool Function() stopped,
  ) async {
    final assist = this.assist;
    if (assist == null) return const [];
    // A single configured model keeps its vote — one family, so the
    // knowledge class stays silent alone, but the ballot exists.
    final models = knowledgeModels.isEmpty ? [assist.model] : knowledgeModels;
    if (models.isEmpty) return const [];
    final votes = <LyricsBallot>[];
    for (final model in models) {
      if (stopped()) break;
      try {
        final sidekick = SmartTextAssist(client: assist.client, model: model);
        final lines = await sidekick.rebuildLyrics(
          title: song.title,
          artist: song.artist,
        );
        if (lines.isEmpty) continue;
        origins.add('knowledge:$model');
        votes.add(
          LyricsBallot(
            origin: 'knowledge:$model',
            kind: BallotKind.knowledge,
            lines: [
              for (final line in lines)
                BallotLine(start: Duration.zero, text: line),
            ],
          ),
        );
      } catch (error, stackTrace) {
        Log.error('知识票 $model 重建失败: $error', stackTrace);
      }
    }
    return votes;
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
