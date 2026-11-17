import 'dart:convert';
import 'dart:typed_data';

import '../../../features/share/domain/share_item.dart';
import 'mesh_crypto.dart';
import 'mesh_identity.dart';
import 'mesh_protocol.dart';

/// 入房握手。`proof` 是用房间密钥对 `peerId + nonce` 算的 HMAC。
class MeshHello {
  const MeshHello({
    required this.roomId,
    required this.peerId,
    required this.nonce,
    required this.proof,
    required this.displayName,
    this.identityId = '',
    this.listenPort = 0,
  });

  final String roomId;
  final String peerId;
  final String nonce;
  final String proof;
  final String displayName;

  /// 对端的稳定身份号（`MeshIdentity.peerId`）；老版本没有时为空。
  final String identityId;

  /// 对端监听的端口，用来把星形补成全互联；0 表示不知道。
  final int listenPort;

  /// 用本地房间密钥算一条自证。
  static MeshHello create({
    required List<int> roomKey,
    required String displayName,
    String identityId = '',
    int listenPort = 0,
    String? nonce,
  }) {
    final peerId = MeshCrypto.randomHex(16);
    final helloNonce = nonce ?? MeshCrypto.randomHex(MeshCrypto.nonceBytes);
    final proof = MeshCrypto.roomProof(
      roomKey: roomKey,
      peerId: peerId,
      nonce: utf8.encode(helloNonce),
    );
    return MeshHello(
      roomId: MeshCrypto.roomIdOf(roomKey),
      peerId: peerId,
      nonce: helloNonce,
      proof: _hex(proof),
      displayName: displayName,
      identityId: identityId,
      listenPort: listenPort,
    );
  }

  /// 对端证明是否正确，顺带核对房间号——两件事一起验，少一个都别放进来。
  bool verifyWith(List<int> roomKey) {
    if (roomId != MeshCrypto.roomIdOf(roomKey)) {
      return false;
    }
    final expected = MeshCrypto.roomProof(
      roomKey: roomKey,
      peerId: peerId,
      nonce: utf8.encode(nonce),
    );
    return MeshCrypto.constantTimeEquals(expected, _unhex(proof));
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'roomId': roomId,
    'peerId': peerId,
    'nonce': nonce,
    'proof': proof,
    'displayName': displayName,
    'identityId': identityId,
    'listenPort': listenPort,
  };

  static MeshHello? tryFromJson(Map<String, Object?> json) {
    final roomId = json['roomId'];
    final peerId = json['peerId'];
    final nonce = json['nonce'];
    final proof = json['proof'];
    final displayName = json['displayName'];
    if (roomId is! String ||
        peerId is! String ||
        nonce is! String ||
        proof is! String ||
        displayName is! String) {
      return null;
    }
    return MeshHello(
      roomId: roomId,
      peerId: peerId,
      nonce: nonce,
      proof: proof,
      displayName: displayName,
      identityId: json['identityId'] is String ? json['identityId']! as String : '',
      listenPort: json['listenPort'] is int ? json['listenPort']! as int : 0,
    );
  }
}

/// 清单帧：一个 peer 手上愿意给出的条目。
class MeshInventory {
  const MeshInventory({
    required this.peerId,
    required this.items,
    this.publicKeyBase64,
    this.signatureBase64,
  });

  /// 分享方的稳定身份号（`MeshIdentity.peerId`）。
  final String peerId;

  /// 这条清单里有哪些条目。
  final List<ShareItem> items;

  /// 分享方的 Ed25519 公钥；没签名时为空。
  final String? publicKeyBase64;

  /// 对清单正文的签名；没签名时为空。
  final String? signatureBase64;

  bool get isSigned => publicKeyBase64 != null && signatureBase64 != null;

  /// 清单正文：条目按内容编号排序后再编码，两端算出的字节必须一致。
  static Map<String, Object?> canonicalBody({
    required String peerId,
    required List<ShareItem> items,
  }) {
    final sorted = items.toList()
      ..sort((left, right) => left.contentId.compareTo(right.contentId));
    return <String, Object?>{
      'peerId': peerId,
      'items': sorted.map((item) => item.toJson()).toList(growable: false),
    };
  }

  static List<int> canonicalBytes({
    required String peerId,
    required List<ShareItem> items,
  }) {
    return utf8.encode(jsonEncode(canonicalBody(peerId: peerId, items: items)));
  }

  /// 用本机身份给清单签名。
  static Future<MeshInventory> sign({
    required MeshIdentity identity,
    required List<ShareItem> items,
  }) async {
    final body = canonicalBytes(peerId: identity.peerId, items: items);
    return MeshInventory(
      peerId: identity.peerId,
      items: items,
      publicKeyBase64: identity.publicKeyBase64,
      signatureBase64: await identity.signBytes(body),
    );
  }

