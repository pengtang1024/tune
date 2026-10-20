import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/library/copy_marker.dart';
import 'package:tune/domain/models/song.dart';

/// The marker says which track a file in the library is a copy of.
void main() {
  late Directory folder;

  const song = Song(
    id: 1,
    title: 'Two',
    artist: 'Artist',
    uri: 'tune://openverse/two',
    streamUrl: 'https://cdn.test/two.mp3',
  );

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('tune_marker');
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  test('the marker sits next to the audio file', () async {
    final audio = File(path.join(folder.path, 'Two.mp3'))
      ..createSync(recursive: true);

    await CopyMarker.write(audio, song);

    final marker = CopyMarker.fileFor(audio);
    expect(marker.path, path.join(folder.path, 'Two.tune'));
    expect(await marker.exists(), isTrue);
  });

  test('the marker names the track the copy belongs to', () async {
    final audio = File(path.join(folder.path, 'Two.mp3'))
      ..createSync(recursive: true);

    await CopyMarker.write(audio, song);

    expect(await CopyMarker.readUri(audio), song.uri);
  });

  test('a file without a marker is a track of its own', () async {
    final audio = File(path.join(folder.path, 'One.mp3'))
      ..createSync(recursive: true);

    expect(await CopyMarker.readUri(audio), isNull);
  });

  test('an empty marker names nothing', () async {
    final audio = File(path.join(folder.path, 'One.mp3'))
      ..createSync(recursive: true);
    await CopyMarker.fileFor(audio).writeAsString('   ');

    expect(await CopyMarker.readUri(audio), isNull);
  });
}
