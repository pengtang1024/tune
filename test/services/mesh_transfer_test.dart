import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_messages.dart';
import 'package:tune/data/services/mesh/mesh_peer.dart';
import 'package:tune/data/services/mesh/mesh_protocol.dart';
import 'package:tune/data/services/mesh/mesh_room.dart';
import 'package:tune/data/services/mesh/mesh_transfer.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

List<int> _key(int seed) => List<int>.generate(32, (index) => (seed + index) & 0xff);

ShareItem _itemFor(Uint8List bytes, String name) {
  return ShareItem(
    contentId: MeshCrypto.contentIdOf(bytes),
    name: name,
    sizeBytes: bytes.length,
    provenance: ShareProvenance.ownRecording,
    createdAt: DateTime.utc(2026, 11, 16),
  );
}

void main() {
  late Directory workspace;
  late MeshRoom host;
  late MeshRoom guest;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-mesh-transfer-');
    host = MeshRoom(roomKey: _key(4), displayName: '主机');
    guest = MeshRoom(roomKey: _key(4), displayName: '访客');
  });

  tearDown(() async {
    await guest.close();
    await host.close();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  Future<(MeshPeer, MeshPeer)> connect() async {
    final port = await host.listen(address: InternetAddress.loopbackIPv4);
    final joined = host.joined.first.timeout(const Duration(seconds: 2));
    final guestSide = await guest.dial('127.0.0.1', port);
    final hostSide = await joined;
    return (hostSide, guestSide);
  }

  test('一整份文件分块传完并能验证内容编号', () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(700 * 1024, (index) => index * 31 & 0xff),
    );
    final source = File('${workspace.path}/来源.flac');
    await source.writeAsBytes(bytes);
    final item = _itemFor(bytes, '夜航');

    final (hostSide, guestSide) = await connect();
    final receiver = MeshFileReceiver(
      item: item,
      destination: '${workspace.path}/收件.flac',
    );
    final received = Completer<MeshReceiveResult>();

    guestSide.frames.listen((frame) async {
      if (frame.type != MeshMessageType.block) {
        return;
      }
      final block = MeshBlock.decodePayload(frame.payload);
      await receiver.accept(block);
      if (receiver.isComplete && !received.isCompleted) {
        received.complete(await receiver.finish());
      }
    });

    final sender = MeshFileSender(
      peer: hostSide,
      contentId: item.contentId,
      file: source,
      bytesPerSecond: 0,
    );
    final total = (item.sizeBytes + MeshBlock.blockBytes - 1) ~/ MeshBlock.blockBytes;
    final sent = await sender.serve(
      MeshWant(contentId: item.contentId, fromBlock: 0, blockCount: total),
    );

    final result = await received.future.timeout(const Duration(seconds: 10));
    expect(sent, total);
    expect(result.verified, isTrue, reason: result.reason);
    expect(result.bytes, bytes.length);
    expect(
      MeshCrypto.contentIdOf(await File(result.path).readAsBytes()),
      item.contentId,
    );
  });

  test('断点续传：只补缺的那几块', () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(600 * 1024, (index) => index & 0xff),
    );
    final source = File('${workspace.path}/来源.wav');
    await source.writeAsBytes(bytes);
    final item = _itemFor(bytes, '断点');
    final total = (item.sizeBytes + MeshBlock.blockBytes - 1) ~/ MeshBlock.blockBytes;

    final (hostSide, guestSide) = await connect();
    final receiver = MeshFileReceiver(
      item: item,
      destination: '${workspace.path}/续传.wav',
    );

    // 先手动灌第 0 块，模拟上次断在第二块。
    final raf = await source.open();
    await raf.setPosition(0);
    final firstChunk = await raf.read(MeshBlock.blockBytes);
    await raf.close();
    await receiver.accept(
      MeshBlock(
        contentId: item.contentId,
        index: 0,
        total: total,
        data: firstChunk,
      ),
    );

    final completion = Completer<MeshReceiveResult>();
    guestSide.frames.listen((frame) async {
      if (frame.type != MeshMessageType.block) {
        return;
      }
      await receiver.accept(MeshBlock.decodePayload(frame.payload));
      if (receiver.isComplete && !completion.isCompleted) {
        completion.complete(await receiver.finish());
      }
    });

    final sender = MeshFileSender(
      peer: hostSide,
      contentId: item.contentId,
      file: source,
      bytesPerSecond: 0,
    );
    final sent = await sender.serve(
      MeshWant(contentId: item.contentId, fromBlock: 1, blockCount: total - 1),
    );

    final result = await completion.future.timeout(const Duration(seconds: 10));
    expect(sent, total - 1);
    expect(result.verified, isTrue, reason: result.reason);
  });

  test('中途放弃会清掉半截文件', () async {
    final bytes = Uint8List.fromList(List<int>.generate(300 * 1024, (i) => i & 0xff));
    final item = _itemFor(bytes, '放弃');
    final destination = '${workspace.path}/半截.flac';
    final receiver = MeshFileReceiver(item: item, destination: destination);
    await receiver.accept(
      MeshBlock(
        contentId: item.contentId,
        index: 0,
        total: 2,
        data: Uint8List.fromList(List<int>.filled(128 * 1024, 1)),
      ),
    );
    final result = await receiver.finish();
    expect(result.verified, isFalse);
    expect(result.reason, 'incomplete');
    expect(await File(destination).exists(), isFalse);

    await receiver.accept(
      MeshBlock(
        contentId: item.contentId,
        index: 0,
        total: 2,
        data: Uint8List.fromList(List<int>.filled(128 * 1024, 1)),
      ),
    );
    await receiver.abort();
    expect(await File(destination).exists(), isFalse);
  });

  test('块数或内容编号对不上时拒绝接收', () async {
    final bytes = Uint8List.fromList(List<int>.generate(100, (i) => i));
    final item = _itemFor(bytes, '核对');
    final receiver = MeshFileReceiver(
      item: item,
      destination: '${workspace.path}/核对.flac',
    );
    expect(
      () => receiver.accept(
        MeshBlock(
          contentId: 'f' * 64,
          index: 0,
          total: 1,
          data: Uint8List(0),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => receiver.accept(
        MeshBlock(
          contentId: item.contentId,
          index: 0,
          total: 9,
          data: Uint8List(0),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('要错了内容时发送方直接拒绝', () async {
    final bytes = Uint8List.fromList(List<int>.generate(10, (i) => i));
    final source = File('${workspace.path}/x.bin');
    await source.writeAsBytes(bytes);
    final item = _itemFor(bytes, 'x');
    final (hostSide, _) = await connect();
    final sender = MeshFileSender(
      peer: hostSide,
      contentId: item.contentId,
      file: source,
      bytesPerSecond: 0,
    );
    await expectLater(
      sender.serve(
        MeshWant(contentId: 'e' * 64, fromBlock: 0, blockCount: 1),
      ),
      throwsArgumentError,
    );
  });

  test('零字节条目不会发出任何块', () async {
    final bytes = Uint8List(0);
    final source = File('${workspace.path}/空.bin');
    await source.writeAsBytes(bytes);
    final item = _itemFor(bytes, '空');
    final (hostSide, _) = await connect();
    final sender = MeshFileSender(
      peer: hostSide,
      contentId: item.contentId,
      file: source,
      bytesPerSecond: 0,
    );
    expect(
      await sender.serve(
        MeshWant(contentId: item.contentId, fromBlock: 0, blockCount: 1),
      ),
      0,
    );
  });
}
