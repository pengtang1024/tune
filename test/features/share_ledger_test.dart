import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_ledger.dart';
import 'package:tune/features/share/data/share_store.dart';

void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-share-ledger-');
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test('记下的条目在下次打开时还在，重复记不算新增', () async {
    final db = File('${workspace.path}/library.db');
    final first = ShareStore.open(db);
    final ledger = ShareLedger(first);
    expect(await ledger.has('a' * 64), isFalse);
    expect(await ledger.add('a' * 64), isTrue);
    expect(await ledger.add('b' * 64), isTrue);
    expect(await ledger.add('a' * 64), isFalse);
    first.dispose();

    final second = ShareLedger(ShareStore.open(db));
    expect(await second.has('a' * 64), isTrue);
    expect(await second.has('c' * 64), isFalse);
  });

  test('台账认的是「生成过」这条事件，跟这条内容后来自不分享无关', () async {
    final store = ShareStore.inMemory();
    final ledger = ShareLedger(store);

    await ledger.add('a' * 64);
    store.logEvent('shared', contentId: 'a' * 64);

    expect(await ledger.has('a' * 64), isTrue);
  });
}
