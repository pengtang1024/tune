import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_messages.dart';
import 'package:tune/data/services/mesh/mesh_peer.dart';
import 'package:tune/data/services/mesh/mesh_protocol.dart';
import 'package:tune/data/services/mesh/mesh_session_crypto.dart';

List<int> _key(int seed) =>
    List<int>.generate(32, (index) => (seed + index) & 0xff);

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

/// 一对已经连上的真实 TCP socket：local 是主动连出的一端，remote 是接受的一端。
Future<({Socket local, Socket remote, ServerSocket listener})> _socketPair() async {
  final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final accepted = Completer<Socket>();
  final subscription = listener.listen(accepted.complete);
  final local = await Socket.connect(InternetAddress.loopbackIPv4, listener.port);
  final remote = await accepted.future.timeout(const Duration(seconds: 5));
  await subscription.cancel();
  return (local: local, remote: remote, listener: listener);
}

/// 一对完成了握手、可以直接互发加密帧的 MeshPeer，底层是真实 socket。
Future<({MeshPeer host, MeshPeer guest, ServerSocket listener})> _handshake() async {
  final sockets = await _socketPair();
  final hostPair = await MeshSessionCrypto.newKeyPair();
  final guestPair = await MeshSessionCrypto.newKeyPair();
  final roomKey = _key(1);
  final hostHello = MeshHello.create(
    roomKey: roomKey,
    ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(hostPair),
    displayName: '主机',
  );
  final guestHello = MeshHello.create(
    roomKey: roomKey,
    ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(guestPair),
    displayName: '访客',
  );
  final hostReady = MeshPeer.accept(
    sockets.remote,
    roomKey: roomKey,
    localHello: hostHello,
    ephemeralKeyPair: hostPair,
  );
  // dial 会在构造时同步把自己的 hello 发出去，accept 才能等到它。
  final guestReady = MeshPeer.dial(
    sockets.local,
    roomKey: roomKey,
    localHello: guestHello,
    ephemeralKeyPair: guestPair,
  );
  final host = await hostReady.timeout(const Duration(seconds: 5));
  final guest = await guestReady.timeout(const Duration(seconds: 5));
  return (host: host, guest: guest, listener: sockets.listener);
}

