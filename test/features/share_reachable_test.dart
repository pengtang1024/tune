import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mesh/mesh_identity.dart';
import 'package:tune/data/services/mesh/mesh_reachability.dart';
import 'package:tune/data/services/mesh/room_invite.dart';
import 'package:tune/features/share/application/share_session.dart';
import 'package:tune/features/share/data/share_inbox.dart';
import 'package:tune/features/share/data/share_store.dart';

void main() {
  late Directory workspace;
  late ShareSession session;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-share-reach-');
  });

  tearDown(() async {
    await session.close();
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  Future<ShareSession> hostWith({
    required Future<List<InternetAddress>> Function() local,
    required Future<String?> Function(int port) upnp,
    Future<String?> Function(int port)? natPmp,
  }) async {
    return ShareSession.host(
      identity: await MeshIdentity.generate(),
      displayName: '房主',
      inbox: ShareInbox(ShareStore.inMemory(), Directory('${workspace.path}/inbox')),
      address: InternetAddress.loopbackIPv4,
      reachability: MeshReachability(
        localAddresses: local,
        upnp: upnp,
        natPmp: natPmp ?? (_) async => null,
      ),
    );
  }

  test('开房自己探到公网地址，邀请码把它带上——不需要谁去填', () async {
    session = await hostWith(
      local: () async => [InternetAddress('192.168.1.9')],
      upnp: (_) async => '203.0.113.7',
    );

    expect(session.invite.seeds, contains('203.0.113.7:${session.port}'));
    expect(session.invite.seeds.first, '192.168.1.9:${session.port}');
    expect(session.publiclyReachable, isTrue);
    expect(RoomInvite.isWellFormedSeed(session.invite.seed!), isTrue);

    final parsed = RoomInvite.tryParse(session.invite.encode());
    expect(parsed, isNotNull);
    expect(parsed!.seeds, session.invite.seeds);
    expect(parsed.roomId, session.invite.roomId);
  });

  test('探不到外网入口时只发局域网地址，如实说只能同网', () async {
    session = await hostWith(
      local: () async => [InternetAddress('192.168.1.9')],
      upnp: (_) async => null,
    );

    expect(session.invite.seeds, ['192.168.1.9:${session.port}']);
    expect(session.publiclyReachable, isFalse);
  });
}
