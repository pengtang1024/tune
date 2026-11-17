import 'dart:convert';
import 'dart:typed_data';

/// 帧头里的类型字节。数字写进协议，发出去就不能改。
enum MeshMessageType {
  hello(1),
  inventory(2),
  want(3),
  block(4),
  revoke(5),
  ping(6),
  pong(7);

  const MeshMessageType(this.code);

  final int code;

  static MeshMessageType? fromCode(int code) {
    for (final type in values) {
      if (type.code == code) {
        return type;
      }
    }
    return null;
  }
}

/// 一帧：类型 + 载荷。字节流的切分只认长度，不认内容。
class MeshFrame {
  const MeshFrame(this.type, this.payload);

  final MeshMessageType type;
  final Uint8List payload;
}

/// 协议错误。坏帧一律抛错并断开连接，不做「跳过继续」的容错。
class MeshProtocolException implements Exception {
  const MeshProtocolException(this.message);

  final String message;

  @override
  String toString() => 'MeshProtocolException: $message';
}

/// 帧格式：4 字节大端长度（含类型字节）+ 1 字节类型 + 载荷。
abstract final class MeshFrameCodec {
  /// 单帧上限 8 MiB：一块 256 KiB，留足余量也挡住恶意的巨大声明。
  static const int maxFrameBytes = 8 * 1024 * 1024;

  static const int headerBytes = 5;

  static Uint8List encode(MeshMessageType type, List<int> payload) {
    if (payload.length + 1 > maxFrameBytes) {
      throw const MeshProtocolException('frame too large');
    }
    final frame = Uint8List(headerBytes + payload.length);
    final length = payload.length + 1;
    frame[0] = (length >> 24) & 0xff;
    frame[1] = (length >> 16) & 0xff;
    frame[2] = (length >> 8) & 0xff;
    frame[3] = length & 0xff;
    frame[4] = type.code;
    frame.setRange(headerBytes, frame.length, payload);
    return frame;
  }

  /// 控制消息的载荷统一是 UTF-8 的 JSON，块数据是裸字节。
  static Uint8List encodeJson(Map<String, Object?> body) =>
      Uint8List.fromList(utf8.encode(jsonEncode(body)));

  static Map<String, Object?> decodeJson(Uint8List payload) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(payload));
    } on FormatException catch (error) {
      throw MeshProtocolException('bad json payload: ${error.message}');
    }
    if (decoded is! Map) {
      throw const MeshProtocolException('json payload is not an object');
    }
    return decoded.cast<String, Object?>();
  }
}

/// 增量切帧器：TCP 上到的是任意长度的字节块，这里拼回整帧。
class MeshFrameDecoder {
  Uint8List _buffer = Uint8List(0);

  /// 已缓存但还没成帧的字节数，用于判断对端是不是在灌垃圾。
  int get bufferedBytes => _buffer.length;

  /// 喂进一段字节，返回这次能切出来的所有整帧。
  List<MeshFrame> add(List<int> chunk) {
    if (chunk.isEmpty) {
      return const <MeshFrame>[];
    }
    _buffer = Uint8List.fromList(<int>[..._buffer, ...chunk]);
    final frames = <MeshFrame>[];
    var offset = 0;
    while (_buffer.length - offset >= MeshFrameCodec.headerBytes) {
      final length =
          (_buffer[offset] << 24) |
          (_buffer[offset + 1] << 16) |
          (_buffer[offset + 2] << 8) |
          _buffer[offset + 3];
      if (length <= 0 || length > MeshFrameCodec.maxFrameBytes) {
        _buffer = Uint8List(0);
        throw MeshProtocolException('bad frame length $length');
      }
      final frameEnd = offset + 4 + length;
      if (_buffer.length < frameEnd) {
        break;
      }
      final typeCode = _buffer[offset + 4];
      final type = MeshMessageType.fromCode(typeCode);
      if (type == null) {
        _buffer = Uint8List(0);
        throw MeshProtocolException('unknown message type $typeCode');
      }
      final payload = Uint8List.fromList(
        _buffer.sublist(offset + MeshFrameCodec.headerBytes, frameEnd),
      );
      frames.add(MeshFrame(type, payload));
      offset = frameEnd;
    }
    _buffer = offset == 0
        ? _buffer
        : Uint8List.fromList(_buffer.sublist(offset));
    return frames;
  }

  /// 连接重建或出错之后丢弃半帧。
  void reset() {
    _buffer = Uint8List(0);
  }
}
