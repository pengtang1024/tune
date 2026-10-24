import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  const first = Song(
    id: 1,
    title: 'So What',
    artist: 'Miles Davis',
    uri: '/music/so-what.mp3',
  );
  const second = Song(
    id: 2,
    title: 'Night Drive',
    artist: 'Nova',
    uri: '/music/night-drive.mp3',
  );

  test('the lyrics of the track that plays are shown', () async {
    final database = _FakeDatabase()..answers[1] = '[00:12.00]First line';
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );

    final state = await _settled(container);

    expect(state.hasLyrics, isTrue);
    expect(state.document!.lines.first.text, 'First line');
    expect(state.songId, 1);
  });

  test('a track without lyrics says so', () async {
    final database = _FakeDatabase();
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );

    final state = await _settled(container);

    expect(state.hasLyrics, isFalse);
    expect(state.document, isNull);
  });

  test('a request that fails says so', () async {
    final database = _FakeDatabase()..fails = true;
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );

    await _settled(container);

    final value = container.read(lyricsControllerProvider);
    expect(value.hasError, isTrue);
  });

  test('a track is asked about once', () async {
    final database = _FakeDatabase()..answers[1] = '[00:12.00]First line';
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );

    await _settled(container);
    // The panel was closed and opened again: the answer is still known.
    container.invalidate(lyricsControllerProvider);
    await _settled(container);

    expect(database.asked, hasLength(1));
  });

  test('a track without lyrics is not asked about again', () async {
    final database = _FakeDatabase();
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );

    await _settled(container);
    container.invalidate(lyricsControllerProvider);
    await _settled(container);

    expect(database.asked, hasLength(1));
  });

  test('the track that plays decides the lyrics', () async {
    final database = _FakeDatabase()
      ..answers[1] = '[00:12.00]First line'
      ..answers[2] = '[00:20.00]Second line';
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );
    await _settled(container);

    await container.read(playbackControllerProvider.notifier).playQueue([second]);
    final state = await _settled(container);

    expect(state.songId, 2);
    expect(state.document!.lines.first.text, 'Second line');
  });

  test('a reload asks again', () async {
    final database = _FakeDatabase();
    final container = await _container(
      paths: _FakeLibraryPaths(),
      database: database,
      song: first,
    );
    await _settled(container);

    await container.read(lyricsControllerProvider.notifier).reload(first);
    await _settled(container);

    expect(database.asked, hasLength(2));
  });

  test('the file next to the track is read without asking the database', () async {
    final paths = _FakeLibraryPaths()..stored[1] = '[00:00] line';
    final database = _FakeDatabase();
    final container = await _container(
      paths: paths,
      database: database,
      song: first,
    );

    final state = await _settled(container);

    expect(state.document!.lines.first.text, 'line');
    expect(database.asked, isEmpty);
  });

  test('the lyrics the reader brought are written down and shown', () async {
    final paths = _FakeLibraryPaths();
    final database = _FakeDatabase();
    final container = await _container(
      paths: paths,
      database: database,
      song: first,
    );

    await container.read(lyricsControllerProvider.notifier).attach(
      first,
      '[00:12.00]Chosen line'.codeUnits,
    );

    final state = container.read(lyricsControllerProvider).valueOrNull!;
    expect(state.hasLyrics, isTrue);
    expect(state.document!.lines.first.text, 'Chosen line');
    expect(paths.stored[1], '[00:12.00]Chosen line');
  });

  test('a file that holds no lyrics is refused', () async {
    final paths = _FakeLibraryPaths();
    final database = _FakeDatabase();
    final container = await _container(
      paths: paths,
      database: database,
      song: first,
    );

    await container.read(lyricsControllerProvider.notifier).attach(first, []);

    final state = container.read(lyricsControllerProvider).valueOrNull!;
    expect(state.invalid, isTrue);
    expect(state.hasLyrics, isFalse);
    expect(paths.stored.containsKey(1), isFalse);
  });

  test('the lyrics stay on screen when the file cannot be written', () async {
    final paths = _FakeLibraryPaths()..unwritable.add(1);
    final database = _FakeDatabase();
    final container = await _container(
      paths: paths,
      database: database,
      song: first,
    );

    await container.read(lyricsControllerProvider.notifier).attach(
      first,
      '[00:12.00]Chosen line'.codeUnits,
    );

    final state = container.read(lyricsControllerProvider).valueOrNull!;
    expect(state.hasLyrics, isTrue);
    expect(state.document!.lines.first.text, 'Chosen line');
  });
}

/// The controller under test, with the files and the database in reach.
Future<ProviderContainer> _container({
  required _FakeLibraryPaths paths,
  required LyricsProvider database,
  Song? song,
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.dispose);
  final playback = PlaybackController(
    audio,
    FakeSongDownloadService(),
    FakeStreamUrlResolver(),
  );
  if (song != null) await playback.playQueue([song]);

  final container = ProviderContainer(
    overrides: [
      libraryPathsProvider.overrideWithValue(paths),
      musicSourceServiceProvider.overrideWithValue(
        MusicSourceService(
          scanner: CrossPlatformMusicScannerImpl(),
          store: MusicSourceStore(FakePersistenceService()),
          lyricsProvider: database,
        ),
      ),
      playbackControllerProvider.overrideWith((ref) => playback),
      audioPlayerServiceProvider.overrideWithValue(audio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Waits until the lyrics of the track that plays are known.
Future<LyricsState> _settled(ProviderContainer container) async {
  try {
    await container.read(lyricsControllerProvider.future);
  } catch (_) {
    // The request failed: the state carries the failure.
  }
  return container.read(lyricsControllerProvider).valueOrNull ??
      const LyricsState();
}

/// The files of the app, kept in memory.
class _FakeLibraryPaths implements LibraryPaths {
  /// The lyrics that are written down for a track.
  final Map<int, String> stored = {};

  /// The tracks whose file cannot be written.
  final Set<int> unwritable = {};

  @override
  Future<String?> readLyrics(Song song) async => stored[song.id];

  @override
  Future<void> saveLyrics(Song song, String lyrics) async {
    if (unwritable.contains(song.id)) {
      throw StateError('the folder is not writable');
    }
    stored[song.id] = lyrics;
  }

  @override
  Future<void> saveChosenLyrics(Song song, String lyrics) async {
    if (unwritable.contains(song.id)) {
      throw StateError('the folder is not writable');
    }
    stored[song.id] = lyrics;
  }

  @override
  Future<Directory> folderFor(Song song) async =>
      throw UnsupportedError('the test has no file system');

  @override
  String nameFor(Song song) => song.title;

  @override
  Future<File> coverFileFor(Song song, String extension) async =>
      throw UnsupportedError('the test has no file system');

  @override
  Future<File> lyricsFileFor(Song song) async =>
      throw UnsupportedError('the test has no file system');

  /// The rest of the library is of no use to the lyrics.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('the test has no file system');
}

/// A lyrics database that answers from a table.
class _FakeDatabase implements LyricsProvider {
  final Map<int, String?> answers = {};
  final List<Song> asked = [];
  bool fails = false;

  @override
  Future<String?> lookup(Song song) async {
    asked.add(song);
    if (fails) throw StateError('the database is not reachable');
    return answers[song.id];
  }
}
