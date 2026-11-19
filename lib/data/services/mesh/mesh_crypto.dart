import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// mesh 层用到的全部密码学原语。
///
/// 对称的一层：房间密钥派生的证明、内容寻址、常量时间比较。
/// 非对称身份在 `mesh_identity.dart`（Ed25519），会话加密在
/// `mesh_session_crypto.dart`（X25519 + ChaCha20-Poly1305）——别在调用点各自造一套。
abstract final class MeshCrypto {
  /// 房间密钥长度。32 字节够长，也刚好能塞进邀请码。
  static const int roomKeyBytes = 32;

  /// 握手随机数的长度。
  static const int nonceBytes = 16;

  /// 字节的内容编号：SHA-256 的小写十六进制。
  static String contentIdOf(List<int> bytes) => _hex(sha256.convert(bytes).bytes);

  /// 文件的内容编号。分块读，几百 MB 的文件不会整个进内存。
  static Future<String> contentIdOfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return _hex(digest.bytes);
  }

  /// 房间证明：用房间密钥对「我是谁 + 挑战」做 HMAC。
  ///
  /// 不知道房间密钥的人算不出来，因此它同时完成入房认证与挑战应答。
  static Uint8List roomProof({
    required List<int> roomKey,
    required String peerId,
    required List<int> nonce,
    required List<int> ephemeralPubKey,
  }) {
    final mac = Hmac(sha256, roomKey);
    return Uint8List.fromList(
      mac.convert(<int>[...utf8.encode(peerId), ...nonce, ...ephemeralPubKey]).bytes,
    );
  }

  /// 房间标识由房间密钥派生，邀请码因此只需要带密钥。
  static String roomIdOf(List<int> roomKey) {
    final digest = sha256.convert(<int>[..._roomIdSalt, ...roomKey]).bytes;
    return _hex(digest.sublist(0, 8));
  }

  /// 定长随机串的十六进制表示，用于 peerId 与 nonce。
  static String randomHex(int bytes) {
    final random = Random.secure();
    final buffer = Uint8List(bytes);
    for (var index = 0; index < bytes; index++) {
      buffer[index] = random.nextInt(256);
    }
    return _hex(buffer);
  }

  /// 常量时间比较，避免用 `==` 比校验值时泄漏前缀信息。
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var index = 0; index < a.length; index++) {
      diff |= a[index] ^ b[index];
    }
    return diff == 0;
  }

  static final List<int> _roomIdSalt = utf8.encode('tune-share-room-v1');

  static String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
