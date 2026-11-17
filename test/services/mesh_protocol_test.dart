import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_messages.dart';
import 'package:tune/data/services/mesh/mesh_protocol.dart';
import 'package:tune/data/services/mesh/room_invite.dart';
import 'package:tune/features/share/domain/share_ai_disclosure.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

const String _cidA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _cidB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

ShareItem _item({
  String contentId = _cidA,
  int sizeBytes = 1024,
  ShareProvenance provenance = ShareProvenance.ownRecording,
  Set<String> evidenceHashes = const <String>{'e1'},
  ShareAiDisclosure aiDisclosure = ShareAiDisclosure.none,
}) {
  return ShareItem(
    contentId: contentId,
    name: '夜航',
    artist: '我自己',
    sizeBytes: sizeBytes,
    provenance: provenance,
    evidenceHashes: evidenceHashes,
    aiDisclosure: aiDisclosure,
    createdAt: DateTime.utc(2026, 11, 16, 12),
  );
}

void main() {
  group('帧编解码', () {
    test('整帧往返保持类型与载荷', () {
      final payload = MeshFrameCodec.encodeJson(<String, Object?>{'a': 1});
      final frame = MeshFrameCodec.encode(MeshMessageType.ping, payload);
      final frames = MeshFrameDecoder().add(frame);
      expect(frames, hasLength(1));
      expect(frames.single.type, MeshMessageType.ping);
      expect(MeshFrameCodec.decodeJson(frames.single.payload), {'a': 1});
    });

    test('字节被切碎也能拼回同一帧', () {
      final frame = MeshFrameCodec.encode(
        MeshMessageType.inventory,
        MeshFrameCodec.encodeJson(<String, Object?>{'peerId': 'p1'}),
      );
      final decoder = MeshFrameDecoder();
      final frames = <MeshFrame>[];
      for (final byte in frame) {
        frames.addAll(decoder.add(<int>[byte]));
      }
      expect(frames, hasLength(1));
      expect(frames.single.type, MeshMessageType.inventory);
      expect(decoder.bufferedBytes, 0);
    });

    test('一次灌多帧能全部切出来', () {
      final a = MeshFrameCodec.encode(MeshMessageType.ping, const <int>[]);
      final b = MeshFrameCodec.encode(MeshMessageType.pong, const <int>[]);
      final frames = MeshFrameDecoder().add(<int>[...a, ...b]);
      expect(frames.map((frame) => frame.type), [
        MeshMessageType.ping,
        MeshMessageType.pong,
      ]);
    });

    test('超大长度直接报错，不缓存垃圾', () {
      final decoder = MeshFrameDecoder();
      expect(
        () => decoder.add(<int>[0x7f, 0xff, 0xff, 0xff, 1]),
        throwsA(isA<MeshProtocolException>()),
      );
      expect(decoder.bufferedBytes, 0);
    });

    test('未知类型字节直接报错', () {
      expect(
        () => MeshFrameDecoder().add(<int>[0, 0, 0, 1, 99]),
        throwsA(isA<MeshProtocolException>()),
      );
    });
  });

  group('房间密钥与邀请码', () {
    test('房间号由密钥派生且稳定', () {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      expect(MeshCrypto.roomIdOf(key), MeshCrypto.roomIdOf(key));
      expect(MeshCrypto.roomIdOf(key).length, 16);
    });

    test('邀请码往返保住密钥与种子地址', () {
      final invite = RoomInvite.create(seeds: <String>['192.168.1.20:47001']);
      final parsed = RoomInvite.tryParse(invite.encode());
      expect(parsed, isNotNull);
      expect(parsed!.roomKey, invite.roomKey);
      expect(parsed.seeds.first, '192.168.1.20:47001');
      expect(parsed.roomId, invite.roomId);
    });

    test('没有种子地址的邀请码也能往返', () {
      final invite = RoomInvite.create();
      final parsed = RoomInvite.tryParse(invite.encode());
      expect(parsed?.seeds, isEmpty);
      expect(parsed?.roomKey, invite.roomKey);
    });

    test('坏邀请码一律拒绝', () {
      expect(RoomInvite.tryParse(''), isNull);
      expect(RoomInvite.tryParse('tune-share1:not-base64!'), isNull);
      expect(
        RoomInvite.tryParse('tune-share1:${base64Url.encode(Uint8List(8))}'),
        isNull,
      );
      expect(RoomInvite.isWellFormedSeed('host'), isFalse);
      expect(RoomInvite.isWellFormedSeed(':123'), isFalse);
      expect(RoomInvite.isWellFormedSeed('host:0'), isFalse);
      expect(RoomInvite.isWellFormedSeed('host:70000'), isFalse);
      expect(RoomInvite.isWellFormedSeed('10.0.0.2:7000'), isTrue);
    });
  });

  group('握手与清单', () {
    test('手持房间密钥的 hello 能验过，换成别的密钥就验不过', () {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => 31 - i));
      final hello = MeshHello.create(roomKey: key, displayName: '本机');
      expect(hello.verifyWith(key), isTrue);
      final other = Uint8List.fromList(List<int>.filled(32, 7));
      expect(hello.verifyWith(other), isFalse);
    });

    test('篡改 random 后证明失效', () {
      final key = Uint8List.fromList(List<int>.filled(32, 9));
      final hello = MeshHello.create(roomKey: key, displayName: '本机');
      final tampered = MeshHello(
        roomId: hello.roomId,
        peerId: hello.peerId,
        nonce: '0123456789abcdef',
        proof: hello.proof,
        displayName: hello.displayName,
      );
      expect(tampered.verifyWith(key), isFalse);
    });

    test('清单往返保住条目事实，坏条目让整份清单作废', () {
      final inventory = MeshInventory(peerId: 'p1', items: [_item()]);
      final parsed = MeshInventory.tryFromJson(inventory.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.items.single.contentId, _cidA);
      expect(parsed.items.single.provenance, ShareProvenance.ownRecording);

      final dirty = parsed.toJson();
      dirty['items'] = <Object?>[
        <String, Object?>{'contentId': 'nope'},
        _item().toJson(),
      ];
      // 丢掉一条会让签名对不上，所以宁可整份不认，也不悄悄少几条。
      expect(MeshInventory.tryFromJson(dirty), isNull);
    });

    test('want 拒绝倒序与零长度', () {
      expect(
        MeshWant.tryFromJson(<String, Object?>{
          'contentId': _cidA,
          'fromBlock': -1,
          'blockCount': 2,
        }),
        isNull,
      );
      expect(
        MeshWant.tryFromJson(<String, Object?>{
          'contentId': _cidA,
          'fromBlock': 0,
          'blockCount': 0,
        }),
        isNull,
      );
      expect(
        MeshWant.tryFromJson(<String, Object?>{
          'contentId': _cidA,
          'fromBlock': 3,
          'blockCount': 2,
        })?.fromBlock,
        3,
      );
    });
  });

  group('数据块', () {
    test('块载荷往返', () {
      final block = MeshBlock(
        contentId: _cidB,
        index: 2,
        total: 5,
        data: _bytes('声音'),
      );
      final decoded = MeshBlock.decodePayload(MeshBlock.encodePayload(block));
      expect(decoded.contentId, block.contentId);
      expect(decoded.index, 2);
      expect(decoded.total, 5);
      expect(decoded.data, block.data);
    });

    test('越界块序号与坏编号被拒绝', () {
      expect(
        () => MeshBlock.encodePayload(
          MeshBlock(
            contentId: _cidB,
            index: 5,
            total: 5,
            data: Uint8List(0),
          ),
        ),
        throwsA(isA<MeshProtocolException>()),
      );
      expect(
        () => MeshBlock.encodePayload(
          MeshBlock(
            contentId: 'short',
            index: 0,
            total: 1,
            data: Uint8List(0),
          ),
        ),
        throwsA(isA<MeshProtocolException>()),
      );
      expect(
        () => MeshBlock.decodePayload(Uint8List(10)),
        throwsA(isA<MeshProtocolException>()),
      );
    });
  });
}
