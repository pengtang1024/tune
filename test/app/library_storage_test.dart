import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/data/impl/library_storage_io.dart';
import 'package:tune/features/library/data/library_document.dart';

/// The library of an older version wrote the words of that version when a
/// file carried no name. The interface writes a missing name in the language
/// of the app now, so the old words are dropped when the library is read.
void main() {
  late Directory support;
  late Directory documents;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('tune_support');
    documents = await Directory.systemTemp.createTemp('tune_documents');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  FileLibraryStorage storage() => FileLibraryStorage(
    supportDirectory: () async => support,
    documentsDirectory: () async => documents,
  );

  File libraryFile() =>
      File(path.join(support.path, 'library', 'scanned_songs.json'));

  test('a saved library is read back', () async {
    final service = storage();
    await service.save([
      const Song(
        id: 1,
        title: 'Night Flight',
        artist: 'Forest Radio',
        uri: '/music/a.mp3',
      ),
    ]);

    final songs = await service.load();

    expect(songs, hasLength(1));
    expect(songs.single.title, 'Night Flight');
    expect(songs.single.artist, 'Forest Radio');
  });

  test('the library is kept in the folder of the app', () async {
    await storage().save([const Song(id: 1, uri: '/music/a.mp3')]);

    expect(await libraryFile().exists(), isTrue);
  });

  test('the library of an older version moves into the folder of the app', () async {
    final older = File(path.join(documents.path, 'scanned_songs.json'));
    await older.writeAsString(
      jsonEncode([
        {'id': 7, 'title': 'Old Track', 'uri': '/music/old.mp3'},
      ]),
    );

    final songs = await storage().load();

    expect(songs, hasLength(1));
    expect(songs.single.title, 'Old Track');
    expect(await libraryFile().exists(), isTrue);
    expect(await older.exists(), isFalse, reason: '旧文件搬走了就不该留下');
  });

  test('the words of an older version are dropped', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Night Flight',
      'artist': 'Unknown Artist',
      'album': 'Unknown Album',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['artist'], '');
    expect(cleaned['album'], '');
  });

  test('a name that is really there is kept', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Night Flight',
      'artist': 'Forest Radio',
      'album': 'City Echoes',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['artist'], 'Forest Radio');
    expect(cleaned['album'], 'City Echoes');
  });

  test('the words of an older version that stand for a title are kept', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Unknown Artist',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['title'], 'Unknown Artist');
  });
}