  /// 验签：先确认 peerId 确实是这把公钥推出来的，再验正文签名。
  Future<bool> verify() async {
    final publicKey = publicKeyBase64;
    final signature = signatureBase64;
    if (publicKey == null || signature == null) {
      return false;
    }
    if (peerId != MeshIdentity.peerIdOf(publicKey)) {
      return false;
    }
    return MeshIdentity.verifyBytes(
      canonicalBytes(peerId: peerId, items: items),
      publicKeyBase64: publicKey,
      signatureBase64: signature,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'peerId': peerId,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    if (publicKeyBase64 != null) 'publicKey': publicKeyBase64,
    if (signatureBase64 != null) 'signature': signatureBase64,
  };

  /// 坏条目直接丢，整份清单不因为一条烂数据变成不可用。
  ///
  /// 被丢掉的条目会让签名对不上，所以签名清单里出现坏条目时 `verify()`
  /// 会失败——这正是想要的结果：悄悄少几条，不如整份不认。
  static MeshInventory? tryFromJson(Map<String, Object?> json) {
    final peerId = json['peerId'];
    final items = json['items'];
    final publicKey = json['publicKey'];
    final signature = json['signature'];
    if (peerId is! String || items is! List) {
      return null;
    }
    final parsed = <ShareItem>[];
    for (final entry in items) {
      if (entry is Map) {
        final item = ShareItem.tryFromJson(entry.cast<String, Object?>());
        if (item != null) {
          parsed.add(item);
        }
      }
    }
    if (parsed.length != items.length) {
      return null;
    }
    return MeshInventory(
      peerId: peerId,
      items: parsed,
      publicKeyBase64: publicKey is String ? publicKey : null,
      signatureBase64: signature is String ? signature : null,
    );
  }
}

/// 索要若干个块。`fromBlock` 允许断点续传。
class MeshWant {
  const MeshWant({
    required this.contentId,
    required this.fromBlock,
    required this.blockCount,
  });

  final String contentId;
  final int fromBlock;
  final int blockCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'contentId': contentId,
    'fromBlock': fromBlock,
    'blockCount': blockCount,
  };

  static MeshWant? tryFromJson(Map<String, Object?> json) {
    final contentId = json['contentId'];
    final fromBlock = json['fromBlock'];
    final blockCount = json['blockCount'];
    if (contentId is! String || fromBlock is! int || blockCount is! int) {
      return null;
    }
    if (fromBlock < 0 || blockCount <= 0) {
      return null;
    }
    return MeshWant(
      contentId: contentId,
      fromBlock: fromBlock,
      blockCount: blockCount,
    );
  }
}

/// 撤回：作者把条目从房间里拿掉，收到的人也要停手。
class MeshRevoke {
  const MeshRevoke({required this.contentId, required this.reason});

  final String contentId;
  final String reason;

  Map<String, Object?> toJson() => <String, Object?>{
    'contentId': contentId,
    'reason': reason,
  };

  static MeshRevoke? tryFromJson(Map<String, Object?> json) {
    final contentId = json['contentId'];
    final reason = json['reason'];
    if (contentId is! String || reason is! String) {
      return null;
    }
    return MeshRevoke(contentId: contentId, reason: reason);
  }
}

/// 数据块。载荷 = 64 字节十六进制 cid + 4 字节块序号 + 4 字节总数 + 字节。
class MeshBlock {
  const MeshBlock({
    required this.contentId,
    required this.index,
    required this.total,
    required this.data,
  });

  static const int blockBytes = 256 * 1024;

  /// cid 用 ASCII 十六进制而不是二进制，便于跨语言读日志。
  static const int contentIdAsciiBytes = 64;

  static const int _prefixBytes = contentIdAsciiBytes + 8;

  final String contentId;
  final int index;
  final int total;
  final Uint8List data;

  static Uint8List encodePayload(MeshBlock block) {
    if (block.total <= 0 || block.index < 0 || block.index >= block.total) {
      throw const MeshProtocolException('bad block index');
    }
    final payload = Uint8List(_prefixBytes + block.data.length);
    final idBytes = ascii.encode(block.contentId);
    if (idBytes.length != contentIdAsciiBytes) {
      throw const MeshProtocolException('bad content id width');
    }
    payload.setRange(0, contentIdAsciiBytes, idBytes);
    _writeUint32(payload, contentIdAsciiBytes, block.index);
    _writeUint32(payload, contentIdAsciiBytes + 4, block.total);
    payload.setRange(_prefixBytes, payload.length, block.data);
    return payload;
  }

  static MeshBlock decodePayload(Uint8List payload) {
    if (payload.length < _prefixBytes) {
      throw const MeshProtocolException('block payload too short');
    }
    final contentId = ascii.decode(
      payload.sublist(0, contentIdAsciiBytes),
      allowInvalid: false,
    );
    final index = _readUint32(payload, contentIdAsciiBytes);
    final total = _readUint32(payload, contentIdAsciiBytes + 4);
    if (total <= 0 || index >= total) {
      throw const MeshProtocolException('bad block header');
    }
    return MeshBlock(
      contentId: contentId,
      index: index,
      total: total,
      data: Uint8List.fromList(payload.sublist(_prefixBytes)),
    );
  }

  static void _writeUint32(Uint8List target, int offset, int value) {
    target[offset] = (value >> 24) & 0xff;
    target[offset + 1] = (value >> 16) & 0xff;
    target[offset + 2] = (value >> 8) & 0xff;
    target[offset + 3] = value & 0xff;
  }

  static int _readUint32(Uint8List source, int offset) {
    return (source[offset] << 24) |
        (source[offset + 1] << 16) |
        (source[offset + 2] << 8) |
        source[offset + 3];
  }
}

String _hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Uint8List _unhex(String value) {
  if (value.length.isOdd) {
    return Uint8List(0);
  }
  final bytes = Uint8List(value.length ~/ 2);
  for (var index = 0; index < bytes.length; index++) {
    final parsed = int.tryParse(value.substring(index * 2, index * 2 + 2), radix: 16);
    if (parsed == null) {
      return Uint8List(0);
    }
    bytes[index] = parsed;
  }
  return bytes;
}
