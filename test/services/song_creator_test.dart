import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/copy_marker.dart';
import 'package:tune/data/services/song_creator.dart';
import 'package:tune/domain/models/song.dart';

/// A file the app fetched is the copy of a track, not a track of its own.
void main() {
  late Directory library;

  const song = Song(
    id: 1,
    title: 'Two',
    artist: 'Artist',
    uri: 'tune://openverse/two',
    streamUrl: 'https://cdn.test/two.mp3',
  );

  setUp(() async {
    library = await Directory.systemTemp.createTemp('tune_scan');
  });

  tearDown(() async {
    if (await library.exists()) await library.delete(recursive: true);
  });

  test('a file without a marker is a track of its own', () async {
    final file = File(path.join(library.path, 'One.mp3'))
      ..writeAsStringSync('not really audio');

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned, isNotNull);
    expect(scanned!.uri, file.path);
    expect(scanned.localPath, isNull);
    expect(scanned.sourceId, isNull);
    expect(scanned.hasLocalFile, isTrue);
    expect(scanned.hasRemoteSource, isFalse);
  });

  test('a file with a marker is the copy of a track', () async {
    final file = File(path.join(library.path, 'Two.mp3'))
      ..writeAsStringSync('not really audio');
    await CopyMarker.write(file, song);

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned, isNotNull);
    expect(scanned!.uri, song.uri);
    expect(scanned.localPath, file.path);
    expect(scanned.sourceId, 'openverse');
    expect(scanned.externalId, 'two');
    expect(scanned.hasLocalFile, isTrue);
    expect(scanned.hasRemoteSource, isTrue);
  });
}
