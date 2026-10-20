import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/cross_platform_music_scanner_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/providers/mpris_service_provider.dart';
import 'package:tune/data/services/providers/tray_service_provider.dart';
import 'package:tune/features/desktop/application/desktop_integration_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// The desktop integration of the player.
///
/// The provider wires the controller with the services of the desktop and
/// keeps it in step with the settings: the media controls follow the setting,
/// and the texts of the tray follow the language of the interface.
final desktopIntegrationProvider = Provider<DesktopIntegrationController>((
  ref,
) {
  final controller = DesktopIntegrationController(
    playback: ref.read(playbackControllerProvider.notifier),
    mpris: ref.read(mprisServiceProvider),
    tray: ref.read(trayServiceProvider),
    instance: ref.read(singleInstanceServiceProvider),
    settings: ref.read(settingsControllerProvider.notifier),
    scanner: ref.read(crossPlatformMusicScannerProvider),
    addToLibrary: (songs) async {
      await ref.read(libraryControllerProvider.notifier).addSongs(songs);
    },
  );
  ref.onDispose(controller.dispose);

  ref.listen(
    settingsControllerProvider.select((state) => state.mediaControlsEnabled),
    (previous, next) {
      controller.setMediaControlsEnabled(next);
    },
  );
  ref.listen(settingsControllerProvider.select((state) => state.locale), (
    previous,
    next,
  ) {
    controller.refreshTrayTexts();
  });

  return controller;
});
