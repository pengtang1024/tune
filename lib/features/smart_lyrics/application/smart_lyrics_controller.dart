import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/stream_url_resolver_provider.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/sherpa_local_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';
import 'package:tune/data/services/smart_lyrics/whisper_local_engine.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run_lock.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_channel_health_store.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

/// The channel health rings the pipeline asks before every question and
/// feeds after every answer — one store, one preference file, shared by
/// every service that runs the pool (docs/smart-lyrics.md §7.2, M9).
final smartLyricsChannelHealthProvider = Provider<SmartLyricsChannelHealthStore>(
  (ref) => SmartLyricsChannelHealthStore(
    ref.watch(persistenceServiceProvider),
  ),
);

/// The service the pipeline runs through, built from what the reader
/// pasted: one channel per transcription model, the text model for the
/// correction and the knowledge vote, the shared libraries as the human
/// pool. A change of the config builds the next run on the new voices.
final smartLyricsServiceProvider = Provider<SmartLyricsService>((ref) {
  // Watch the fields the service actually reads: watching the whole
  // config rebuilt the service on every unrelated keystroke.
  final (baseUrl, apiKey, asrModels, chatModel, localModel) = ref.watch(
    settingsControllerProvider.select(
      (state) => (
        state.smartLyrics.baseUrl,
        state.smartLyrics.apiKey,
        state.smartLyrics.asrModels,
        state.smartLyrics.chatModel,
        state.smartLyrics.localModel,
      ),
    ),
  );
  final sources = ref.watch(musicSourceServiceProvider);
  final paths = ref.watch(libraryPathsProvider);
  final resolver = ref.watch(streamUrlResolverProvider);

  final dio = Dio(
    BaseOptions(
      // A whole song travels: the endpoint may take a while to answer.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 10),
    ),
  );
  // The Dio is not closed here: a config edit rebuilds the provider while
  // a run may still be on the wire, and closing the client under it would
  // abort a request the run still needs. One client per config edit is a
  // bounded cost; a killed request is a lost song.
  final client = OpenAiCompatibleClient(
    dio: dio,
    baseUrl: baseUrl,
    apiKey: apiKey,
  );

  // The local channel votes when a model was named for it: a binary the
  // system already has first, the downloaded one as the fallback. The
  // folders are resolved once per run of the pipeline, not per song.
  final local = localModel.trim();
  // Without a key the default endpoints answer 401 on every song; a
  // keyless local endpoint is the one exception worth asking.
  final cloud =
      apiKey.trim().isNotEmpty ||
      baseUrl.contains('localhost') ||
      baseUrl.contains('127.0.0.1');
  final chatModelList = [
    for (final model in chatModel.split(','))
      if (model.trim().isNotEmpty) model.trim(),
  ];
  final assets = Future<WhisperAssets>.sync(WhisperAssets.appDefault);

  return SmartLyricsService(
    engines: [
      if (cloud)
        for (final model in asrModels)
          OpenAiCompatibleEngine(model: model, client: client),
      // The second, independent ASR family (M12): SenseVoice via
      // sherpa-onnx when it is installed — a free vote whose lineage
      // (sensevoice) is a different algorithm from whisper's, so the two
      // can cross-prove a line. Absent install: the channel fails soft
      // and the health rings park it.
      SherpaLocalEngine(
        model: 'sensevoice',
        binaryOf: () async {
          final file = File(
            '${Platform.environment['HOME'] ?? ''}'
            '/.local/opt/sherpa-onnx/bin/sherpa-onnx-offline',
          );
          return await file.exists() ? file : null;
        },
        modelDirOf: () async {
          final dir = Directory(
            '${Platform.environment['HOME'] ?? ''}'
            '/.local/opt/sherpa-onnx/models/sense-voice',
          );
          return await dir.exists() ? dir : null;
        },
      ),
      if (local.isNotEmpty)
        WhisperLocalEngine(
          model: local,
          binaryOf: () async => (await assets).findBinary(),
          modelOf: () async => (await assets).findModel(local),
          workspaceOf: () async => (await assets).workspace(),
        ),
    ],
    humanPool: [(name: 'lrclib', provider: sources.lyricsProvider)],
    paths: paths,
    health: ref.watch(smartLyricsChannelHealthProvider),
    // The correction runs on the first model; every listed model casts a
    // knowledge ballot — two families make the class speak (§7.6).
    assist: !cloud || chatModelList.isEmpty
        ? null
        : SmartTextAssist(client: client, model: chatModelList.first),
    knowledgeModels: cloud ? chatModelList : const [],
    resolver: resolver,
  );
});

