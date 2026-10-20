import 'dart:io' show Platform;

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/mpris/mpris_bus.dart';
import 'package:tune/data/services/impl/mpris/mpris_service_io.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';

void main() {
  late _FakeBus bus;
  late MprisServiceImpl service;

  setUp(() {
    bus = _FakeBus();
    service = MprisServiceImpl(bus: bus);
  });

  test('the object answers before the name shows up on the bus', () async {
    if (!Platform.isLinux) return;

    final started = await service.start(_FakeBackend());

    expect(started, isTrue);
    // The desktop looks the player up the moment the name appears, so the
    // object has to be on the bus before the name is taken.
    expect(bus.steps, ['publish', 'claim']);
    expect(bus.claimedName, mprisBusName);
  });

  test('gives the bus back when another player holds the name', () async {
    if (!Platform.isLinux) return;
    bus.holdsTheName = false;

    final started = await service.start(_FakeBackend());

    expect(started, isFalse);
    expect(bus.steps, ['publish', 'claim', 'close']);
  });
}

/// A bus that only remembers what the player asked of it.
class _FakeBus implements MprisBus {
  /// The steps the player took, in the order it took them.
  final List<String> steps = [];

  /// The name the player claimed.
  String? claimedName;

  /// Whether the name is free for the player.
  bool holdsTheName = true;

  @override
  Future<void> publish(DBusObject object) async {
    steps.add('publish');
  }

  @override
  Future<bool> claim(String name) async {
    steps.add('claim');
    claimedName = name;
    return holdsTheName;
  }

  @override
  Future<void> close() async {
    steps.add('close');
  }
}

/// A player that does nothing, the controls are not put to work here.
class _FakeBackend implements MprisBackend {
  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> playPause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seek(Duration offset) async {}

  @override
  Future<void> setPosition(Duration position) async {}

  @override
  Future<void> openUri(Uri uri) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setShuffle(bool shuffle) async {}

  @override
  Future<void> setLoopStatus(MprisLoopStatus status) async {}

  @override
  Future<void> raise() async {}

  @override
  Future<void> quit() async {}
}
