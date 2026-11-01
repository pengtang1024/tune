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

  test('a lyrics file next to the audio counts as lyrics', () async {
    final file = File(path.join(library.path, 'WithLrc.mp3'))
      ..writeAsStringSync('not really audio');
    File(path.join(library.path, 'WithLrc.lrc')).writeAsStringSync(
      '[00:01.00]一句词',
    );

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned!.hasLyrics, isTrue);
  });

  test('a manual lyrics file next to the audio counts as lyrics', () async {
    final file = File(path.join(library.path, 'Chosen.mp3'))
      ..writeAsStringSync('not really audio');
    File(path.join(library.path, 'Chosen.manual.lrc')).writeAsStringSync(
      '[00:01.00]一句词',
    );

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned!.hasLyrics, isTrue);
  });

  test('a smart sheet next to the audio counts as lyrics', () async {
    final file = File(path.join(library.path, 'Generated.mp3'))
      ..writeAsStringSync('not really audio');
    File(path.join(library.path, 'Generated.smart.lrc')).writeAsStringSync(
      '[tune:smart]\n[00:01.00]一句词',
    );

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned!.hasLyrics, isTrue,
        reason: 'the pipeline filled the gap; a rescan must see it');
  });

  test('a file without a lyrics sheet carries none', () async {
    final file = File(path.join(library.path, 'Bare.mp3'))
      ..writeAsStringSync('not really audio');

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned!.hasLyrics, isFalse);
  });

  test('a corrupt tag declaring a gigabyte frame stays bounded', () async {
    // A real-world mp3 (2014-02-12 Bigwords.mp3) carried a corrupt ID3v2
    // frame header that declared ~1.2 GB of payload on a 4 MB file. The
    // tag reader used to allocate the declared size, so scanning that one
    // file raised the resident memory by 1.2 GB. This replica keeps the
    // shape: a valid tag, one small frame, then a frame header whose size
    // runs past the end of the file.
    final bytes = <int>[
      // ID3v2.3 header: "ID3", version 2.3, no flags, tag size 118.
      0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x76,
      // COMM frame, 98 bytes of payload.
      0x43, 0x4F, 0x4D, 0x4D, 0x00, 0x00, 0x00, 0x62,
      ...List.filled(98, 0),
      // The corrupt frame: id "\x00COM" declaring 1,291,845,632 bytes.
      0x00, 0x43, 0x4F, 0x4D, 0x4D, 0x00, 0x00, 0x00,
    ];
    final file = File(path.join(library.path, 'Corrupt.mp3'))
      ..writeAsBytesSync(bytes);

    int rss() => ProcessInfo.currentRss;
    final before = rss();

    final scanned = await SongCreator.createFromFile(file);

    expect(scanned, isNotNull);
    expect(scanned!.uri, file.path);
    // The declared 1.2 GB must never become a resident allocation. The
    // parse itself costs a few MB; two orders of magnitude is slack.
    expect(rss() - before, lessThan(100 * 1024 * 1024));
  });
}
