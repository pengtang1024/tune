import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/desktop/application/opened_files_handler.dart';
import 'package:tune/features/player/application/playback_controller.dart';

import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  late FakeAudioPlayerService audio;
  late PlaybackController playback;
  late _FakeScanner scanner;
  late List<Song> added;
  late OpenedFilesHandler handler;

  const songA = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    album: 'Album A',
    duration: 180000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    album: 'Album B',
    duration: 120000,
    uri: '/music/b.mp3',
  );

  setUp(() {
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    scanner = _FakeScanner({'/music/a.mp3': songA, '/music/b.mp3': songB});
    added = [];
    handler = OpenedFilesHandler(
      scanner: scanner,
      playback: playback,
      addToLibrary: (songs) async => added.addAll(songs),
    );
  });

  tearDown(() {
    playback.dispose();
    audio.dispose();
  });

  test('the files the desktop names are put in the library and played', () async {
    await handler.open(['/music/a.mp3', '/music/b.mp3']);

    expect(added, [songA, songB]);
    expect(playback.state.queue, [songA, songB]);
  });

  test('a file that cannot be read does not stop the others', () async {
    await handler.open(['/music/broken.mp3', '/music/a.mp3']);

    expect(added, [songA]);
    expect(playback.state.queue, [songA]);
  });

  test('nothing happens without a file', () async {
    await handler.open([]);

    expect(added, isEmpty);
    expect(playback.state.queue, isEmpty);
  });
}

/// A scanner that knows two files by heart.
class _FakeScanner implements CrossPlatformMusicScanner {
  _FakeScanner(this.songs);

  final Map<String, Song> songs;

  @override
  Future<Song?> scanMusicFile(String filePath) async {
    final song = songs[filePath];
    if (song == null) throw StateError('cannot read $filePath');
    return song;
  }

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
