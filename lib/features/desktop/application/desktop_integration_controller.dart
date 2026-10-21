import 'dart:async';

import 'package:tune/data/services/artwork/artwork_cache.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/desktop/application/desktop_window.dart';
import 'package:tune/features/desktop/application/mpris_state_mapper.dart';
import 'package:tune/features/desktop/application/opened_files_handler.dart';
import 'package:tune/features/desktop/application/playback_mpris_backend.dart';
import 'package:tune/features/desktop/application/playback_track_tracker.dart';
import 'package:tune/features/desktop/application/tray_integration.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/utils/logger.dart';

/// Connects the player with the desktop.
///
/// The controller owns the services that let the desktop talk to the player:
/// the media controls of the system, the icon in the panel and the place on
/// the bus that keeps a single player on the machine. It never owns the
/// playback state; it reads the playback controller and asks it to act.
class DesktopIntegrationController {
  DesktopIntegrationController({
    required this.playback,
    required this.mpris,
    required this.tray,
    required this.instance,
    required this.settings,
    required this.scanner,
    required this.addToLibrary,
    required this.artwork,
  });

  final PlaybackController playback;
  final MprisService mpris;
  final TrayService tray;
  final SingleInstanceService instance;
  final SettingsController settings;

  final CrossPlatformMusicScanner scanner;
  final Future<void> Function(List<Song> songs) addToLibrary;

  /// The covers that were fetched, so the media controls can show them.
  final ArtworkCache artwork;

  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<List<String>>? _filesSubscription;
  StreamSubscription<void>? _activationSubscription;

  bool _mediaControlsRunning = false;
  bool _trayRunning = false;

  final PlaybackTrackTracker _tracker = PlaybackTrackTracker();
  late final MprisStateMapper _mpris = MprisStateMapper(_tracker, artwork);
  late final DesktopWindow _window = DesktopWindow(
    closeToTray: () => settings.snapshot.closeToTray,
    hasTray: () => _trayRunning,
  );

  /// The handler of the files the desktop asked to open.
  late final OpenedFilesHandler _files = OpenedFilesHandler(
    scanner: scanner,
    playback: playback,
    addToLibrary: addToLibrary,
  );

  /// Starts the parts of the desktop the player talks to.
  Future<void> start() async {
    _playbackSubscription = playback.stream.listen(_handlePlaybackState);

    if (settings.snapshot.mediaControlsEnabled) {
      await _startMediaControls();
    }
    await _startTray();

    _filesSubscription = instance.requestedFiles.listen((paths) async {
      await _files.open(paths);
      await _window.show();
    });
    _activationSubscription = instance.activationRequests.listen((_) async {
      await _window.show();
    });

    await _window.takeOverClose();
    Log.info('桌面集成已启动');
  }

  /// Stops the parts of the desktop the player talks to.
  Future<void> dispose() async {
    _window.releaseClose();
    await _playbackSubscription?.cancel();
    await _filesSubscription?.cancel();
    await _activationSubscription?.cancel();
    await mpris.dispose();
    await tray.destroy();
  }

  /// Switches the media controls of the system on or off.
  Future<void> setMediaControlsEnabled(bool enabled) async {
    if (enabled == _mediaControlsRunning) return;
    if (enabled) {
      await _startMediaControls();
    } else {
      await mpris.dispose();
      _mediaControlsRunning = false;
    }
  }

  /// Rebuilds the texts of the tray, after the language changed.
  Future<void> refreshTrayTexts() async {
    if (!_trayRunning) return;
    await tray.setMenu(buildTrayMenu());
    await tray.setTooltip(trayTooltipFor(playback.snapshot));
  }

  // ---------------------------------------------------------------------------
  // The system media controls
  // ---------------------------------------------------------------------------

  Future<void> _startMediaControls() async {
    final backend = PlaybackMprisBackend(
      playback,
      onRaise: _window.show,
      onQuit: _window.quit,
    );
    _mediaControlsRunning = await mpris.start(backend);
    if (_mediaControlsRunning) {
      await mpris.update(_mpris.snapshotFor(playback.snapshot));
    }
  }

  /// Publishes the state of the player to the system.
  Future<void> _handlePlaybackState(PlaybackState state) async {
    final song = state.currentSong;
    final trackChanged = song != null && _tracker.remember(song);
    if (_mediaControlsRunning) {
      await mpris.update(_mpris.snapshotFor(state));
    }
    if (_trayRunning && trackChanged) {
      await tray.setTooltip(trayTooltipFor(state));
    }
  }

  // ---------------------------------------------------------------------------
  // The system tray
  // ---------------------------------------------------------------------------

  Future<void> _startTray() async {
    if (!tray.isSupported) return;

    final actions = TrayActionHandler(
      playback: playback,
      showWindow: _window.show,
      quit: _window.quit,
    );
    final created = await tray.create(
      iconPath: 'assets/icons/app_icon_tray.png',
      tooltip: trayTooltipFor(playback.snapshot),
      menu: buildTrayMenu(),
      onMenuItemClick: actions.handle,
      onClick: _window.toggle,
    );
    _trayRunning = created;
  }
}
