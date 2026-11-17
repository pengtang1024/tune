import 'dart:convert';
import 'dart:typed_data';

import 'mesh_crypto.dart';

/// 跨网邀请码：房间密钥 + 几个「可能连得上房主」的地址。
///
/// 地址由房主那头自动探测（局域网 / 公网 IPv6 / 路由器映射），访客逐个试，
/// 谁先通就用谁。刻意不带「找房间」的服务器——邀请码是唯一发放入口，
/// 我们不当索引方，也不做中继（`docs/ai-music-sharing.md` §5.6）。
class RoomInvite {
  const RoomInvite({required this.roomKey, this.seeds = const <String>[]});

  static const String prefix = 'tune-share2:';

  /// 旧版只带一个地址，仍然认，免得升级后旧邀请码全废。
  static const String legacyPrefix = 'tune-share1:';

  /// 邀请码再长就不像人传的东西了，也顺手挡住塞垃圾。
  static const int maxLength = 600;

  /// 32 字节房间密钥。
  final Uint8List roomKey;

  /// `host:port` 列表，按「越可能通」排；可能为空（只在局域网靠广播）。
  final List<String> seeds;

  /// 第一个地址：老代码与「只想看一个」的地方用。
  String? get seed => seeds.isEmpty ? null : seeds.first;

  String get roomId => MeshCrypto.roomIdOf(roomKey);

  /// 新建房间：随机密钥，可选若干种子地址。
  static RoomInvite create({List<String> seeds = const <String>[]}) {
    final key = Uint8List(MeshCrypto.roomKeyBytes);
    final random = MeshCrypto.randomHex(MeshCrypto.roomKeyBytes);
    for (var index = 0; index < MeshCrypto.roomKeyBytes; index++) {
      key[index] = int.parse(random.substring(index * 2, index * 2 + 2), radix: 16);
    }
    return RoomInvite(roomKey: key, seeds: seeds);
  }

  String encode() {
    final key = base64Url.encode(roomKey).replaceAll('=', '');
    if (seeds.isEmpty) {
      return '$prefix$key';
    }
    final payload = base64Url.encode(utf8.encode(seeds.join('\n'))).replaceAll('=', '');
    return '$prefix$key:$payload';
  }

  /// 认不出的一律返回 null：宁可让用户重贴，也不要带着半个密钥进房。
  static RoomInvite? tryParse(String text) {
    final trimmed = text.trim();
    if (trimmed.length > maxLength) {
      return null;
    }
    final String body;
    final bool legacy;
    if (trimmed.startsWith(prefix)) {
      body = trimmed.substring(prefix.length);
      legacy = false;
    } else if (trimmed.startsWith(legacyPrefix)) {
      body = trimmed.substring(legacyPrefix.length);
      legacy = true;
    } else {
      return null;
    }

    final parts = body.split(':');
    if (parts.isEmpty || parts.length > 2) {
      return null;
    }
    final Uint8List key;
    try {
      key = base64Url.decode(_pad(parts[0]));
    } on FormatException {
      return null;
    }
    if (key.length != MeshCrypto.roomKeyBytes) {
      return null;
    }
    if (parts.length == 1) {
      return RoomInvite(roomKey: key);
    }

    final String decoded;
    try {
      decoded = utf8.decode(base64Url.decode(_pad(parts[1])));
    } on FormatException {
      return null;
    }
    final seeds = legacy ? <String>[decoded] : decoded.split('\n');
    if (seeds.any((value) => !isWellFormedSeed(value))) {
      return null;
    }
    return RoomInvite(
      roomKey: key,
      seeds: List<String>.unmodifiable(seeds.where((value) => value.isNotEmpty)),
    );
  }

  /// 种子地址必须是 `host:port`，端口在 1–65535。
  ///
  /// 主机可以是域名、IPv4，或方括号包起来的 IPv6（`[2001:db8::1]:45871`）。
  static bool isWellFormedSeed(String value) {
    final separator = value.lastIndexOf(':');
    if (separator <= 0 || separator == value.length - 1) {
      return false;
    }
    final host = value.substring(0, separator);
    final port = int.tryParse(value.substring(separator + 1));
    if (host.isEmpty || port == null || port <= 0 || port > 65535) {
      return false;
    }
    if (host.contains(' ') || host.contains('/') || host.contains('\n')) {
      return false;
    }
    if (host.startsWith('[')) {
      return host.endsWith(']') && host.length > 2;
    }
    return !host.contains('[') && !host.contains(']');
  }

  /// 把主机与端口拼成种子地址；IPv6 要加方括号，否则分不清哪一段是端口。
  static String formatSeed(String host, int port) {
    return host.contains(':') ? '[$host]:$port' : '$host:$port';
  }

  /// 拆开种子地址；认不出返回 null（与 [isWellFormedSeed] 同一套判据）。
  static ({String host, int port})? parseSeed(String value) {
    if (!isWellFormedSeed(value)) {
      return null;
    }
    final separator = value.lastIndexOf(':');
    var host = value.substring(0, separator);
    final port = int.parse(value.substring(separator + 1));
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    return (host: host, port: port);
  }

  static String _pad(String value) {
    final remainder = value.length % 4;
    return remainder == 0 ? value : value + '=' * (4 - remainder);
  }
}
