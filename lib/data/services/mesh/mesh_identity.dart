import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// 本机的分享身份：一对 Ed25519 密钥，用来给清单签名。
///
/// 身份是**稳定的**（不像连接那样一次一个），因为清单签名要在断开重连后
/// 仍然能验。私钥只落本机，公钥随清单一起发出去。
class MeshIdentity {
  MeshIdentity._({
    required KeyPair keyPair,
    required SimplePublicKey publicKey,
    required Uint8List seed,
  })  : _keyPair = keyPair,
        _publicKey = publicKey,
        _seed = seed;

  static final Ed25519 _algorithm = Ed25519();

  final KeyPair _keyPair;
  final SimplePublicKey _publicKey;
  final Uint8List _seed;

  /// 公钥的 base64，随清单一起发给对端。
  String get publicKeyBase64 => base64Encode(_publicKey.bytes);

  /// 稳定身份号：`sha256(公钥)` 前 16 字节的十六进制。
  String get peerId => peerIdOf(publicKeyBase64);

  /// 由公钥推出身份号，验签时用它核对清单里的 peerId 没被换掉。
  static String peerIdOf(String publicKeyBase64) {
    final digest = crypto.sha256.convert(base64Decode(publicKeyBase64));
    return digest.bytes.take(16).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<MeshIdentity> generate() async {
    final keyPair = await _algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final seed = await keyPair.extractPrivateKeyBytes();
    return MeshIdentity._(
      keyPair: keyPair,
      publicKey: publicKey,
      seed: Uint8List.fromList(seed),
    );
  }

  /// 读本机身份；没有就生成一份并存下来。
  static Future<MeshIdentity> loadOrCreate(File file) async {
    if (await file.exists()) {
      final restored = await _restore(await file.readAsString());
      if (restored != null) {
        return restored;
      }
    }
    final identity = await generate();
    await file.parent.create(recursive: true);
    await file.writeAsString(identity._export());
    return identity;
  }

  static Future<MeshIdentity?> _restore(String source) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final seed = decoded['seed'];
    final publicKey = decoded['publicKey'];
    if (seed is! String || publicKey is! String) {
      return null;
    }
    final seedBytes = base64Decode(seed);
    final publicKeyBytes = base64Decode(publicKey);
    if (seedBytes.length != 32 || publicKeyBytes.length != 32) {
      return null;
    }
    final pair = SimpleKeyPairData(
      seedBytes,
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
    return MeshIdentity._(
      keyPair: pair,
      publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      seed: Uint8List.fromList(seedBytes),
    );
  }

  String _export() {
    return jsonEncode(<String, Object?>{
      'v': 1,
      'seed': base64Encode(_seed),
      'publicKey': publicKeyBase64,
    });
  }

  /// 对一段字节签名，返回 base64。
  Future<String> signBytes(List<int> bytes) async {
    final signature = await _algorithm.sign(bytes, keyPair: _keyPair);
    return base64Encode(signature.bytes);
  }

  /// 用对端的公钥验签。
  static Future<bool> verifyBytes(
    List<int> bytes, {
    required String publicKeyBase64,
    required String signatureBase64,
  }) async {
    final List<int> publicKeyBytes;
    final List<int> signatureBytes;
    try {
      publicKeyBytes = base64Decode(publicKeyBase64);
      signatureBytes = base64Decode(signatureBase64);
    } on FormatException {
      return false;
    }
    if (publicKeyBytes.length != 32 || signatureBytes.length != 64) {
      return false;
    }
    return _algorithm.verify(
      bytes,
      signature: Signature(
        signatureBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      ),
    );
  }
}
