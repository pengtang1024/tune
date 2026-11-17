import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 局域网里一条「这里有个房间」的广播。
///
/// 只播广播、不播房间内容：谁想进来还得自己用邀请码解出房间密钥。
class MeshBeacon {
  const MeshBeacon({
    required this.roomId,
    required this.port,
    required this.name,
    required this.sentAt,
  });

  /// 信标格式版本；解析时版本不等于它的一律丢弃。
  static const int version = 1;

  /// 房间号（`MeshCrypto.roomIdOf` 的结果），不含房间密钥。
  final String roomId;

  /// 房间监听的端口，对端据此发起 TCP 连接。
  final int port;

  /// 房间名，给发现列表显示用。
  final String name;

  /// 发出时刻，用来判过期；接收端信这个时间会比信自己的钟差安全。
  final DateTime sentAt;

  Uint8List encode() {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'v': version,
          'roomId': roomId,
          'port': port,
          'name': name,
          'sentAt': sentAt.toUtc().millisecondsSinceEpoch,
        }),
      ),
    );
  }

  /// 解析一条信标；字段缺失、版本不符或端口非法都返回 null。
  static MeshBeacon? tryDecode(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > 1024) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    if (decoded['v'] != version) {
      return null;
    }
    final roomId = decoded['roomId'];
    final port = decoded['port'];
    final name = decoded['name'];
    final sentAt = decoded['sentAt'];
    if (roomId is! String || roomId.length != 16) {
      return null;
    }
    if (port is! int || port <= 0 || port > 65535) {
      return null;
    }
    if (name is! String || name.length > 64) {
      return null;
    }
    if (sentAt is! int) {
      return null;
    }
    return MeshBeacon(
      roomId: roomId,
      port: port,
      name: name,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAt, isUtc: true),
    );
  }

  /// 按收到时刻判过期：超过 [ttl] 没再听到就当房间已经不在。
  bool isFresh(DateTime now, {Duration ttl = MeshDiscovery.beaconTtl}) {
    return now.difference(sentAt) <= ttl;
  }
}

/// 把收到的信标按房间号归并，并丢掉过期的。
///
/// 单独拆出来是为了不碰 socket 也能测：网络层只负责收发字节。
class MeshBeaconTracker {
  MeshBeaconTracker({this.ttl = MeshDiscovery.beaconTtl});

  final Duration ttl;
  final Map<String, MeshBeacon> _rooms = <String, MeshBeacon>{};

  /// 记下一条信标，返回当前仍然新鲜的房间列表（按房间号排序）。
  List<MeshBeacon> absorb(MeshBeacon beacon, DateTime now) {
    if (beacon.isFresh(now, ttl: ttl)) {
      _rooms[beacon.roomId] = beacon;
    }
    return sweep(now);
  }

  /// 清掉过期的，返回剩下的。
  List<MeshBeacon> sweep(DateTime now) {
    _rooms.removeWhere((_, beacon) => !beacon.isFresh(now, ttl: ttl));
    final rooms = _rooms.values.toList()
      ..sort((left, right) => left.roomId.compareTo(right.roomId));
    return rooms;
  }

  void clear() => _rooms.clear();
}

/// 局域网发现：UDP 广播信标，2 秒一次，6 秒过期。
///
/// 刻意不做 mDNS：这里只需要「房间里有人」这一条信息，广播够用且没有
/// 额外的原生依赖。
class MeshDiscovery {
  MeshDiscovery({this.port = defaultPort});

  /// 发现用的固定端口；房间的 TCP 端口由信标携带，跟它无关。
  static const int defaultPort = 45871;

  /// 广播间隔。
  static const Duration beaconInterval = Duration(seconds: 2);

  /// 多久没再听到就当房间消失。
  static const Duration beaconTtl = Duration(seconds: 6);

  /// 过期清扫间隔。
  static const Duration sweepInterval = Duration(seconds: 1);

  final int port;
  final MeshBeaconTracker _tracker = MeshBeaconTracker();
  final StreamController<List<MeshBeacon>> _rooms =
      StreamController<List<MeshBeacon>>.broadcast();
  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  Timer? _sweepTimer;

  /// 当前仍新鲜（未过期）的房间列表。每次有变化推一次。
  Stream<List<MeshBeacon>> get rooms => _rooms.stream;

  bool get isRunning => _socket != null;

  /// 开始收发信标。[beacon] 每 [beaconInterval] 取一次，返回 null 表示这一轮不播。
  Future<void> start(MeshBeacon Function() beacon) async {
    if (_socket != null) {
      return;
    }
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    _socket = socket;
    socket.listen(_onEvent);
    _beaconTimer = Timer.periodic(beaconInterval, (_) => _send(beacon()));
    _sweepTimer = Timer.periodic(sweepInterval, (_) => _emit(_tracker.sweep(DateTime.now())));
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _socket?.close();
    _socket = null;
    _tracker.clear();
    if (!_rooms.isClosed) {
      _rooms.add(const <MeshBeacon>[]);
    }
  }

  /// 马上播一次（进房间时用，省得等满 2 秒）。
  void announce(MeshBeacon beacon) => _send(beacon);

  void _send(MeshBeacon? beacon) {
    final socket = _socket;
    if (socket == null || beacon == null) {
      return;
    }
    socket.send(
      beacon.encode(),
      InternetAddress('255.255.255.255'),
      port,
    );
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }
    final beacon = MeshBeacon.tryDecode(datagram.data);
    if (beacon == null) {
      return;
    }
    _emit(_tracker.absorb(beacon, DateTime.now()));
  }

  void _emit(List<MeshBeacon> rooms) {
    if (!_rooms.isClosed) {
      _rooms.add(rooms);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _rooms.close();
  }
}
