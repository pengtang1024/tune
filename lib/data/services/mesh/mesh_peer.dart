import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'mesh_messages.dart';
import 'mesh_protocol.dart';
import 'mesh_session_crypto.dart';

/// 一条已经过了握手、可以收发加密帧的对端连接。
///
/// 握手在构造之后立刻开始：双方各发一条 [MeshHello]，各自用房间密钥验证对方，
/// 证明材料覆盖双方的临时公钥。验不过就断开；验过了用 X25519 + HKDF 派生
/// 两个方向的会话密钥，ready 才完成，之后的帧全部走 ChaCha20-Poly1305，
/// 没有回落明文的路径。
class MeshPeer {
  MeshPeer._(
    this._socket, {
    required this.isInbound,
    required SimpleKeyPair ephemeralKeyPair,
  }) : _decoder = MeshFrameDecoder(),
       _localEphemeral = ephemeralKeyPair;

  /// 握手允许的最长等待，超时就掐线。
  static const Duration handshakeTimeout = Duration(seconds: 5);

  final Socket _socket;
  final MeshFrameDecoder _decoder;
  final bool isInbound;

  /// 本端这条连接的临时 X25519 密钥对，只给这一条连接用。
  final SimpleKeyPair _localEphemeral;

  /// 单订阅：事件会缓存到有人监听为止，握手刚完成时到的帧不会丢。
  final StreamController<MeshFrame> _frames = StreamController<MeshFrame>();
  final Completer<void> _ready = Completer<void>();
  final Completer<void> _closed = Completer<void>();

  /// 握手期收到的密文帧：会话密钥就位后按到达顺序补解。
  final List<MeshFrame> _pending = <MeshFrame>[];

  String _peerId = '';
  String _displayName = '';
  String _identityId = '';
  int _listenPort = 0;
  bool _open = false;
  bool _helloSeen = false;
  bool _disposed = false;
  MeshSessionKeys? _session;
  int _sendCounter = 0;
  int _recvCounter = 0;
  Future<void> _sendQueue = Future<void>.value();
  Future<void> _recvQueue = Future<void>.value();
  Timer? _handshakeTimer;
  StreamSubscription<Uint8List>? _subscription;

  /// 对端自称的身份，ready 完成后才有效。
  String get peerId => _peerId;

  String get displayName => _displayName;

  /// 对端的稳定身份号，可能为空（老版本不发）。
  String get identityId => _identityId;

  /// 对端监听的端口，0 表示对端没报。
  int get listenPort => _listenPort;

  /// 对端地址，用来把它补进全互联。
  InternetAddress get remoteAddress => _socket.remoteAddress;

  /// 握手完成（对方证明正确、会话密钥就位）。
  Future<void> get ready => _ready.future;

  /// 连接关闭，正常与异常都在这里结束。
  Future<void> get closed => _closed.future;

  /// 握手之后的帧流（已解密）；握手期到的帧先缓存，完成后补发。
  Stream<MeshFrame> get frames => _frames.stream;

  /// 主动连出去的一条连接：先把自己的 hello 发出去，再等对方证明。
  static Future<MeshPeer> dial(
    Socket socket, {
    required List<int> roomKey,
    required MeshHello localHello,
    required SimpleKeyPair ephemeralKeyPair,
  }) {
    final peer = MeshPeer._(
      socket,
      isInbound: false,
      ephemeralKeyPair: ephemeralKeyPair,
    );
    peer._start(roomKey, localHello);
    return peer.ready.then((_) => peer);
  }

  /// 被动接受的一条连接：先等对方证明，验过了才回自己的 hello。
  static Future<MeshPeer> accept(
    Socket socket, {
    required List<int> roomKey,
    required MeshHello localHello,
    required SimpleKeyPair ephemeralKeyPair,
  }) {
    final peer = MeshPeer._(
      socket,
      isInbound: true,
      ephemeralKeyPair: ephemeralKeyPair,
    );
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
        _dispatch(frame);
        continue;
      }
      if (frame.type != MeshMessageType.hello) {
        if (!_helloSeen) {
          _fail('expected hello, got ${frame.type.name}');
          return;
        }
        // 对方的 hello 已经验过，密文帧先缓存，等会话密钥就位后按序补解。
        _pending.add(frame);
        continue;
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
      _helloSeen = true;
      unawaited(_deriveSession(localHello, hello));
    }
  }

  /// 从双方临时密钥对派生两个方向的会话密钥，然后才放开加密通道。
  ///
  /// 顺序有讲究：先把 [_session] 放好再置 [_open]——send() 只看开闸标志，
  /// 密钥没就位就开闸会把明文帧发出去；被动方回 hello 要赶在补发密文帧
  /// 之前，让对端尽早拿到派生材料。
  Future<void> _deriveSession(MeshHello localHello, MeshHello remoteHello) async {
    try {
      final outbound = await MeshSessionCrypto.deriveKey(
        localKeyPair: _localEphemeral,
        remotePubHex: remoteHello.ephemeralPubKey,
        outbound: true,
      );
      final inbound = await MeshSessionCrypto.deriveKey(
        localKeyPair: _localEphemeral,
        remotePubHex: remoteHello.ephemeralPubKey,
        outbound: false,
      );
      _session = MeshSessionKeys(outbound: outbound, inbound: inbound);
      if (_disposed) {
        return;
      }
      if (isInbound) {
        _send(localHello);
      }
      _open = true;
      _handshakeTimer?.cancel();
      if (!_ready.isCompleted) {
        _ready.complete();
      }
      final pending = List<MeshFrame>.of(_pending);
      _pending.clear();
      for (final frame in pending) {
        _dispatch(frame);
      }
    } on Object catch (error) {
      _fail('session key derivation failed: $error');
    }
  }

  /// 解密一帧并交给上层。计数器按到达顺序取号，重放或插帧会在 MAC 上现形。
  void _dispatch(MeshFrame frame) {
    final counter = _recvCounter++;
    _recvQueue = _recvQueue.then((_) async {
      final session = _session;
      if (_disposed || session == null) {
        return;
      }
      try {
        final plain = await MeshSessionCrypto.decrypt(
          key: session.inbound,
          counter: counter,
          frameType: frame.type.code,
          sealed: frame.payload,
        );
        if (!_disposed) {
          _frames.add(MeshFrame(frame.type, plain));
        }
      } on Object catch (error) {
        _fail('frame decrypt failed: $error');
      }
    });
  }

  /// 发一帧（加密后上线）。连接已断时返回 false，不抛异常——上层按帧计数判断更省事。
  bool send(MeshMessageType type, List<int> payload) {
    if (_disposed || !_open) {
      return false;
    }
    // 取号与拷贝都在同步段完成：同一连接上的帧号严格按调用顺序递增。
    final counter = _sendCounter++;
    final session = _session!;
    final bytes = Uint8List.fromList(payload);
    _sendQueue = _sendQueue.then((_) async {
      if (_disposed) {
        return;
      }
      try {
        final sealed = await MeshSessionCrypto.encrypt(
          key: session.outbound,
          counter: counter,
          frameType: type.code,
          payload: bytes,
        );
        _socket.add(MeshFrameCodec.encode(type, sealed));
      } on Object catch (error) {
        _fail('frame encryption failed: $error');
      }
    });
    return true;
  }

  bool sendJson(MeshMessageType type, Map<String, Object?> body) =>
      send(type, MeshFrameCodec.encodeJson(body));

  void _send(MeshHello hello) {
    // hello 是明文：里面的临时公钥本来就是公开的，房间证明绑死了它。
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