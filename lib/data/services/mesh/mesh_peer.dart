import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'mesh_messages.dart';
import 'mesh_protocol.dart';

/// 一条已经过了握手、可以收发帧的对端连接。
///
/// 握手在构造之后立刻开始：双方各发一条 [MeshHello]，各自用房间密钥验证对方。
/// 验不过就断开；验过了 `ready` 才完成，之后的帧才交给上层。
class MeshPeer {
  MeshPeer._(this._socket, {required this.isInbound})
    : _decoder = MeshFrameDecoder();

  /// 握手允许的最长等待，超时就掐线。
  static const Duration handshakeTimeout = Duration(seconds: 5);

  final Socket _socket;
  final MeshFrameDecoder _decoder;
  final bool isInbound;

  /// 单订阅：事件会缓存到有人监听为止，握手刚完成时到的帧不会丢。
  final StreamController<MeshFrame> _frames = StreamController<MeshFrame>();
  final Completer<void> _ready = Completer<void>();
  final Completer<void> _closed = Completer<void>();

  String _peerId = '';
  String _displayName = '';
  String _identityId = '';
  int _listenPort = 0;
  bool _open = false;
  bool _disposed = false;
  Timer? _handshakeTimer;
  StreamSubscription<Uint8List>? _subscription;

  /// 对端自称的身份，`ready` 完成后才有效。
  String get peerId => _peerId;

  String get displayName => _displayName;

  /// 对端的稳定身份号，可能为空（老版本不发）。
  String get identityId => _identityId;

  /// 对端监听的端口，0 表示对端没报。
  int get listenPort => _listenPort;

  /// 对端地址，用来把它补进全互联。
  InternetAddress get remoteAddress => _socket.remoteAddress;

  /// 握手完成（对方证明正确）。
  Future<void> get ready => _ready.future;

  /// 连接关闭，正常与异常都在这里结束。
  Future<void> get closed => _closed.future;

  /// 握手之后的帧流；握手期到的帧先缓存，完成后补发。
  Stream<MeshFrame> get frames => _frames.stream;

  /// 主动连出去的一条连接：先把自己的 hello 发出去，再等对方证明。
  static Future<MeshPeer> dial(
    Socket socket, {
    required List<int> roomKey,
    required MeshHello localHello,
  }) {
    final peer = MeshPeer._(socket, isInbound: false);
    peer._start(roomKey, localHello);
    return peer.ready.then((_) => peer);
  }

  /// 被动接受的一条连接：先等对方证明，验过了才回自己的 hello。
  static Future<MeshPeer> accept(
    Socket socket, {
    required List<int> roomKey,
    required MeshHello localHello,
  }) {
    final peer = MeshPeer._(socket, isInbound: true);
    peer._start(roomKey, localHello);
    return peer.ready.then((_) => peer);
  }

  void _start(List<int> roomKey, MeshHello localHello) {
    _handshakeTimer = Timer(handshakeTimeout, () {
      _fail('handshake timeout');
    });
    _subscription = _socket.listen(
      (data) => _onData(data, roomKey, localHello),
      onError: (Object error) => _fail('socket error: $error'),
      onDone: () => _fail('socket closed'),
      cancelOnError: true,
    );
    if (!isInbound) {
      _send(localHello);
    }
  }

  void _onData(Uint8List data, List<int> roomKey, MeshHello localHello) {
    if (_disposed) {
      return;
    }
    final List<MeshFrame> frames;
    try {
      frames = _decoder.add(data);
    } on MeshProtocolException catch (error) {
      _fail(error.message);
      return;
    }
    for (final frame in frames) {
      if (_open) {
        _frames.add(frame);
        continue;
      }
      if (frame.type != MeshMessageType.hello) {
        _fail('expected hello, got ${frame.type.name}');
        return;
      }
      final hello = MeshHello.tryFromJson(_decodeJson(frame));
      if (hello == null || !hello.verifyWith(roomKey)) {
        _fail('hello proof rejected');
        return;
      }
      _peerId = hello.peerId;
      _displayName = hello.displayName;
      _identityId = hello.identityId;
      _listenPort = hello.listenPort;
      if (isInbound) {
        _send(localHello);
      }
      _open = true;
      _handshakeTimer?.cancel();
      if (!_ready.isCompleted) {
        _ready.complete();
      }
    }
  }

  /// 发一帧。连接已断时返回 false，不抛异常——上层按帧计数判断更省事。
  bool send(MeshMessageType type, List<int> payload) {
    if (_disposed || !_open) {
      return false;
    }
    _socket.add(MeshFrameCodec.encode(type, payload));
    return true;
  }

  bool sendJson(MeshMessageType type, Map<String, Object?> body) =>
      send(type, MeshFrameCodec.encodeJson(body));

  void _send(MeshHello hello) {
    _socket.add(
      MeshFrameCodec.encode(
        MeshMessageType.hello,
        MeshFrameCodec.encodeJson(hello.toJson()),
      ),
    );
  }

  Map<String, Object?> _decodeJson(MeshFrame frame) {
    try {
      return MeshFrameCodec.decodeJson(frame.payload);
    } on MeshProtocolException catch (error) {
      _fail(error.message);
      return const <String, Object?>{};
    }
  }

  void _fail(String reason) {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _handshakeTimer?.cancel();
    if (!_ready.isCompleted) {
      _ready.completeError(StateError('mesh handshake failed: $reason'));
    }
    if (!_closed.isCompleted) {
      _closed.complete();
    }
    _subscription?.cancel();
    _frames.close();
    _socket.destroy();
  }

  /// 关掉连接。重复调用无害，也不等对端回应：先掐 socket，再收尾。
  Future<void> close() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _handshakeTimer?.cancel();
    _socket.destroy();
    unawaited(_subscription?.cancel());
    if (!_ready.isCompleted) {
      _ready.complete();
    }
    if (!_closed.isCompleted) {
      _closed.complete();
    }
    // 单订阅控制器在没有监听者时 close() 不会完成，这里不等它。
    unawaited(_frames.close());
  }
}
