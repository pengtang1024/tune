import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission_audit.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_consensus.dart';
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

  /// The program that turns a format the local engines cannot read into
  /// the 16 kHz mono WAV they can. Missing is not an error: the engines
  /// then try the original file and fail soft.
  final String ffmpegBinary;

  /// Set once the first download of this service cleaned the folders a
  /// killed run left behind.
  Future<void>? _cleaned;

  SmartLyricsService({
    required this.engines,
    required this.humanPool,
    required this.paths,
    this.assist,
    this.knowledgeModels = const [],
    this.resolver,
    this.health,
    this.ffmpegBinary = 'ffmpeg',
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
    try {
      await paths.saveSmartLyrics(
        song,
        buildSmartLrc(consensus, origins: origins, at: DateTime.now()),
      );
    } catch (error, stackTrace) {
      // A disk that refuses the sheet is a failed run, not a crash — and
      // never a half-written file.
      Log.error('写入智能词稿失败: $error', stackTrace);
      return const SmartLyricsOutcome.failed(SmartLyricsFailure.uploadFailed);
    }
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
      if (votes.isEmpty) {
        // No sheet anywhere: a channel that answered with silence heard
        // an instrumental; one that never answered failed. A human sheet
        // is never discarded because the machines stayed quiet — 每首有词.
        return _silenceOf(machine);
      }
      if (stopped()) return const SmartLyricsOutcome.cancelled();

      // Every song gets words: the pool hands in its best sheet — the
      // product promise is 每首有词 (M2–M8 semantics). Cross-proof from
      // independent families raises confidence and is recorded, but it
      // never blanks a line the pool could write.
      final consensus = voteOn(
        votes,
        knowledge: knowledges.isEmpty ? null : knowledges.first,
      );
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

  /// When each parked channel was last probed.
  final Map<String, DateTime> _probes = {};

  /// The parked channels a probe brought back this run.
  final Map<String, bool> _probeAlive = {};

  /// Consecutive failures per channel in this run.
  final Map<String, int> _failStreak = {};

  /// Whether the health rings let [channelId] be asked this round.
  ///
  /// The ring has no clock: a parked channel would never be asked again,
  /// so a binary installed after its failures could never come back. A
  /// parked channel gets one probe when the run starts, then at most one
  /// every ten minutes — cheap enough to forgive, rare enough not to
  /// spend a batch on a dead endpoint.
  bool _usable(String channelId) {
    final ledger = health;
    if (ledger == null) return true;
    if (_probeAlive[channelId] == true) return true;
    final healthNow = ledger.healthOf(channelId);
    if (healthNow.usable) return true;
    final now = DateTime.now();
    final last = _probes[channelId];
    if (last != null && now.difference(last) < _probeInterval) return false;
    _probes[channelId] = now;
    return true;
  }

  static const _probeInterval = Duration(minutes: 10);

  /// One answer lands in the ring.
  ///
  /// A probe that came back alive keeps the channel in the run even while
  /// the old failures still weigh the ring down — otherwise a batch would
  /// burn a whole queue waiting for the ring to climb back.
  void _record(String channelId, ChannelOutcome outcome) {
    health?.record(channelId, outcome);
    if (outcome == ChannelOutcome.failure) {
      // One bad file does not condemn a living channel: three failures in
      // a row do. A single m4a whisper cannot decode must not park the
      // channel for the rest of a 700-song queue.
      final streak = (_failStreak[channelId] ?? 0) + 1;
      _failStreak[channelId] = streak;
      if (streak >= _failStreakLimit) _probeAlive[channelId] = false;
      return;
    }
    _failStreak[channelId] = 0;
    if (_probes.containsKey(channelId)) _probeAlive[channelId] = true;
  }

  static const _failStreakLimit = 3;

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
        // A segment with no words is not a line: silence markers and
        // empty rows never reach the sheet.
        final rows = [
          for (final segment in result.segments)
            if (segment.text.trim().isNotEmpty) segment,
        ];
        if (rows.isEmpty) {
          _record(engine.id, ChannelOutcome.empty);
          empty++;
          continue;
        }

        final drafts = [for (final segment in rows) segment.text];
        final corrected = await _correctedDrafts(song, drafts);
        votes.add(
          LyricsBallot(
            origin: engine.id,
            kind: BallotKind.machine,
            lines: [
              for (var index = 0; index < rows.length; index++)
                BallotLine(start: rows[index].start, text: corrected[index]),
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
    if (local != null && local.isNotEmpty) {
      return _decoded(song, File(local), false);
    }
    // A live stream never ends: downloading it would fill the disk and
    // hang the batch on a song that has no fixed words.
    if (song.isLiveStream) return (null, false);

    await _cleanStaleAudioOnce();
    Directory? folder;
    try {
      final fresh = await resolver?.refresh(song) ?? song;
      final url = fresh.streamUrl ?? song.streamUrl;
      if (url == null || url.isEmpty) return (null, false);
      folder = await Directory.systemTemp.createTemp('tune_smart_audio');
      final file = File(path.join(folder.path, 'audio'));
      await _dio.download(url, file.path);
      return await _decoded(song, file, true);
    } catch (error, stackTrace) {
      Log.error('取音频失败: $error', stackTrace);
      // A download that died halfway leaves a folder of bytes behind: it
      // is the run's own mess, so the run cleans it.
      if (folder != null) await _discardFolder(folder);
      return (null, false);
    }
  }

  /// The audio as the local engines read it: 16 kHz mono WAV.
  ///
  /// whisper.cpp and sherpa-onnx both read WAV; an m4a podcast or an mp4
  /// makes them exit without words. ffmpeg is used when the machine has
  /// it — no bundle, no download — and a missing ffmpeg leaves the
  /// original file for the engines to try.
  Future<(File?, bool)> _decoded(
    Song song,
    File audio,
    bool temporary,
  ) async {
    final source = song.localFile ?? song.streamUrl ?? song.uri;
    final extension = path
        .extension(Uri.tryParse(source)?.path ?? source)
        .toLowerCase();
    if (extension == '.wav') return (audio, temporary);

    final folder = temporary
        ? audio.parent
        : await Directory.systemTemp.createTemp('tune_smart_audio');
    final wav = File(path.join(folder.path, 'decoded.wav'));
    try {
      final result = await Process.run(ffmpegBinary, [
        '-y',
        '-loglevel',
        'error',
        '-i',
        audio.path,
        '-ar',
        '16000',
        '-ac',
        '1',
        '-f',
        'wav',
        wav.path,
      ]);
      if (result.exitCode != 0 || !await wav.exists()) {
        if (!temporary) await _discardFolder(folder);
        return (audio, temporary);
      }
      return (wav, true);
    } catch (error, stackTrace) {
      Log.error('音频转码失败: $error', stackTrace);
      if (!temporary) await _discardFolder(folder);
      return (audio, temporary);
    }
  }

  /// Removes the `tune_smart_audio*` folders a killed run left behind.
  ///
  /// Only folders older than an hour are touched: a download of this run
  /// (or another instance) is fresh, and its folder is not ours to delete.
  Future<void> _cleanStaleAudioOnce() => _cleaned ??= _cleanStaleAudio();

  Future<void> _cleanStaleAudio() async {
    try {
      final now = DateTime.now();
      await for (final entity in Directory.systemTemp.list()) {
        if (entity is! Directory) continue;
        final name = path.basename(entity.path);
        if (!name.startsWith('tune_smart_audio')) continue;
        final modified = (await entity.stat()).modified;
        if (now.difference(modified) < const Duration(hours: 1)) continue;
        await entity.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      Log.error('残留临时音频清理失败: $error', stackTrace);
    }
  }

  Future<void> _discard(File audio) => _discardFolder(audio.parent);

  Future<void> _discardFolder(Directory folder) async {
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (error) {
      Log.error('临时音频清理失败: $error');
    }
  }
}
