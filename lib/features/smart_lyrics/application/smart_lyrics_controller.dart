import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/providers/stream_url_resolver_provider.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';
import 'package:tune/data/services/smart_lyrics/whisper_local_engine.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run.dart';

/// The service the pipeline runs through, built from what the reader
/// pasted: one channel per transcription model, the text model for the
/// correction and the knowledge vote, the shared libraries as the human
/// pool. A change of the config builds the next run on the new voices.
final smartLyricsServiceProvider = Provider<SmartLyricsService>((ref) {
  final config = ref.watch(
    settingsControllerProvider.select((state) => state.smartLyrics),
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
  ref.onDispose(dio.close);
  final client = OpenAiCompatibleClient(
    dio: dio,
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
  );

  // The local channel votes when a model was named for it: a binary the
  // system already has first, the downloaded one as the fallback. The
  // folders are resolved once per run of the pipeline, not per song.
  final localModel = config.localModel.trim();
  final assets = Future<WhisperAssets>.sync(WhisperAssets.appDefault);

  return SmartLyricsService(
    engines: [
      for (final model in config.asrModels)
        OpenAiCompatibleEngine(model: model, client: client),
      if (localModel.isNotEmpty)
        WhisperLocalEngine(
          model: localModel,
          binaryOf: () async => (await assets).findBinary(),
          modelOf: () async => (await assets).findModel(localModel),
          workspaceOf: () async => (await assets).workspace(),
        ),
    ],
    humanPool: [(name: 'lrclib', provider: sources.lyricsProvider)],
    paths: paths,
    assist: config.chatModel.trim().isEmpty
        ? null
        : SmartTextAssist(client: client, model: config.chatModel),
    resolver: resolver,
  );
});

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
  Future<void> generate(Song song) async {
    if (state.phase == SmartLyricsPhase.running) return;
    _cancelled = false;
    state = SmartLyricsRun(
      phase: SmartLyricsPhase.running,
      songId: song.id,
    );

    final outcome = await ref
        .read(smartLyricsServiceProvider)
        .generate(song, cancelled: () => _cancelled);
    if (_cancelled) {
      state = const SmartLyricsRun();
      return;
    }

    if (outcome.saved) {
      // The sheet is on the disk; the panel learns it the way every sheet
      // does — the controller reads again and the memory forgets the gap.
      ref.read(lyricsMemoryProvider).forget(song);
      ref.invalidate(lyricsControllerProvider);
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
  }

  /// Stops the run between two votes; nothing half-written stays behind.
  ///
  /// A channel that is mid-pass is asked to stop with it — a local
  /// transcription that would keep chewing minutes of CPU is killed where
  /// it stands.
  void cancel() {
    _cancelled = true;
    final engines = ref.read(smartLyricsServiceProvider).engines;
    for (final engine in engines) {
      engine.requestCancel();
    }
  }
}
