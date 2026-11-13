import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/saf_music_scanner.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';

import 'fake_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const saf = MethodChannel('cn.iouf.tune/saf');
  const mediaStore = MethodChannel('cn.iouf.tune/media_store');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const tree =
      'content://com.android.externalstorage.documents/tree/primary%3AMusic';

  tearDown(() {
    messenger.setMockMethodCallHandler(saf, null);
    messenger.setMockMethodCallHandler(mediaStore, null);
  });

  test('pages through the tree and stops on a short page', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);

    final offsets = <int>[];
    messenger.setMockMethodCallHandler(saf, (call) async {
      expect(call.method, 'listTree');
      final args = call.arguments as Map<Object?, Object?>;
      final offset = args['offset'] as int;
      final limit = args['limit'] as int;
      offsets.add(offset);
      if (offset == 0) {
        return List.generate(limit, (index) => _row('a$index'));
      }
      return [_row('last')];
    });

    final scanner = SafMusicScanner(tree: SafTreeStore(persistence));
    final songs = await scanner.scanMusic();

    expect(offsets, [0, 500]);
    expect(songs, hasLength(501));
    expect(songs.first.uri, contains('/document/'));
    expect(scanner.addressesSystemLibrary, isTrue);
  });

  test('a tree whose permission was taken back fails the scan', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);

    messenger.setMockMethodCallHandler(saf, (call) async {
      throw PlatformException(code: 'permission_lost', message: 'gone');
    });

    final scanner = SafMusicScanner(tree: SafTreeStore(persistence));
    await expectLater(
      scanner.scanMusic(),
      throwsA(isA<SafTreePermissionException>()),
    );
  });

  test('without a tree the system library is read', () async {
    final persistence = FakePersistenceService();
    var safCalls = 0;
    messenger.setMockMethodCallHandler(saf, (call) async {
      safCalls++;
      return null;
    });
    messenger.setMockMethodCallHandler(mediaStore, (call) async {
      expect(call.method, 'listAudio');
      return [
        _row('media/a', uri: 'content://media/external/audio/media/a'),
        _row('media/b', uri: 'content://media/external/audio/media/b'),
      ];
    });

    final scanner = SafMusicScanner(tree: SafTreeStore(persistence));
    final songs = await scanner.scanMusic();

    expect(safCalls, 0);
    expect(songs, hasLength(2));
  });
}

Map<String, Object> _row(String id, {String? uri}) => {
  'uri': uri ?? 'content://provider/tree/primary%3AMusic/document/$id',
  'mediaId': id,
  'title': 'Title $id',
  'artist': 'Artist',
  'album': 'Album',
  'durationMs': 1000,
  'dateAddedSeconds': 0,
  'size': 1024,
  'mimeType': 'audio/wav',
};
