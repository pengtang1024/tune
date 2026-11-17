import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_protocol.dart';
import 'package:tune/data/services/mesh/mesh_room.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

List<int> _key(int seed) => List<int>.generate(32, (index) => (seed + index) & 0xff);

Future<void> _pump([Duration duration = const Duration(milliseconds: 60)]) =>
    Future<void>.delayed(duration);

void main() {
  group('房间互连', () {
    late MeshRoom host;
    late MeshRoom guest;

    setUp(() async {
      host = MeshRoom(roomKey: _key(1), displayName: '主机');
      guest = MeshRoom(roomKey: _key(1), displayName: '访客');
    });

    tearDown(() async {
      await guest.close();
      await host.close();
    });

    test('同一密钥的两个房间能握手并互见', () async {
      final port = await host.listen(address: InternetAddress.loopbackIPv4);
      expect(port, greaterThan(0));

      final joined = host.joined.first.timeout(const Duration(seconds: 2));
      final guestPeer = await guest.dial('127.0.0.1', port);
      expect(guestPeer.peerId, isNotEmpty);
      expect(guestPeer.displayName, '主机');

      final hostPeer = await joined;
      expect(hostPeer.displayName, '访客');
      expect(host.peers, hasLength(1));
      expect(guest.peers, hasLength(1));
      // 身份是「每条连接一个新号」，两端各自记的是对端的号，所以这里换着比。
      expect(guest.peers.single.peerId, guestPeer.peerId);
      expect(host.peers.single.peerId, hostPeer.peerId);
      expect(hostPeer.peerId, isNot(guestPeer.peerId));
    });

    test('握手之后能双向收帧', () async {
      final port = await host.listen(address: InternetAddress.loopbackIPv4);
      final joined = host.joined.first.timeout(const Duration(seconds: 2));
      final guestPeer = await guest.dial('127.0.0.1', port);
      final hostPeer = await joined;

      final toGuest = guestPeer.frames.first.timeout(
        const Duration(seconds: 2),
      );
      final toHost = hostPeer.frames.first.timeout(const Duration(seconds: 2));

      host.broadcast(MeshMessageType.ping, const <int>[]);
      guest.broadcast(MeshMessageType.pong, const <int>[1, 2, 3]);

      expect((await toGuest).type, MeshMessageType.ping);
      final pong = await toHost;
      expect(pong.type, MeshMessageType.pong);
      expect(pong.payload, <int>[1, 2, 3]);
    });

    test('密钥不同的房间握手被拒', () async {
      final port = await host.listen(address: InternetAddress.loopbackIPv4);
      final intruder = MeshRoom(roomKey: _key(9), displayName: '陌生人');
      addTearDown(intruder.close);

      await expectLater(
        intruder.dial('127.0.0.1', port),
        throwsA(isA<MeshRoomException>()),
      );
      await _pump(const Duration(milliseconds: 100));
      expect(host.peers, isEmpty);
    });

    test('对端断开后从成员表里消失', () async {
      final port = await host.listen(address: InternetAddress.loopbackIPv4);
      final joined = host.joined.first.timeout(const Duration(seconds: 2));
      await guest.dial('127.0.0.1', port);
      final hostPeer = await joined;
      expect(host.peers, hasLength(1));

      final departed = host.left.first.timeout(const Duration(seconds: 2));
      await guest.close();
      final leftPeer = await departed;
      expect(leftPeer.peerId, hostPeer.peerId);
      expect(host.peers, isEmpty);
    });

    test('房间满了之后不再接受新连接', () async {
      host = MeshRoom(roomKey: _key(1), displayName: '主机', maxPeers: 1);
      final port = await host.listen(address: InternetAddress.loopbackIPv4);
      final first = MeshRoom(roomKey: _key(1), displayName: '一号');
      addTearDown(first.close);
      final joined = host.joined.first.timeout(const Duration(seconds: 2));
      await first.dial('127.0.0.1', port);
      await joined;

      final second = MeshRoom(roomKey: _key(1), displayName: '二号');
      addTearDown(second.close);
      await expectLater(
        second.dial('127.0.0.1', port),
        throwsA(isA<MeshRoomException>()),
      );
    });

    test('关掉的房间拒绝再开与再连', () async {
      await host.close();
      await expectLater(
        host.listen(address: InternetAddress.loopbackIPv4),
        throwsA(isA<MeshRoomException>()),
      );
      await expectLater(
        host.dial('127.0.0.1', 1),
        throwsA(isA<MeshRoomException>()),
      );
    });
  });

  group('协议违规', () {
    test('不发 hello 就对端灌帧，连接被断', () async {
      final host = MeshRoom(roomKey: _key(2), displayName: '主机');
      addTearDown(host.close);
      final port = await host.listen(address: InternetAddress.loopbackIPv4);

      final socket = await Socket.connect('127.0.0.1', port);
      socket.add(
        MeshFrameCodec.encode(
          MeshMessageType.inventory,
          MeshFrameCodec.encodeJson(<String, Object?>{'peerId': 'x'}),
        ),
      );
      await socket.flush();
      await _pump(const Duration(milliseconds: 120));
      expect(host.peers, isEmpty);
      socket.destroy();
    });

    test('房间广播发给未知类型不会崩', () {
      final room = MeshRoom(roomKey: _key(3), displayName: '空房');
      addTearDown(room.close);
      expect(room.broadcast(MeshMessageType.ping, Uint8List(0)), 0);
      expect(room.peers, isEmpty);
      expect(room.port, 0);
      expect(room.isListening, isFalse);
    });
  });

  group('条目缘起与房间无关但走同一条协议', () {
    test('wireName 稳定', () {
      expect(ShareProvenance.ownRecording.wireName, 'own_recording');
      expect(ShareProvenance.parse('licensed'), ShareProvenance.licensed);
      expect(ShareProvenance.parse('pirated'), isNull);
    });
  });
}
