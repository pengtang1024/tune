import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'mesh_messages.dart';
import 'mesh_peer.dart';
import 'mesh_protocol.dart';
import 'mesh_session_crypto.dart';

/// 房间打不开 / 拒绝入房时抛的错。
class MeshRoomException implements Exception {
  const MeshRoomException(this.message);

  final String message;

  @override
  String toString() => 'MeshRoomException: $message';
}

/// 一个局域网房间：监听、连出去、登记成员。
///
/// 只做全互联，不做中继：任何人关掉客户端，ta 手上的内容就断了。
class MeshRoom {
  MeshRoom({
    required this.roomKey,
    required this.displayName,
    this.identityId = '',
    this.maxPeers = defaultMaxPeers,
  });

  /// 默认 8 人，硬上限 16。人多不等于好用，反而更难说清谁传给了谁。
  static const int defaultMaxPeers = 8;
  static const int hardMaxPeers = 16;

  /// 单条连接的空闲上限：聊天室没人说话不代表可以无限挂着。
  static const Duration dialTimeout = Duration(seconds: 8);

  final List<int> roomKey;
  final String displayName;

  /// 本机稳定身份号，随 hello 发给对端，用来把星形补成全互联。
  final String identityId;

  final int maxPeers;

  final Map<String, MeshPeer> _peers = <String, MeshPeer>{};
  final StreamController<MeshPeer> _joined =
      StreamController<MeshPeer>.broadcast();
  final StreamController<MeshPeer> _left =
      StreamController<MeshPeer>.broadcast();

  ServerSocket? _server;
  bool _closed = false;

  /// 监听端口；还没 listen 时是 0。
  int get port => _server?.port ?? 0;

  bool get isListening => _server != null;

  List<MeshPeer> get peers => List<MeshPeer>.unmodifiable(_peers.values);

  Stream<MeshPeer> get joined => _joined.stream;

  Stream<MeshPeer> get left => _left.stream;

  /// 绑定端口并开始接客。端口传 0 时由系统挑一个。
  Future<int> listen({
    InternetAddress? address,
    int port = 0,
    int backlog = 8,
  }) async {
    if (_closed) {
      throw const MeshRoomException('room closed');
    }
    // 双栈：同一个端口既接 IPv4 也接 IPv6，跨网走 IPv6 时不用另开一条。
    // 平台不支持 IPv6 时退回只听 IPv4。
    ServerSocket server;
    if (address != null) {
      server = await ServerSocket.bind(address, port, backlog: backlog);
    } else {
      try {
        server = await ServerSocket.bind(
          InternetAddress.anyIPv6,
          port,
          backlog: backlog,
          v6Only: false,
        );
      } on SocketException {
        server = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
          backlog: backlog,
        );
      }
    }
    _server = server;
    server.listen(_onConnection, onError: (Object error) {
      // 单条 accept 失败不该带走整个房间。
      return;
    });
    return server.port;
  }

  /// 连到种子 peer。房间满了、握手不过都抛 [MeshRoomException]。
  Future<MeshPeer> dial(
    String host,
    int port, {
    Duration timeout = dialTimeout,
  }) async {
    if (_closed) {
      throw const MeshRoomException('room closed');
    }
    _ensureCapacity();
    final Socket socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
    } on SocketException catch (error) {
      throw MeshRoomException('connect failed: ${error.message}');
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    try {
      final hand = await _newHandshake();
      final peer = await MeshPeer.dial(
        socket,
        roomKey: roomKey,
        localHello: hand.hello,
        ephemeralKeyPair: hand.ephemeral,
      );
      _register(peer);
      return peer;
    } on Object catch (error) {
      socket.destroy();
      throw MeshRoomException('handshake failed: $error');
    }
  }

  /// 广播一帧给所有成员，返回真正发出去的人数。
  int broadcast(MeshMessageType type, List<int> payload) {
    var sent = 0;
    for (final peer in _peers.values) {
      if (peer.send(type, payload)) {
        sent++;
      }
    }
    return sent;
  }

  int broadcastJson(MeshMessageType type, Map<String, Object?> body) {
    var sent = 0;
    for (final peer in _peers.values) {
      if (peer.sendJson(type, body)) {
        sent++;
      }
    }
    return sent;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final peer in _peers.values.toList(growable: false)) {
      await peer.close();
    }
    _peers.clear();
    await _server?.close();
    _server = null;
    await _joined.close();
    await _left.close();
  }

  void _onConnection(Socket socket) {
    if (_closed) {
      socket.destroy();
      return;
    }
    if (_peers.length >= maxPeers) {
      socket.destroy();
      return;
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    unawaited(_accept(socket));
  }

  Future<void> _accept(Socket socket) async {
    try {
      final hand = await _newHandshake();
      final peer = await MeshPeer.accept(
        socket,
        roomKey: roomKey,
        localHello: hand.hello,
        ephemeralKeyPair: hand.ephemeral,
      );
      _register(peer);
    } on Object {
      // 没通过证明的连接直接丢掉，不记日志刷屏。
      socket.destroy();
    }
  }

  void _register(MeshPeer peer) {
    if (_closed || _peers.containsKey(peer.peerId)) {
      unawaited(peer.close());
      return;
    }
    if (_peers.length >= maxPeers) {
      unawaited(peer.close());
      return;
    }
    _peers[peer.peerId] = peer;
    unawaited(
      peer.closed.then((_) {
        if (_peers.remove(peer.peerId) != null && !_left.isClosed) {
          _left.add(peer);
        }
      }),
    );
    if (!_joined.isClosed) {
      _joined.add(peer);
    }
  }

  void _ensureCapacity() {
    if (_peers.length >= maxPeers) {
      throw const MeshRoomException('room is full');
    }
  }

  /// 每条连接都用新的 peerId、nonce 与临时密钥对，复用等于把重放窗口留着。
  Future<({MeshHello hello, SimpleKeyPair ephemeral})> _newHandshake() async {
    final ephemeral = await MeshSessionCrypto.newKeyPair();
    final hello = MeshHello.create(
      roomKey: roomKey,
      displayName: displayName,
      identityId: identityId,
      listenPort: port,
      ephemeralPubHex: await MeshSessionCrypto.pubKeyHex(ephemeral),
    );
    return (hello: hello, ephemeral: ephemeral);
  }
}
