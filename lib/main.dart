import 'dart:async';
import 'dart:ui';

import 'package:tune/features/library/application/hidden_sources_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/player/application/playback_overview_provider.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/application/source_health_reports.dart';
import 'package:tune/features/sources/domain/source_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/app.dart';
import 'package:tune/app/licenses.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/impl/preference_store_io.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/translation/translation_key_store.dart';
import 'package:tune/features/player/application/tune_audio_handler.dart';
import 'package:tune/features/settings/application/mobile_permissions_controller.dart';
import 'package:tune/features/settings/application/update_scheduler_provider.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_auto_fill_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_leak_check_controller.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/utils/logger.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerThirdPartyLicenses();

  // The preferences are read while the window is still warming up: the first
  // screen asks for them, and waiting for the disk after the first frame
  // spends the warm-up twice instead of once.
  final persistence = createPersistenceService();
  final persistenceReady = persistence.init();
  persistenceReady.ignore();

  // The keys of the translation vendors live in their own file, and the
  // settings are built from them: reading the file first closes the gap
  // between a settings object and its keys, and the file is a few lines.
  final keyStore = TranslationKeyStore();
  await keyStore.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Log.error(
      'Flutter未捕获错误: ${details.exceptionAsString()}\n'
      '${details.stack?.toString() ?? ''}',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Log.error('平台层未捕获错误: $error\n$stack');
    return true;
  };

  final container = ProviderContainer(
    overrides: [
      persistenceServiceProvider.overrideWithValue(persistence),
      translationKeyStoreProvider.overrideWithValue(keyStore),
      // The Windows runner hands the command line to `main`; Linux reads it
      // from `/proc`, so the words are only used where they arrive.
      startupArgumentsProvider.overrideWithValue(arguments),
      // The health gate reads settings, the scan history and what is playing;
      // the page only asks for the answer, so the rule stays in one place.
      libraryHiddenSourcesProvider.overrideWith((ref) {
        final settings = ref.watch(settingsControllerProvider);
        if (!settings.hideUnhealthySources) return const <String>{};
        final sources = ref
            .watch(musicSourcesControllerProvider)
            .valueOrNull;
        if (sources == null || sources.sources.isEmpty) {
          return const <String>{};
        }
        final reports = ref.watch(sourceHealthReportsProvider);
        if (reports.isEmpty) return const <String>{};
        final state = ref.watch(libraryControllerProvider).valueOrNull;
        return SourceVisibility(
          threshold: settings.healthGateThreshold,
          alwaysVisible: settings.alwaysVisibleSources,
          playingSourceId: ref.watch(playbackOverviewProvider).currentSong
              ?.sourceId,
        ).hiddenOf(
          reports: reports,
          localSourceIds: {
            for (final source in sources.sources)
              if (source.isLocal) source.id,
          },
          sourcesWithTracks: (state?.sourceFacts ?? const {}).keys.toSet(),
          sourcesWithEvidence: (state?.sourceSummaries ?? const {}).keys.toSet(),
          libraryIsEmpty: (state?.sourceFacts ?? const {}).isEmpty,
        );
      }),
    ],
  );
  if (!await _claimThePlayerPlace(container)) {
    // Another player is already running; it got the files and the window.
    container.dispose();
    // The engine of the desktop keeps the process alive after the main
    // function is done, so this start ends the process by itself.
    await SystemNavigator.pop();
    return;
  }

  // Android keeps the sound alive after the interface is gone. The service
  // has to exist before the first frame: it creates the media session and the
  // notification channel, and the notification of a playing track cannot be
  // shown without them.
  final audioHandler = PlatformConstants.isAndroid
      ? await TuneAudioHandler.start()
      : null;

  runApp(
    UncontrolledProviderScope(container: container, child: const TuneApp()),
  );

  // The handler mirrors the state after the first frame: the controller
  // restores the session and reads the preferences, which are still warming
  // up while the service starts.
  audioHandler?.attach(container);

  // Android 13 and newer hide the notification of the service until the
  // reader allows it. The dialog needs a frame to sit on, so it is asked
  // once after the first one; a refusal is remembered by the system and the
  // settings page offers the way back.
  if (PlatformConstants.isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        container
            .read(mobilePermissionsControllerProvider.notifier)
            .ensure(MobilePermission.notifications),
      );
    });
  }

  // The free check of the smart lyrics pipeline (docs/smart-lyrics.md
  // §7.2): periodic, quiet, and free — the loop it lives in starts once,
  // here, and every tick decides for itself whether the machine is idle
  // enough to ask the human pool again.
  container.read(smartLyricsLeakCheckControllerProvider).start();

  // The library fills itself (2026-10-29 用户拍板): with the toggle on —
  // and it is on by default — the batch drains the gap until every song
  // carries words. No button, no queue-watching; the toggle closes the
  // door and the loop walks through it.
  container.read(smartLyricsAutoFillControllerProvider).start();

  // The update check (docs/update-cdn.md §4.3): a minute after start, then
  // every hour with jitter, backing off when the sources cannot be
  // reached. It reads the static list, so it no longer spends the anonymous
  // requests of the GitHub API.
  container.read(updateSchedulerProvider).start();
}

/// Takes the place of the player on the machine.
///
/// The place on the bus belongs to one player. A start that finds the place
/// taken hands its files over to the running player and leaves, so the
/// machine never has two players fighting over the sound card.
Future<bool> _claimThePlayerPlace(ProviderContainer container) async {
  final service = container.read(singleInstanceServiceProvider);

  final holdsPlace = await service.acquire();
  final files = service.startupFiles;
  if (files.isNotEmpty) Log.debug('命令行里的文件: $files');

  if (!holdsPlace) {
    Log.info('已有播放器在运行，把文件交给它');
    await service.forwardFiles(files);
    await service.forwardActivation();
    return false;
  }

  service.requestFiles(files);
  return true;
}