void main() {
  group('会话加密', () {
    test('密封字节是密文：不含明文片段，方向密钥两端成对', () async {
      final plain = utf8.encode('密文探针 AI-music-disclosure-payload');
      final alice = await MeshSessionCrypto.newKeyPair();
      final bob = await MeshSessionCrypto.newKeyPair();
      final alicePub = await MeshSessionCrypto.pubKeyHex(alice);
      final bobPub = await MeshSessionCrypto.pubKeyHex(bob);
      final outKey = await MeshSessionCrypto.deriveKey(
        localKeyPair: alice,
        remotePubHex: bobPub,
        outbound: true,
      );
      final inKey = await MeshSessionCrypto.deriveKey(
        localKeyPair: bob,
        remotePubHex: alicePub,
        outbound: false,
      );

      final sealed = await MeshSessionCrypto.encrypt(
        key: outKey,
        counter: 0,
        frameType: MeshMessageType.inventory.code,
        payload: plain,
      );
      // 线上格式是 ChaCha20-Poly1305：密封字节既不等于明文，也解不出探针
      // 内容，长度恰好多出 12 字节 nonce + 16 字节 MAC。
      expect(sealed, isNot(plain));
      final wire = utf8.decode(sealed, allowMalformed: true);
      expect(wire, isNot(contains('密文探针')));
      expect(wire, isNot(contains('AI-music-disclosure-payload')));
      expect(sealed.length, plain.length + MeshSessionCrypto.sealedOverheadBytes);

      // 方向密钥成对：Alice 的发送密钥就是 Bob 的接收密钥，能解回原样。
      final round = await MeshSessionCrypto.decrypt(
        key: inKey,
        counter: 0,
        frameType: MeshMessageType.inventory.code,
        sealed: sealed,
      );
      expect(round, plain);
    });

    test('真实连接端到端回环：对端收到原样载荷', () async {
      final session = await _handshake();
      addTearDown(() async {
        await session.guest.close();
        await session.host.close();
        await session.listener.close();
      });

      final plain = utf8.encode('端到端探针 AI-music-disclosure-payload');
      final first = session.guest.frames.first.timeout(const Duration(seconds: 5));
      expect(session.host.send(MeshMessageType.inventory, plain), isTrue);

      final frame = await first;
      expect(frame.type, MeshMessageType.inventory);
      // frames 流是解密后的视图：内容与发送方逐字节一致；线上字节确为
      // 密文，由上一条的密封字节断言与篡改断连用例共同证明。
      expect(frame.payload, plain);
    });

    test('密文被篡改一字节就断开连接，不投递任何帧', () async {
      final sockets = await _socketPair();
      addTearDown(() async {
        await sockets.listener.close();
      });
      final roomKey = _key(1);
      final hostPair = await MeshSessionCrypto.newKeyPair();
      final rawPair = await MeshSessionCrypto.newKeyPair();
      final hostHello = MeshHello.create(
        roomKey: roomKey,
        ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(hostPair),
        displayName: '主机',
      );
      final rawHello = MeshHello.create(
        roomKey: roomKey,
        ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(rawPair),
        displayName: '篡改者',
      );

      final hostReady = MeshPeer.accept(
        sockets.remote,
        roomKey: roomKey,
        localHello: hostHello,
        ephemeralKeyPair: hostPair,
      );
      sockets.local.add(
        MeshFrameCodec.encode(
          MeshMessageType.hello,
          MeshFrameCodec.encodeJson(rawHello.toJson()),
        ),
      );
      final hostPeer = await hostReady.timeout(const Duration(seconds: 5));
      addTearDown(hostPeer.close);

      // 裸 socket 侧：读完对端 hello，用同一套派生算法算出发送密钥。
      final decoder = MeshFrameDecoder();
      final hostHelloWire = Completer<MeshFrame>();
      sockets.local.listen((data) {
        if (hostHelloWire.isCompleted) {
          return;
        }
        for (final frame in decoder.add(data)) {
          if (frame.type == MeshMessageType.hello) {
            hostHelloWire.complete(frame);
            return;
          }
        }
      });
      final hello = await hostHelloWire.future.timeout(const Duration(seconds: 5));
      final hostPub =
          MeshFrameCodec.decodeJson(hello.payload)['ephemeralPubKey']! as String;
      final outbound = await MeshSessionCrypto.deriveKey(
        localKeyPair: rawPair,
        remotePubHex: hostPub,
        outbound: true,
      );

      final sealed = await MeshSessionCrypto.encrypt(
        key: outbound,
        counter: 0,
        frameType: MeshMessageType.inventory.code,
        payload: utf8.encode('这帧永远不应该以明文到达对端'),
      );
      final tampered = Uint8List.fromList(sealed);
      tampered[tampered.length - 1] ^= 0x01;
      sockets.local.add(
        MeshFrameCodec.encode(MeshMessageType.inventory, tampered),
      );

      // MAC 对不上就断线：closed 完成，帧流一条都不投递。
      await hostPeer.closed.timeout(const Duration(seconds: 5));
      await expectLater(
        hostPeer.frames.first.timeout(const Duration(seconds: 2)),
        throwsA(isA<StateError>()),
      );
      sockets.local.destroy();
    });

    test('多帧大块按序完整到达', () async {
      final session = await _handshake();
      addTearDown(() async {
        await session.guest.close();
        await session.host.close();
        await session.listener.close();
      });

      final sent = <Uint8List>[];
      for (var i = 0; i < 8; i++) {
        final payload = Uint8List(1 << 20);
        for (var j = 0; j < payload.length; j++) {
          payload[j] = (i + j) & 0xff;
        }
        sent.add(payload);
      }
      for (final payload in sent) {
        expect(session.host.send(MeshMessageType.block, payload), isTrue);
      }

      final received = await session.guest.frames
          .take(sent.length)
          .toList()
          .timeout(const Duration(seconds: 60));
      expect(received, hasLength(sent.length));
      for (var i = 0; i < sent.length; i++) {
        expect(received[i].type, MeshMessageType.block);
        expect(received[i].payload, sent[i]);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('缺临时公钥的旧版 hello 直接拒之门外', () async {
      final sockets = await _socketPair();
      addTearDown(() async {
        await sockets.listener.close();
      });
      final roomKey = _key(1);
      final hostPair = await MeshSessionCrypto.newKeyPair();
      final hostHello = MeshHello.create(
        roomKey: roomKey,
        ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(hostPair),
        displayName: '主机',
      );

      // 证明按旧材料（不含临时公钥）算，且房间号正确——这样被拒的原因
      // 只能是「缺 ephemeralPubKey 字段」，而不是证明本身算错。
      final peerId = MeshCrypto.randomHex(16);
      final nonce = MeshCrypto.randomHex(MeshCrypto.nonceBytes);
      final legacy = <String, Object?>{
        'roomId': MeshCrypto.roomIdOf(roomKey),
        'peerId': peerId,
        'nonce': nonce,
        'proof': _hex(
          MeshCrypto.roomProof(
            roomKey: roomKey,
            peerId: peerId,
            nonce: utf8.encode(nonce),
            ephemeralPubKey: const <int>[],
          ),
        ),
        'displayName': '老版本',
      };

      final rejected = MeshPeer.accept(
        sockets.remote,
        roomKey: roomKey,
        localHello: hostHello,
        ephemeralKeyPair: hostPair,
      );
      sockets.local.add(
        MeshFrameCodec.encode(
          MeshMessageType.hello,
          MeshFrameCodec.encodeJson(legacy),
        ),
      );
      await expectLater(
        rejected.timeout(const Duration(seconds: 5)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('hello proof rejected'),
          ),
        ),
      );
      sockets.local.destroy();
    });
  });
}
