import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_identity.dart';
import 'package:tune/data/services/mesh/room_invite.dart';
import 'package:tune/features/share/application/share_session.dart';
import 'package:tune/features/share/data/share_copy.dart';
import 'package:tune/features/share/data/share_inbox.dart';
import 'package:tune/features/share/data/share_label_writer.dart';
import 'package:tune/features/share/data/share_ledger.dart';
import 'package:tune/features/share/data/share_store.dart';
import 'package:tune/features/share/domain/share_declaration.dart';
import 'package:tune/features/share/domain/share_provenance.dart';
import 'package:tune/features/share/domain/share_session_state.dart';

/// 端到端合规链路：房主分享一个本机生成的文件，出门的不该是原始字节——
/// 必须是「开头加了提示音 + 容器里写了四条隐式标识」的副本，访客凭自己读回的
/// 标识收下（docs/ai-music-sharing.md §7）。
///
/// 素材由 ffmpeg 现场合成，不提交音频进仓库（docs/licensing.md）。CI 不装
/// ffmpeg（.github/workflows/ci.yml），所以整组按 _canRun 跳过。
final bool _canRun = _detectFfmpeg();

bool _detectFfmpeg() {
  try {
    return Process.runSync('ffmpeg', ['-version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

Future<void> _synthesizeFlac(Directory dir, String name) async {
  final result = await Process.run('ffmpeg', <String>[
    '-y',
    '-loglevel',
    'error',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=440:duration=0.6',
    '${dir.path}/$name',
  ]);
  expect(result.exitCode, 0, reason: '素材合成失败：${result.stderr}');
}

/// 用 ffmpeg 自己量时长，不复用实现的自检，避免「实现自己对自己」。
Future<int> _durationMsOf(String path) async {
  final result = await Process.run(
    'ffmpeg',
    <String>['-hide_banner', '-i', path],
  );
  final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)')
      .firstMatch('${result.stderr}${result.stdout}');
  expect(match, isNotNull, reason: '量不出时长：${result.stderr}');
  final seconds = double.parse(match!.group(3)!);
  return (int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!)) * 1000 +
      (seconds * 1000).round();
}

Future<ShareSessionState> _waitFor(
  ShareSession session,
  bool Function(ShareSessionState state) predicate, {
  Duration timeout = const Duration(seconds: 20),
}) {
  if (predicate(session.state)) {
    return Future<ShareSessionState>.value(session.state);
  }
  return session.states.firstWhere(predicate).timeout(timeout);
}

void main() {
  late Directory workspace;
  late MeshIdentity hostIdentity;
  late MeshIdentity guestIdentity;
  late ShareSession host;
  late ShareSession guest;
  late ShareLedger ledger;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-share-copy-');
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

  Future<void> startPair() async {
    final store = ShareStore.inMemory();
    ledger = ShareLedger(store);
    host = await ShareSession.host(
      identity: hostIdentity,
      displayName: '房主',
      inbox: ShareInbox(store, Directory('${workspace.path}/host-inbox')),
      ledger: ledger,
      copyBuilder: const ShareCopyBuilder(),
      labelWriter: const ShareLabelWriter(),
      outbox: Directory('${workspace.path}/outbox'),
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
      // 访客台账是空的：这一条必须靠字节里的标识才进得来。
      ledger: ShareLedger(ShareStore.inMemory()),
      labelWriter: const ShareLabelWriter(),
    );
  }

  test(
    '生成物出门换成带标识的副本，访客凭标识收下',
    () async {
      await startPair();
      await _synthesizeFlac(workspace, '夜航.flac');
      final source = File('${workspace.path}/夜航.flac');
      final originId = await MeshCrypto.contentIdOfFile(source);
      final originSize = await source.length();
      final originMs = await _durationMsOf(source.path);

      final item = ShareDeclaration(
        provenance: ShareProvenance.generated,
        declaredAt: DateTime.utc(2026, 11, 18, 12),
      ).toItem(
        contentId: originId,
        name: '夜航.flac',
        sizeBytes: originSize,
      );
      // 房主台账只记源编号：副本没进过台账，所以收端只可能走标识这条路。
      await ledger.add(originId);

      expect(await host.addLocalItem(item, source), isTrue);

      final published = host.state.localItems.single;
      expect(published.contentId, isNot(originId), reason: '出门的必须是改过字节的副本');
      expect(published.sizeBytes, isNot(originSize));
      expect(published.name, contains('.ai-share.'));

      final copy = File(
        '${workspace.path}/outbox/${originId.substring(0, 12)}/'
        '${published.name}',
      );
      expect(await copy.exists(), isTrue, reason: '副本应落在按源编号分好的 outbox 里');
      expect(
        await MeshCrypto.contentIdOfFile(copy),
        published.contentId,
        reason: '清单里的编号必须等于副本最终字节的编号',
      );

      // 隐式标识：四条键真的在副本里，且 CONTENT_ID 指的是源文件。
      final labels = await const ShareLabelWriter().readLabels(copy);
      expect(labels['AI_GENERATED'], '1');
      expect(labels['GENERATOR'], '本机生成');
      expect(labels['CONTENT_ID'], originId);
      expect(labels['PRODUCER'], 'tune');

      // 显式标识：副本开头那段提示音，体现在时长上。
      final copyMs = await _durationMsOf(copy.path);
      expect(copyMs - originMs, closeTo(1300, 300));

      // 原始文件一个字节都不能动。
      expect(await MeshCrypto.contentIdOfFile(source), originId);

      final seen = await _waitFor(guest, (state) => state.remoteItems.isNotEmpty);
      expect(seen.remoteItems.single.item.contentId, published.contentId);
      expect(seen.remoteItems.single.manifestVerified, isTrue);

      await guest.request(published);
      final received = await _waitFor(guest, (state) => state.inbox.isNotEmpty);
      final entry = received.inbox.single;
      expect(entry.item.contentId, published.contentId);
      final receivedFile = File(entry.path);
      expect(
        await MeshCrypto.contentIdOfFile(receivedFile),
        published.contentId,
      );
      // 收件端读回同一组标识，才算这条真的合规。
      expect(await const ShareLabelWriter().hasRequiredLabels(receivedFile), isTrue);
      expect(await receivedFile.length(), published.sizeBytes);
    },
    skip: !_canRun,
  );

  test(
    '撤销会把副本从磁盘拿掉，原始文件不动',
    () async {
      await startPair();
      await _synthesizeFlac(workspace, '撤销副本.flac');
      final source = File('${workspace.path}/撤销副本.flac');
      final originId = await MeshCrypto.contentIdOfFile(source);
      final item = ShareDeclaration(
        provenance: ShareProvenance.generated,
        declaredAt: DateTime.utc(2026, 11, 18, 12),
      ).toItem(
        contentId: originId,
        name: '撤销副本.flac',
        sizeBytes: await source.length(),
      );
      await ledger.add(originId);

      expect(await host.addLocalItem(item, source), isTrue);
      final copyId = host.state.localItems.single.contentId;
      final copy = File(
        '${workspace.path}/outbox/${originId.substring(0, 12)}/'
        '撤销副本.ai-share.flac',
      );
      expect(await copy.exists(), isTrue);

      await host.revoke(copyId);

      expect(host.state.localItems, isEmpty);
      expect(await copy.exists(), isFalse, reason: '派生副本是分享产物，撤销要一起删');
      // 原始文件是用户的，撤销不动它。
      expect(await source.exists(), isTrue);
    },
    skip: !_canRun,
  );
}
