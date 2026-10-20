import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_persistence.dart';

/// The files of the app live in the music library, one folder per track.
void main() {
  late Directory root;
  late FileLibraryPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_library');
    final persistence = FakePersistenceService()
      ..values[LibraryPaths.rootKey] = root.path;
    paths = FileLibraryPaths(persistence);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('the folder of a track is named after artist, album and title', () async {
    const song = Song(
      id: 1,
      title: 'So What',
      artist: 'Miles Davis',
      album: 'Kind of Blue',
      uri: 'https://source.test/so-what',
    );

    final folder = await paths.folderFor(song);

    expect(
      folder.path,
      path.join(root.path, 'Miles Davis', 'Kind of Blue', 'So What'),
    );
  });

  test('a track without an album keeps the folder short', () async {
    const song = Song(
      id: 1,
      title: 'So What',
      artist: 'Miles Davis',
      uri: 'https://source.test/so-what',
    );

    final folder = await paths.folderFor(song);

    expect(folder.path, path.join(root.path, 'Miles Davis', 'So What'));
  });

  test('a track that is on the disk keeps the folder it is in', () async {
    final file = File(path.join(root.path, 'Album', 'Track.mp3'))
      ..createSync(recursive: true);
    final song = Song(id: 1, title: 'Track', uri: file.path);

    final folder = await paths.folderFor(song);

    expect(folder.path, path.join(root.path, 'Album'));
    expect(paths.nameFor(song), 'Track');
  });

  test('the files of a track sit next to each other', () async {
    const song = Song(
      id: 1,
      title: 'So What',
      artist: 'Miles Davis',
      uri: 'https://source.test/so-what',
    );

    final cover = await paths.coverFileFor(song, 'jpg');
    final lyrics = await paths.lyricsFileFor(song);

    expect(cover.path, endsWith('So What.jpg'));
    expect(lyrics.path, endsWith('So What.lrc'));
    expect(cover.parent.path, lyrics.parent.path);
  });

  test('the covers of the tracks that were not fetched go into one place', () async {
    final folder = await paths.coverCacheFolder();

    expect(folder.path, path.join(root.path, '.tune', 'artwork'));
  });

  test('a title cannot write outside the folder it belongs to', () async {
    const song = Song(
      id: 1,
      title: '../../escape',
      artist: 'Artist',
      uri: 'https://source.test/escape',
    );

    final folder = await paths.folderFor(song);

    expect(folder.path.startsWith(root.path), isTrue);
    expect(path.split(folder.path).contains('..'), isFalse);
  });

  test('the lyrics are written next to the track and read back', () async {
    const song = Song(
      id: 1,
      title: 'So What',
      artist: 'Miles Davis',
      uri: 'https://source.test/so-what',
    );

    expect(await paths.readLyrics(song), isNull);

    await paths.saveLyrics(song, '[00:00] line');

    expect(await paths.readLyrics(song), '[00:00] line');
    final file = await paths.lyricsFileFor(song);
    expect(await file.exists(), isTrue);
  });
}
