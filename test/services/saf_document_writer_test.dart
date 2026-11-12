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
}

Song _song(String uri) => Song(id: uri.hashCode, uri: uri);
