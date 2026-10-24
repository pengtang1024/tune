import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/data/services/tray/tray_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/desktop/application/desktop_integration_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

import '../services/fake_artwork_cache.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The window of the desktop is not there in a test; the integration asks
  // it to keep the window from closing on its own.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async => null,
      );

  late FakeAudioPlayerService audio;
  late PlaybackController playback;
  late _FakeMprisService mpris;
  late DesktopIntegrationController desktop;

  const song = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    album: 'Album A',
    duration: 180000,
    uri: '/music/a.mp3',
  );

  setUp(() async {
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    mpris = _FakeMprisService();

    final settings = SettingsController(FakePersistenceService());
    addTearDown(settings.dispose);

    desktop = DesktopIntegrationController(
      playback: playback,
      mpris: mpris,
      tray: _FakeTrayService(),
      instance: _FakeSingleInstanceService(),
      settings: settings,
      scanner: _FakeScanner(),
      addToLibrary: (songs) async {},
      artwork: FakeArtworkCache(),
    );
    addTearDown(desktop.dispose);
    addTearDown(playback.dispose);
    addTearDown(audio.dispose);
  });

  test('the clock alone does not publish to the media controls', () async {
    await desktop.start();
    await playback.playQueue([song]);
    // The player tells the controls about the state in a later turn of the
    // event loop, so the publications are counted after it had its say.
    await Future<void>.delayed(Duration.zero);

    final published = mpris.published.length;
    final positions = mpris.positions.length;

    // Ten ticks of the clock: the desktop asks the position for itself, so
    // the player keeps it fresh and publishes nothing.
    for (var i = 1; i <= 10; i++) {
      audio.emitPosition(Duration(seconds: i));
      await Future<void>.delayed(Duration.zero);
    }

    expect(mpris.published.length, published);
    expect(mpris.positions.length, greaterThan(positions));
    expect(mpris.positions.last, const Duration(seconds: 10));
  });

  test('a change the reader made is published', () async {
    await desktop.start();
    await playback.playQueue([song]);

    final published = mpris.published.length;

    await playback.setVolume(0.5);
    await Future<void>.delayed(Duration.zero);

    expect(mpris.published.length, greaterThan(published));
    expect(mpris.published.last.volume, 0.5);
  });
}

/// The media controls, counted instead of published.
class _FakeMprisService implements MprisService {
  /// The snapshots that were published.
  final List<MprisSnapshot> published = [];

  /// The positions that were handed over.
  final List<Duration> positions = [];

  @override
  Future<bool> start(MprisBackend backend) async => true;

  @override
  Future<void> update(MprisSnapshot snapshot) async {
    published.add(snapshot);
  }

  @override
  void setPosition(Duration position) {
    positions.add(position);
  }

  @override
  Future<void> dispose() async {}
}

/// A desktop without a tray.
class _FakeTrayService implements TrayService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> create({
    required String iconPath,
    required String tooltip,
    required List<TrayMenuEntry> menu,
    required void Function(String key) onMenuItemClick,
    required void Function() onClick,
  }) async => false;

  @override
  Future<void> setTooltip(String tooltip) async {}

  @override
  Future<void> setMenu(List<TrayMenuEntry> menu) async {}

  @override
  Future<void> destroy() async {}
}

/// A desktop that asks for nothing.
class _FakeSingleInstanceService implements SingleInstanceService {
  @override
  Future<bool> acquire() async => true;

  @override
  List<String> get startupFiles => const [];

  @override
  Stream<List<String>> get requestedFiles => const Stream.empty();

  @override
  Stream<void> get activationRequests => const Stream.empty();

  @override
  void requestFiles(List<String> paths) {}

  @override
  void requestActivation() {}

  @override
  Future<void> forwardFiles(List<String> paths) async {}

  @override
  Future<void> forwardActivation() async {}

  @override
  Future<void> dispose() async {}
}

/// A scanner that finds nothing.
class _FakeScanner implements CrossPlatformMusicScanner {
  @override
  Future<Song?> scanMusicFile(String filePath) async => null;

  @override
  Future<void> init() async {}

  @override
  Future<List<Song>> scanMusic() async => const [];

  @override
  Future<List<Song>> scanMusicInDirectory(String directoryPath) async =>
      const [];

  @override
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths) async =>
      const [];

  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async => const [];

  @override
  Future<List<Song>> getAllSongs() async => const [];

  @override
  Future<List<Song>> searchSongs(String query) async => const [];

  @override
  List<String> getDefaultMusicPaths() => const [];

  @override
  Future<List<Song>> scanCustomPaths(List<String> paths) async => const [];
}
