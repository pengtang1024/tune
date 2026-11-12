import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/saf_document_writer.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const saf = MethodChannel('cn.iouf.tune/saf');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const tree =
      'content://com.android.externalstorage.documents/tree/primary%3AMusic';

  tearDown(() => messenger.setMockMethodCallHandler(saf, null));

  test('without a tree no sheet can be written', () async {
    final writer = SafDocumentWriter(
      tree: SafTreeStore(FakePersistenceService()),
    );
    expect(writer.owns(_song('$tree/document/a')), isFalse);
    expect(await writer.canWrite(_song('$tree/document/a')), isFalse);
  });

  test('a track of MediaStore is not inside the tree', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);
    var asked = false;
    messenger.setMockMethodCallHandler(saf, (call) async {
      asked = true;
      return true;
    });

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));
    const media = Song(id: 1, uri: 'content://media/external/audio/media/1');

    expect(writer.owns(media), isFalse);
    expect(await writer.canWrite(media), isFalse);
    expect(asked, isFalse);
  });

  test(
    'a document of the tree is writable while the permission holds',
    () async {
      final persistence = FakePersistenceService();
      await persistence.setString(LibraryPaths.rootKey, tree);

      String? askedUri;
      messenger.setMockMethodCallHandler(saf, (call) async {
        expect(call.method, 'canWrite');
        askedUri = (call.arguments as Map<Object?, Object?>)['uri'] as String?;
        return true;
      });

      final writer = SafDocumentWriter(tree: SafTreeStore(persistence));
      final song = _song('$tree/document/a');

      expect(writer.owns(song), isTrue);
      expect(await writer.canWrite(song), isTrue);
      expect(askedUri, tree);
    },
  );

  test(
    'a tree whose write permission was taken back is not writable',
    () async {
      final persistence = FakePersistenceService();
      await persistence.setString(LibraryPaths.rootKey, tree);
      messenger.setMockMethodCallHandler(saf, (call) async => false);

      final writer = SafDocumentWriter(tree: SafTreeStore(persistence));
      expect(await writer.canWrite(_song('$tree/document/a')), isFalse);
    },
  );

  test('the machine sheet lands in the folder of the track', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);
    final song = Song(
      id: 1,
      title: 'Saf One',
      uri: '$tree/document/audio%3A7',
    );
    Map<Object?, Object?>? written;
    messenger.setMockMethodCallHandler(saf, (call) async {
      if (call.method == 'canWrite') return true;
      expect(call.method, 'writeSheet');
      written = call.arguments as Map<Object?, Object?>;
      return {'uri': '$tree/document/sheet', 'replaced': false};
    });

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));
    await writer.writeSmartLyrics(song, '[00:01.00] 一句');

    expect(written?['treeUri'], tree);
    expect(written?['songUri'], song.uri);
    expect(written?['name'], 'Saf One.smart.lrc');
    expect(written?['content'], '[00:01.00] 一句');
  });

  test('a taken-back permission is reported and nothing is written', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);
    var wrote = false;
    messenger.setMockMethodCallHandler(saf, (call) async {
      if (call.method == 'canWrite') return false;
      wrote = true;
      return null;
    });

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));

    await expectLater(
      writer.writeSmartLyrics(_song('$tree/document/a'), 'words'),
      throwsA(
        isA<SheetWriteException>().having(
          (error) => error.permissionLost,
          'permissionLost',
          isTrue,
        ),
      ),
    );
    expect(wrote, isFalse);
  });

  test('a native permission loss comes back as the same report', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);
    messenger.setMockMethodCallHandler(saf, (call) async {
      if (call.method == 'canWrite') return true;
      throw PlatformException(code: 'permission_lost');
    });

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));

    await expectLater(
      writer.writeSmartLyrics(_song('$tree/document/a'), 'words'),
      throwsA(
        isA<SheetWriteException>().having(
          (error) => error.permissionLost,
          'permissionLost',
          isTrue,
        ),
      ),
    );
  });

  test('a track outside the tree has no sheet in it', () async {
    final persistence = FakePersistenceService();
    await persistence.setString(LibraryPaths.rootKey, tree);
    var asked = false;
    messenger.setMockMethodCallHandler(saf, (call) async {
      asked = true;
      return true;
    });

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));

    await expectLater(
      writer.writeSmartLyrics(
        const Song(id: 1, title: 'Media', uri: 'content://media/external/audio/media/1'),
        'words',
      ),
      throwsA(isA<SheetWriteException>()),
    );
    expect(asked, isFalse);
  });
}

Song _song(String uri) => Song(id: uri.hashCode, uri: uri);
