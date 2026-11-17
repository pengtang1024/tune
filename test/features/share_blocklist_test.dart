import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_blocklist.dart';
import 'package:tune/features/share/data/share_store.dart';

void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-share-blocked-');
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test('加进去的编号下次打开还在，重复加不重复记', () async {
    final db = File('${workspace.path}/library.db');
    final first = ShareStore.open(db);
    final blocklist = ShareBlocklist(first);
    expect(await blocklist.has('a' * 64), isFalse);
    expect(await blocklist.add('a' * 64), isTrue);
    expect(await blocklist.add('a' * 64), isFalse);
    await blocklist.add('b' * 64);
    first.dispose();

    final second = ShareBlocklist(ShareStore.open(db));
    expect(await second.has('a' * 64), isTrue);
    expect(await second.has('c' * 64), isFalse);
  });

  test('黑名单只挡它自己那一条', () async {
    final blocklist = ShareBlocklist(ShareStore.inMemory());
    await blocklist.add('a' * 64);

    expect(await blocklist.has('a' * 64), isTrue);
    expect(await blocklist.has('b' * 64), isFalse);
  });
}
