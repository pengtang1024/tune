import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_inbox.dart';
import 'package:tune/features/share/data/share_migration.dart';
import 'package:tune/features/share/data/share_store.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

ShareItem _item(String contentId, {String name = 'a.flac'}) => ShareItem(
  contentId: contentId,
  name: name,
  sizeBytes: 1024,
  provenance: ShareProvenance.ownRecording,
  createdAt: DateTime.utc(2026, 11, 16),
);

void main() {
  test('收件箱读的是没被软删的行，撤掉一条不影到别的', () async {
    final store = ShareStore.inMemory();
    final dir = Directory.systemTemp.createTempSync('tune-share-inbox-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final inbox = ShareInbox(store, dir);

    store.rememberReceived(
      _item('a' * 64),
      path: '${dir.path}/a.flac',
      fromPeerId: 'peer-a',
      fromName: '甲',
    );
    store.rememberReceived(
      _item('b' * 64),
      path: '${dir.path}/b.flac',
      fromPeerId: 'peer-b',
      fromName: '乙',
    );

    expect((await inbox.load()).map((e) => e.item.contentId), ['b' * 64, 'a' * 64]);
    expect((await inbox.load()).first.fromName, '乙');

    await inbox.forget((await inbox.load()).first);
    expect((await inbox.load()).map((e) => e.item.contentId), ['a' * 64]);
  });

  test('M0 的四份 JSON 快照能搬进表里，搬完全改名', () async {
    final dir = Directory.systemTemp.createTempSync('tune-share-migrate-');
    addTearDown(() => dir.deleteSync(recursive: true));
    await Directory('${dir.path}/inbox').create(recursive: true);

    const cid = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    await File('${dir.path}/ledger.json').writeAsString(
      jsonEncode({'v': 1, 'contentIds': [cid]}),
    );
    await File('${dir.path}/blocked.json').writeAsString(
      jsonEncode({'v': 1, 'contentIds': [cid]}),
    );
    await File('${dir.path}/reports.json').writeAsString(
      jsonEncode({
        'v': 1,
        'reports': [
          {
            'contentId': cid,
            'name': 'a.flac',
            'reason': 'unknown',
            'createdAt': '2026-11-16T00:00:00.000Z',
            'fromPeerId': 'peer-a',
          },
        ],
      }),
    );
    await File('${dir.path}/inbox/index.json').writeAsString(
      jsonEncode([
        {
          'item': _item(cid).toJson(),
          'path': '${dir.path}/inbox/$cid.flac',
          'fromPeerId': 'peer-a',
          'fromName': '甲',
          'receivedAt': '2026-11-16T00:00:00.000Z',
        },
      ]),
    );

    final store = ShareStore.inMemory();
    await importLegacyShareJson(store, dir);

    expect(store.hasGenerated(cid), isTrue);
    expect(store.isBlocked(cid), isTrue);
    expect(store.reports(), hasLength(1));
    expect(store.receivedEntries().single.item.contentId, cid);

    // 再搬一次不会重复记。
    await importLegacyShareJson(store, dir);
    expect(store.reports(), hasLength(1));

    expect(await File('${dir.path}/ledger.json').exists(), isFalse);
    expect(await File('${dir.path}/ledger.json.migrated').exists(), isTrue);
  });
}
