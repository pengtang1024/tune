import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_identity.dart';
import 'package:tune/data/services/mesh/room_invite.dart';
import 'package:tune/features/share/application/share_session.dart';
import 'package:tune/features/share/data/share_inbox.dart';
import 'package:tune/features/share/data/share_store.dart';
import 'package:tune/features/share/data/share_blocklist.dart';
import 'package:tune/features/share/data/share_ledger.dart';
import 'package:tune/features/share/data/share_reports.dart';
import 'package:tune/features/share/domain/share_declaration.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';
import 'package:tune/features/share/domain/share_session_state.dart';

Future<ShareSessionState> _waitFor(
  ShareSession session,
  bool Function(ShareSessionState state) predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  if (predicate(session.state)) {
    return session.state;
  }
  return session.states
      .firstWhere(predicate)
      .timeout(timeout);
}

void main() {
  late Directory workspace;
  late MeshIdentity hostIdentity;
  late MeshIdentity guestIdentity;
  late ShareSession host;
  late ShareSession guest;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-share-session-');
    hostIdentity = await MeshIdentity.generate();
    guestIdentity = await MeshIdentity.generate();
  });

  tearDown(() async {
    await guest.close();
    await host.close();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  /// 走真实路径拼条目：声明带证据哈希，闸门才认。
  ShareItem itemFor(Uint8List bytes, {String name = '夜航.flac'}) {
    return ShareDeclaration(
      provenance: ShareProvenance.generated,
      declaredAt: DateTime.utc(2026, 11, 16, 12),
    ).toItem(
      contentId: MeshCrypto.contentIdOf(bytes),
      name: name,
      sizeBytes: bytes.length,
      artist: '本机',
    );
  }

  late ShareStore store;
  late ShareLedger ledger;

  Future<void> startPair({ShareRecordingLookup? hostLookup}) async {
    store = ShareStore.inMemory();
    ledger = ShareLedger(store);
    host = await ShareSession.host(
      identity: hostIdentity,
      displayName: '房主',
      inbox: ShareInbox(store, Directory('${workspace.path}/host-inbox')),
      ledger: ledger,
      recordingLookup: hostLookup,
      address: InternetAddress.loopbackIPv4,
    );
    guest = await ShareSession.join(
      invite: RoomInvite(
        roomKey: host.invite.roomKey,
        seeds: <String>['127.0.0.1:${host.port}'],
      ),
      identity: guestIdentity,
      displayName: '访客',
      inbox: ShareInbox(store, Directory('${workspace.path}/guest-inbox')),
      ledger: ledger,
    );
  }

  test('访客连上就能看见房主的清单，收下来能验过内容编号', () async {
    await startPair();
    final bytes = Uint8List.fromList(
      List<int>.generate(300 * 1024, (index) => index & 0xff),
    );
    final file = File('${workspace.path}/夜航.flac');
    await file.writeAsBytes(bytes);
    final item = itemFor(bytes);
    await ledger.add(item.contentId);

    expect(await host.addLocalItem(item, file), isTrue);
    expect(host.state.localItems.single.contentId, item.contentId);

    final seen = await _waitFor(guest, (state) => state.remoteItems.isNotEmpty);
    expect(seen.remoteItems.single.item.contentId, item.contentId);
    expect(seen.remoteItems.single.manifestVerified, isTrue);
    expect(seen.peers.single.displayName, '房主');

    await guest.request(item);
    final received = await _waitFor(guest, (state) => state.inbox.isNotEmpty);
    final entry = received.inbox.single;
    expect(entry.item.contentId, item.contentId);
    expect(await File(entry.path).length(), bytes.length);
    expect(
      MeshCrypto.contentIdOf(await File(entry.path).readAsBytes()),
      item.contentId,
    );
    expect(entry.fromName, '房主');
  });

  test('不满足分享条件的条目发不出去', () async {
    await startPair();
    final bytes = Uint8List.fromList([1, 2, 3]);
    final file = File('${workspace.path}/no-evidence.flac');
    await file.writeAsBytes(bytes);
    final item = ShareItem(
      contentId: MeshCrypto.contentIdOf(bytes),
      name: 'no-evidence.flac',
      sizeBytes: bytes.length,
      provenance: ShareProvenance.ownRecording,
      createdAt: DateTime.utc(2026, 11, 16),
    );
    expect(await host.addLocalItem(item, file), isFalse);
    expect(host.state.lastError, isNotNull);
    expect(host.state.localItems, isEmpty);
  });

  test('作者撤销后，对方清单里没有了，已收的那份也被删掉', () async {
    await startPair();
    final bytes = Uint8List.fromList(
      List<int>.generate(20 * 1024, (index) => index & 0xff),
    );
    final file = File('${workspace.path}/撤销.flac');
    await file.writeAsBytes(bytes);
    final item = itemFor(bytes);
    await ledger.add(item.contentId);
    expect(await host.addLocalItem(item, file), isTrue);

    final seen = await _waitFor(guest, (state) => state.remoteItems.isNotEmpty);
    expect(seen.remoteItems.single.item.contentId, item.contentId);

    // 先收下来，再让作者撤销：本地那份必须跟着消失。
    await guest.request(item);
    final received = await _waitFor(guest, (state) => state.inbox.isNotEmpty);
    final path = received.inbox.single.path;
    expect(await File(path).exists(), isTrue);

    host.revoke(item.contentId);

    final after = await _waitFor(guest, (state) => state.remoteItems.isEmpty);
    expect(after.remoteItems, isEmpty);
    final emptied = await _waitFor(guest, (state) => state.inbox.isEmpty);
    expect(emptied.inbox, isEmpty);
    expect(await File(path).exists(), isFalse);
    expect(host.state.localItems, isEmpty);
    // 原始文件是用户自己的，撤销分享不动它。
    expect(await file.exists(), isTrue);
  });

  test('举报会记一条留痕并把本地那份删掉', () async {
    await startPair();
    final reports = ShareReports(store);
    final blocklist = ShareBlocklist(store);
    await guest.close();
    guest = await ShareSession.join(
      invite: RoomInvite(
        roomKey: host.invite.roomKey,
        seeds: <String>['127.0.0.1:${host.port}'],
      ),
      identity: guestIdentity,
      displayName: '访客',
      inbox: ShareInbox(store, Directory('${workspace.path}/guest-inbox')),
      ledger: ledger,
      reports: reports,
      blocklist: blocklist,
    );

    final bytes = Uint8List.fromList(
      List<int>.generate(8 * 1024, (index) => index & 0xff),
    );
    final file = File('${workspace.path}/待举报.flac');
    await file.writeAsBytes(bytes);
    final item = itemFor(bytes);
    await ledger.add(item.contentId);
    expect(await host.addLocalItem(item, file), isTrue);

    await _waitFor(guest, (state) => state.remoteItems.isNotEmpty);
    await guest.request(item);
    final received = await _waitFor(guest, (state) => state.inbox.isNotEmpty);
    final entry = received.inbox.single;

    await guest.report(entry, reason: 'suspected_unlicensed');

    final after = await _waitFor(guest, (state) => state.inbox.isEmpty);
    expect(after.inbox, isEmpty);
    expect(await File(entry.path).exists(), isFalse);

    final logged = await reports.load();
    expect(logged, hasLength(1));
    expect(logged.single.contentId, item.contentId);
    expect(logged.single.reason, 'suspected_unlicensed');
    expect(logged.single.name, '夜航.flac');
    // 举报等于撤销：这个编号进本地黑名单，之后不再接收。
    expect(await blocklist.has(item.contentId), isTrue);
  });

  test('查重命中已知商业录音的条目不往外发', () async {
    await startPair(
      hostLookup: (item, file) async => '夜航 — 某商业发行',
    );
    final bytes = Uint8List.fromList(
      List<int>.generate(4 * 1024, (index) => index & 0xff),
    );
    final file = File('${workspace.path}/查重.flac');
    await file.writeAsBytes(bytes);
    final item = itemFor(bytes);
    await ledger.add(item.contentId);
    expect(await host.addLocalItem(item, file), isTrue);

    await _waitFor(guest, (state) => state.remoteItems.isNotEmpty);
    await guest.request(item);

    // 拒在房主那一侧：他手上有文件，才查得动。
    final failed = await _waitFor(host, (state) => state.lastError != null);
    expect(failed.lastError, contains('rejected_known_recording'));
    expect(guest.state.inbox, isEmpty);
  });

  test('关掉房间后状态是 closed', () async {
    await startPair();
    await guest.close();
    expect(guest.state.phase, ShareSessionPhase.closed);
    await host.close();
    expect(host.state.phase, ShareSessionPhase.closed);
  });
}
