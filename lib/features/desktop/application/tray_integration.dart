import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';

/// The menu of the tray icon, in the language of the interface.
List<TrayMenuEntry> buildTrayMenu() {
  final strings = AppStrings.instance;
  return [
    TrayMenuEntry(key: 'playPause', label: strings.trayPlayPause),
    TrayMenuEntry(key: 'previous', label: strings.trayPrevious),
    TrayMenuEntry(key: 'next', label: strings.trayNext),
    const TrayMenuEntry.separator(),
    TrayMenuEntry(key: 'show', label: strings.trayShowWindow),
    TrayMenuEntry(key: 'quit', label: strings.trayQuit),
  ];
}

/// The text the tray icon shows when the mouse rests on it.
String trayTooltipFor(PlaybackState state) {
  final song = state.currentSong;
  if (song == null) return 'Tune';
  if (song.artist.isEmpty) return song.title;
  return '${song.title} - ${song.artist}';
}

/// Carries out the action the user picked in the tray.
///
/// The tray is an outside caller, so every action goes through the playback
/// controller or through the window; the handler never touches the state
/// itself.
class TrayActionHandler {
  TrayActionHandler({
    required this.playback,
    required this.showWindow,
    required this.quit,
  });

  final PlaybackController playback;

  /// Brings the window of the player to the front.
  final Future<void> Function() showWindow;

  /// Ends the player.
  final Future<void> Function() quit;

  /// Carries out the action with the given key.
  Future<void> handle(String key) async {
    switch (key) {
      case 'playPause':
        await playback.togglePlayPause();
      case 'previous':
        await playback.previous();
      case 'next':
        await playback.next();
      case 'show':
        await showWindow();
      case 'quit':
        await quit();
    }
  }
}