/// Lets the lyrics panel learn a sheet that landed outside its own button.
///
/// A batch track or a leak-check song is written straight to the disk; the
/// panel holds the answer it read earlier in the session, so it would keep
/// saying「没有词」until the reader reopens the page. Forgetting the memory
/// is enough; the panel is invalidated only when the sheet is the track
/// playing, so a long batch does not reload it for every other song.
void refreshLyricsPanel(Ref ref, Song song) {
  ref.read(lyricsMemoryProvider).forget(song);
  unawaited(_markLedger(ref, song));
  final current = ref.read(
    playbackControllerProvider.select((state) => state.currentSong?.id),
  );
  if (current == song.id) ref.invalidate(lyricsControllerProvider);
}

/// Moves the coverage number the moment a sheet lands.
Future<void> _markLedger(Ref ref, Song song) async {
  try {
    final database = await ref.read(appDatabaseProvider.future);
    database.markSongHasLyrics(song.id);
  } catch (error, stackTrace) {
    Log.error('歌词账本更新失败: $error', stackTrace);
  }
  ref.invalidate(smartLyricsLedgerProvider);
}

/// The progress of the smart pipeline's single-song run.
///
/// The controller holds the progress alone; the sheet itself lands in the
/// file next to the audio and shows up through [LyricsController], so no
/// second copy of the lyrics exists.
final smartLyricsControllerProvider =
    NotifierProvider<SmartLyricsController, SmartLyricsRun>(
      SmartLyricsController.new,
    );

class SmartLyricsController extends Notifier<SmartLyricsRun> {
  bool _cancelled = false;

  /// The service this run holds: cancel kills these engines, not the ones
  /// a later config edit built.
  SmartLyricsService? _service;

  @override
  SmartLyricsRun build() {
    // The progress belongs to the track that plays: when it changes, the
    // old run's state is of nobody's interest any more.
    ref.listen(
      playbackControllerProvider.select((state) => state.currentSong?.id),
      (previous, next) {
        if (previous != next) state = const SmartLyricsRun();
      },
    );
    return const SmartLyricsRun();
  }

  /// Generates the lyrics of [song] with the pipeline as configured.
  ///
  /// The batch holds the same engines; the run lock makes the two doors
  /// take turns instead of corrupting each other's whisper output.
  Future<void> generate(Song song) async {
    final lock = ref.read(smartLyricsRunLockProvider);
    if (!lock.claimPanel()) return;
    _cancelled = false;
    final service = ref.read(smartLyricsServiceProvider);
    _service = service;
    state = SmartLyricsRun(
      phase: SmartLyricsPhase.running,
      songId: song.id,
    );

    try {
      final outcome = await service.generate(
        song,
        cancelled: () => _cancelled,
      );
      if (_cancelled) {
        state = const SmartLyricsRun();
        return;
      }

      if (outcome.saved) {
        // The sheet is on the disk; the panel learns it the way every
        // sheet does — the controller reads again and the memory forgets
        // the gap.
        refreshLyricsPanel(ref, song);
        state = SmartLyricsRun(
          phase: SmartLyricsPhase.done,
          songId: song.id,
        );
      } else {
        state = SmartLyricsRun(
          phase: SmartLyricsPhase.failed,
          songId: song.id,
          failure: outcome.failure,
        );
      }
    } catch (error, stackTrace) {
      // A run that dies on the way must not leave the button greyed for
      // the rest of the session.
      Log.error('智能歌词单曲失败: $error', stackTrace);
      state = SmartLyricsRun(
        phase: SmartLyricsPhase.failed,
        songId: song.id,
        failure: SmartLyricsFailure.uploadFailed,
      );
    } finally {
      _service = null;
      lock.releasePanel();
    }
  }

  /// Stops the run between two votes; nothing half-written stays behind.
  ///
  /// A channel that is mid-pass is asked to stop with it — a local
  /// transcription that would keep chewing minutes of CPU is killed where
  /// it stands.
  void cancel() {
    _cancelled = true;
    final service = _service;
    if (service == null) return;
    for (final engine in service.engines) {
      engine.requestCancel();
    }
  }
}
