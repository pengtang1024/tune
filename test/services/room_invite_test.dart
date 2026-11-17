import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/room_invite.dart';

void main() {
  test('种子地址认宿主名、IPv4 和方括号 IPv6', () {
    expect(RoomInvite.isWellFormedSeed('192.168.1.5:45871'), isTrue);
    expect(RoomInvite.isWellFormedSeed('mytunnel.example.com:45871'), isTrue);
    expect(RoomInvite.isWellFormedSeed('[2001:db8::1]:45871'), isTrue);
  });

  test('不像 host:port 的一律不认', () {
    for (final value in <String>[
      '',
      'example.com',
      'example.com:',
      ':45871',
      'example.com:0',
      'example.com:70000',
      'exa mple.com:45871',
      'https://example.com:45871',
      '[2001:db8::1:45871',
      '2001:db8::1]:45871',
    ]) {
      expect(RoomInvite.isWellFormedSeed(value), isFalse, reason: value);
    }
  });

  test('IPv6 拼地址要加方括号，拆回来还是原样', () {
    expect(RoomInvite.formatSeed('2001:db8::1', 45871), '[2001:db8::1]:45871');
    expect(RoomInvite.formatSeed('192.168.1.5', 45871), '192.168.1.5:45871');
    final target = RoomInvite.parseSeed('[2001:db8::1]:45871');
    expect(target?.host, '2001:db8::1');
    expect(target?.port, 45871);
  });

  test('拆不出的地址返回 null', () {
    expect(RoomInvite.parseSeed('example.com'), isNull);
    expect(RoomInvite.parseSeed('[2001:db8::1]:0'), isNull);
  });

  test('邀请码带 IPv6 种子能原样往返', () {
    final invite = RoomInvite.create(seeds: <String>['[2001:db8::1]:45871']);
    final parsed = RoomInvite.tryParse(invite.encode());
    expect(parsed?.seeds.first, '[2001:db8::1]:45871');
    expect(parsed?.roomId, invite.roomId);
  });
}
