import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_discovery.dart';

MeshBeacon _beacon({
  String roomId = '0123456789abcdef',
  int port = 45872,
  String name = '客厅',
  DateTime? sentAt,
}) {
  return MeshBeacon(
    roomId: roomId,
    port: port,
    name: name,
    sentAt: sentAt ?? DateTime.utc(2026, 11, 16, 12),
  );
}

void main() {
  test('信标能编码再解回来', () {
    final beacon = _beacon();
    final decoded = MeshBeacon.tryDecode(beacon.encode());
    expect(decoded, isNotNull);
    expect(decoded!.roomId, beacon.roomId);
    expect(decoded.port, beacon.port);
    expect(decoded.name, beacon.name);
    expect(decoded.sentAt, beacon.sentAt);
  });

  test('坏信标一律丢掉，不让它把发现层带崩', () {
    expect(MeshBeacon.tryDecode(const <int>[]), isNull);
    expect(MeshBeacon.tryDecode('不是 json'.codeUnits), isNull);
    expect(MeshBeacon.tryDecode('{"v":99}'.codeUnits), isNull);
    expect(
      MeshBeacon.tryDecode(
        '{"v":1,"roomId":"too-short","port":1,"name":"x","sentAt":0}'.codeUnits,
      ),
      isNull,
    );
    expect(
      MeshBeacon.tryDecode(
        '{"v":1,"roomId":"0123456789abcdef","port":0,"name":"x","sentAt":0}'
            .codeUnits,
      ),
      isNull,
    );
    expect(
      MeshBeacon.tryDecode(
        '{"v":1,"roomId":"0123456789abcdef","port":1,"name":"x","sentAt":"昨天"}'
            .codeUnits,
      ),
      isNull,
    );
    expect(MeshBeacon.tryDecode(List<int>.filled(2048, 32)), isNull);
  });

  test('过期判定按 ttl', () {
    final sentAt = DateTime.utc(2026, 11, 16, 12);
    final beacon = _beacon(sentAt: sentAt);
    expect(beacon.isFresh(sentAt.add(const Duration(seconds: 6))), isTrue);
    expect(beacon.isFresh(sentAt.add(const Duration(seconds: 7))), isFalse);
  });

  test('同一房间以最新信标为准，按房间号排序', () {
    final tracker = MeshBeaconTracker();
    final now = DateTime.utc(2026, 11, 16, 12);
    tracker.absorb(_beacon(roomId: 'bbbbbbbbbbbbbbbb', port: 1, sentAt: now), now);
    tracker.absorb(_beacon(roomId: 'aaaaaaaaaaaaaaaa', port: 2, sentAt: now), now);
    final rooms = tracker.absorb(
      _beacon(roomId: 'bbbbbbbbbbbbbbbb', port: 3, sentAt: now),
      now,
    );
    expect(rooms.map((room) => room.roomId).toList(), [
      'aaaaaaaaaaaaaaaa',
      'bbbbbbbbbbbbbbbb',
    ]);
    expect(rooms.last.port, 3);
  });

  test('超过 ttl 没再听到的房间会被清掉', () {
    final tracker = MeshBeaconTracker();
    final now = DateTime.utc(2026, 11, 16, 12);
    tracker.absorb(_beacon(roomId: 'cccccccccccccccc', sentAt: now), now);
    expect(
      tracker.sweep(now.add(const Duration(seconds: 3))).length,
      1,
    );
    expect(
      tracker.sweep(now.add(const Duration(seconds: 8))),
      isEmpty,
    );
    expect(tracker.sweep(now.add(const Duration(seconds: 9))), isEmpty);
  });

  test('已经过期的信标不会进表', () {
    final tracker = MeshBeaconTracker();
    final now = DateTime.utc(2026, 11, 16, 12);
    final stale = _beacon(sentAt: now.subtract(const Duration(seconds: 30)));
    expect(tracker.absorb(stale, now), isEmpty);
  });
}
