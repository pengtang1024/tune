import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// M1 会话加密：每条连接一对 X25519 临时密钥 + HKDF-SHA256 派生 +
/// ChaCha20-Poly1305 载荷加密。
///
/// 握手双方在 hello 里交换临时公钥（它本身是公开的，且被房间证明绑定），
/// 连接建立后各自用临时私钥与对方公钥算出共享密钥，再用 HKDF 派生两把
/// 方向密钥：盐取双方临时公钥按字典序拼接（绑定握手转录，两端算得一致），
/// info 带方向标签——自己的发送密钥必须等于对端的接收密钥，两个方向
/// 不共用一把钥匙，杜绝 nonce 复用。载荷的 nonce 是每方向 12 字节递增
/// 计数器，接收端按到达顺序严格递增；AAD 绑外层帧的类型字节（类型明文、
/// 载荷密文）。任何一步失败都抛 [MeshSessionCryptoException]，由调用方
/// 断开连接——没有回落明文的路径。
abstract final class MeshSessionCrypto {
  /// HKDF info 的前缀，把本协议的派生与其他用途隔开。
  static const String _infoPrefix = 'tune-share-session-v1';

  static const int _keyBytes = 32;

  /// X25519 公钥长度；hello 里的临时公钥必须正好这么长。
  static const int pubKeyBytes = 32;

  static const int _nonceBytes = 12;
  static const int _macBytes = 16;

  /// 密封格式相对明文的开销：12 字节 nonce + 16 字节 MAC。
  static const int sealedOverheadBytes = _nonceBytes + _macBytes;

  static final X25519 _exchange = X25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: _keyBytes);
  static final Chacha20 _cipher = Chacha20.poly1305Aead();

  /// 为一条新连接生成一对临时 X25519 密钥。
  static Future<SimpleKeyPair> newKeyPair() => _exchange.newKeyPair();

  /// 临时公钥的十六进制形式，进 hello、进证明材料。
  static Future<String> pubKeyHex(SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    return _hex(publicKey.bytes);
  }

  /// 派生一个方向的会话密钥。
  ///
  /// 方向标签按「字典序较小的公钥那一端」命名（a-to-b / b-to-a）：
  /// 两端各自算，得到的标签集合一致，发送密钥与对端接收密钥必然成对。
  static Future<SecretKey> deriveKey({
    required SimpleKeyPair localKeyPair,
    required String remotePubHex,
    required bool outbound,
  }) async {
    final remote = _unhex(remotePubHex);
    if (remote.length != pubKeyBytes) {
      throw const MeshSessionCryptoException(
        'remote ephemeral public key must be 32 bytes',
      );
    }
    final local = (await localKeyPair.extractPublicKey()).bytes;
    final localHex = _hex(local);
    final localIsFirst = localHex.compareTo(remotePubHex) < 0;
    // 盐绑定握手转录：双方临时公钥都进了密钥材料，中间人换掉任何一把，
    // 两边算出的密钥就对不上。
    final salt = localIsFirst
        ? <int>[...local, ...remote]
        : <int>[...remote, ...local];
    final label = outbound
        ? (localIsFirst ? 'a-to-b' : 'b-to-a')
        : (localIsFirst ? 'b-to-a' : 'a-to-b');
    final shared = await _exchange.sharedSecretKey(
      keyPair: localKeyPair,
      remotePublicKey: SimplePublicKey(remote, type: KeyPairType.x25519),
    );
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: salt,
      info: utf8.encode('$_infoPrefix/$label'),
    );
  }

  /// 第 [counter] 帧的 nonce：12 字节，计数器按 64 位大端放进后 8 字节。
  static Uint8List nonceOf(int counter) {
    final nonce = Uint8List(_nonceBytes);
    for (var index = 0; index < 8; index++) {
      nonce[_nonceBytes - 1 - index] = (counter >> (8 * index)) & 0xff;
    }
    return nonce;
  }

  /// 加密一帧载荷，返回 `nonce || cipherText || mac` 的密封字节。
  static Future<Uint8List> encrypt({
    required SecretKey key,
    required int counter,
    required int frameType,
    required List<int> payload,
  }) async {
    final box = await _cipher.encrypt(
      payload,
      secretKey: key,
      nonce: nonceOf(counter),
      aad: <int>[frameType & 0xff],
    );
    return Uint8List.fromList(box.concatenation());
  }

  /// 解密一帧载荷。密封格式、MAC、AAD 任何一处不对都抛错，调用方断连。
  static Future<Uint8List> decrypt({
    required SecretKey key,
    required int counter,
    required int frameType,
    required List<int> sealed,
  }) async {
    if (sealed.length < _nonceBytes + _macBytes) {
      throw const MeshSessionCryptoException('sealed frame too short');
    }
    final box = SecretBox.fromConcatenation(
      sealed,
      nonceLength: _nonceBytes,
      macLength: _macBytes,
    );
    try {
      final plain = await _cipher.decrypt(
        box,
        secretKey: key,
        aad: <int>[frameType & 0xff],
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError catch (error) {
      throw MeshSessionCryptoException('frame authentication failed: $error');
    } on Object catch (error) {
      throw MeshSessionCryptoException('frame decrypt failed: $error');
    }
  }

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// 解析失败或奇数长度都返回空表——长度校验会把坏输入挡下来。
  static Uint8List _unhex(String hex) {
    if (hex.length.isOdd) {
      return Uint8List(0);
    }
    final bytes = Uint8List(hex.length ~/ 2);
    for (var index = 0; index < bytes.length; index++) {
      final high = int.tryParse(
        hex.substring(index * 2, index * 2 + 1),
        radix: 16,
      );
      final low = int.tryParse(
        hex.substring(index * 2 + 1, index * 2 + 2),
        radix: 16,
      );
      if (high == null || low == null) {
        return Uint8List(0);
      }
      bytes[index] = high * 16 + low;
    }
    return bytes;
  }
}

/// 一条连接的两把方向密钥。outbound 只管发、inbound 只管收，永不混用。
class MeshSessionKeys {
  const MeshSessionKeys({required this.outbound, required this.inbound});

  final SecretKey outbound;
  final SecretKey inbound;
}

/// 会话加密层的错误。它出现在哪条连接，哪条连接就该断开。
class MeshSessionCryptoException implements Exception {
  const MeshSessionCryptoException(this.message);

  final String message;

  @override
  String toString() => 'MeshSessionCryptoException: $message';
}
