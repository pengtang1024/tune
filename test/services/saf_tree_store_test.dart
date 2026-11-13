import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';

import 'fake_persistence.dart';

void main() {
  test('a tree is kept, a desktop path is not', () async {
    final persistence = FakePersistenceService();
    final store = SafTreeStore(persistence);
    expect(store.treeUri, isNull);

    await persistence.setString(LibraryPaths.rootKey, '/home/me/Music');
    expect(store.treeUri, isNull);

    const tree =
        'content://com.android.externalstorage.documents/tree/primary%3AMusic';
    await persistence.setString(LibraryPaths.rootKey, tree);
    expect(store.treeUri, tree);
  });

  test('isTreeUri tells the two kinds of folder apart', () {
    expect(SafTreeStore.isTreeUri('content://x/tree/y'), isTrue);
    expect(SafTreeStore.isTreeUri('/home/me/Music'), isFalse);
    expect(SafTreeStore.isTreeUri(null), isFalse);
  });
}
