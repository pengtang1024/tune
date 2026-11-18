import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:tune/features/share/domain/share_admission.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_session_state.dart';

import '../../../data/services/mesh/mesh_crypto.dart';
import '../../../data/services/mesh/mesh_discovery.dart';
import '../../../data/services/mesh/mesh_identity.dart';
import '../../../data/services/mesh/mesh_messages.dart';
import '../../../data/services/mesh/mesh_peer.dart';
import '../../../data/services/mesh/mesh_protocol.dart';
import '../../../data/services/mesh/mesh_reachability.dart';
import '../../../data/services/mesh/mesh_room.dart';
import '../../../data/services/mesh/mesh_transfer.dart';
import '../../../data/services/mesh/room_invite.dart';
import '../data/share_copy.dart';
import '../data/share_inbox.dart';
import '../data/share_label_writer.dart';
import '../data/share_blocklist.dart';
import '../data/share_ledger.dart';
import '../data/share_reports.dart';

/// 查重钩子：给一段文件和它的声明，返回「已经是某张商业录音」的标识。
///
/// 接 AcoustID；没接时传 null，闸门里那一格就是「没查」，不是「查过没问题」。
typedef ShareRecordingLookup =
    Future<String?> Function(ShareItem item, File file);

/// 一个分享房间的运行时：连接、清单、传输、准入都在这里串起来。
///
/// 应用层，不碰 UI：页面只读 [states]、调 [addLocalItem] / [request]。
class ShareSession {
  ShareSession._({
    required this.identity,
    required this.displayName,
    required this.roomKey,
    required RoomInvite invite,
    required MeshRoom room,
    required MeshDiscovery discovery,
    required this.inbox,
    required this.isHost,
    this.ledger,
    this.reports,
    this.blocklist,
    this.recordingLookup,
    this.copyBuilder,
    this.labelWriter = const ShareLabelWriter(),
    this.outbox,
    this.publiclyReachable = false,
  })  : _invite = invite,
        _room = room,
        _discovery = discovery;

  final MeshIdentity identity;
  final String displayName;

  /// 房间密钥；只有房里的人有。
  final Uint8List roomKey;

  final ShareInbox inbox;
  final bool isHost;

  /// 本机生成台账；没有台账时闸门只认声明。
  final ShareLedger? ledger;

  /// 举报台账；只留痕，不外发。
  final ShareReports? reports;

  /// 本地黑名单：撤销、举报过的编号不再接收。
  final ShareBlocklist? blocklist;

  /// AcoustID 查重；没接时为 null。
  final ShareRecordingLookup? recordingLookup;

  /// 分享副本的构建器（开头插 AI 提示音）。没装配就不产出副本。
  final ShareCopyBuilder? copyBuilder;

  /// 隐式标识的写入与核验。核验不依赖它写成功——读得出就算。
  final ShareLabelWriter labelWriter;

  /// 副本落盘目录；按源内容编号分子目录，同名源文件不会互相覆盖。
  final Directory? outbox;

  /// 房主自动探测到了可跨网直连的地址（公网 IPv6 或路由器映射）。
  final bool publiclyReachable;

  final RoomInvite _invite;

  /// 这个房间的邀请码（含房间密钥）；房主用它发人，访客用它重连。
  RoomInvite get invite => _invite;

  final MeshRoom _room;
  final MeshDiscovery _discovery;
  final Map<String, MeshPeer> _peers = <String, MeshPeer>{};
  final Map<String, ShareItem> _localItems = <String, ShareItem>{};
  final Map<String, File> _localFiles = <String, File>{};
  final Map<String, ShareRemoteItem> _remote = <String, ShareRemoteItem>{};
  final Map<String, MeshFileReceiver> _receivers = <String, MeshFileReceiver>{};

  /// 派生副本：副本编号 → 落盘位置与它的源编号。撤销时按这张表删文件。
  final Map<String, ({File file, String originContentId})> _derivedCopies =
      <String, ({File file, String originContentId})>{};
  final StreamController<ShareSessionState> _states =
      StreamController<ShareSessionState>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  ShareSessionState _state = ShareSessionState.idle;

  /// 自己开房间：监听、广播信标、生成邀请码。
  static Future<ShareSession> host({
    required MeshIdentity identity,
    required String displayName,
    required ShareInbox inbox,
    ShareLedger? ledger,
    ShareReports? reports,
    ShareBlocklist? blocklist,
    ShareRecordingLookup? recordingLookup,
    ShareCopyBuilder? copyBuilder,
    ShareLabelWriter labelWriter = const ShareLabelWriter(),
    Directory? outbox,
    InternetAddress? address,
    MeshReachability? reachability,
  }) async {
    final invite = RoomInvite.create();
    final room = MeshRoom(
      roomKey: invite.roomKey,
      displayName: displayName,
      identityId: identity.peerId,
    );
    final port = await room.listen(address: address);
    final discovery = MeshDiscovery();
    await discovery.start(
      () => MeshBeacon(
        roomId: invite.roomId,
        port: port,
        name: displayName,
        sentAt: DateTime.now().toUtc(),
      ),
    );
    final reachable = await (reachability ?? MeshReachability()).probe(port: port);
    final session = ShareSession._(
      identity: identity,
      displayName: displayName,
      roomKey: invite.roomKey,
      invite: RoomInvite(
        roomKey: invite.roomKey,
        seeds: reachable.seeds,
      ),
      room: room,
      discovery: discovery,
      inbox: inbox,
      isHost: true,
      publiclyReachable: reachable.hasPublic,
      ledger: ledger,
      reports: reports,
      blocklist: blocklist,
      recordingLookup: recordingLookup,
      copyBuilder: copyBuilder,
      labelWriter: labelWriter,
      outbox: outbox,
    );
    await session._start(invite: session.invite);
    return session;
  }

  /// 用邀请码进别人的房间。
  static Future<ShareSession> join({
    required RoomInvite invite,
    required MeshIdentity identity,
    required String displayName,
    required ShareInbox inbox,
    ShareLedger? ledger,
    ShareReports? reports,
    ShareBlocklist? blocklist,
    ShareRecordingLookup? recordingLookup,
    ShareCopyBuilder? copyBuilder,
    ShareLabelWriter labelWriter = const ShareLabelWriter(),
    Directory? outbox,
  }) async {
    final room = MeshRoom(
      roomKey: invite.roomKey,
      displayName: displayName,
      identityId: identity.peerId,
    );
    await room.listen(address: InternetAddress.anyIPv4);
    final discovery = MeshDiscovery();
    final session = ShareSession._(
      identity: identity,
      displayName: displayName,
      roomKey: invite.roomKey,
      invite: invite,
      room: room,
      discovery: discovery,
      inbox: inbox,
      isHost: false,
      ledger: ledger,
      reports: reports,
      blocklist: blocklist,
      recordingLookup: recordingLookup,
      copyBuilder: copyBuilder,
      labelWriter: labelWriter,
      outbox: outbox,
    );
    await session._start(invite: invite);
    return session;
  }

  Stream<ShareSessionState> get states => _states.stream;

  ShareSessionState get state => _state;

  /// 本机监听的端口。
  int get port => _room.port;

  Future<void> _start({required RoomInvite invite}) async {
    if (_state == ShareSessionState.idle) {
      _state = ShareSessionState.idle.copyWith(
        phase: isHost ? ShareSessionPhase.hosting : ShareSessionPhase.joined,
        roomId: invite.roomId,
        inviteCode: isHost ? invite.encode() : null,
        port: _room.port,
      );
      _emit();
    }
    await discoveryBeacons(invite);
    _subscriptions.add(_room.joined.listen(_onPeer));
    if (!isHost && invite.seeds.isNotEmpty) {
      await _dialSeeds(invite.seeds);
    }
  }

  /// 房主与访客都广播信标，局域网里互相能看见；进房仍靠邀请码。
  Future<void> discoveryBeacons(RoomInvite invite) async {
    if (_discovery.isRunning) {
      return;
    }
    try {
      await _discovery.start(
      () => MeshBeacon(
        roomId: invite.roomId,
        port: _room.port,
        name: displayName,
        sentAt: DateTime.now().toUtc(),
      ),
      );
    } on SocketException {
      // 广播不可用不影响进房：邀请码里带了地址，也能直连。
    }
  }

  /// 邀请码里可能有好几个地址（局域网、公网 IPv6、路由器映射）。
  /// 全部同时拨，谁先通就用谁，剩下的自己关掉。
  Future<void> _dialSeeds(List<String> seeds) async {
    final targets = <({String host, int port})>[
      for (final seed in seeds) ?RoomInvite.parseSeed(seed),
    ];
    if (targets.isEmpty) {
      _fail('邀请码里的地址认不出来');
      return;
    }
    final attempts = <Future<MeshPeer>>[
      for (final target in targets) _connect(target.host, target.port),
    ];
    try {
      final winner = await Future.any(attempts);
      for (final attempt in attempts) {
        unawaited(attempt.then((peer) async {
          if (!identical(peer, winner)) {
            await peer.close();
          }
        }).catchError((Object _) {}));
      }
      await _onPeer(winner);
    } on Object catch (error) {
      _fail('连不上邀请码里的地址：$error');
    }
  }

  Future<MeshPeer> _connect(String host, int port) async {
    final socket =
        await Socket.connect(host, port, timeout: MeshRoom.dialTimeout);
    return MeshPeer.dial(socket, roomKey: roomKey, localHello: _hello());
  }

  /// `MeshRoom.joined` 只报进来的连接，拨出去的这条要自己登记。
  Future<void> _dial(String host, int peerPort) async {
    final socket = await Socket.connect(host, peerPort, timeout: MeshRoom.dialTimeout);
    final peer = await MeshPeer.dial(socket, roomKey: roomKey, localHello: _hello());
    await _onPeer(peer);
  }

  MeshHello _hello() => MeshHello.create(
    roomKey: roomKey,
    displayName: displayName,
    identityId: identity.peerId,
    listenPort: _room.port,
  );

  Future<void> _onPeer(MeshPeer peer) async {
    if (peer.identityId.isEmpty) {
      await peer.close();
      return;
    }
    final known = _peers[peer.identityId];
    if (known != null) {
      // 全互联会撞出两条方向相反的同源连接。留哪条必须两边算得一样，
      // 否则各留一条、互相把对方那条关掉，最后一条都不剩。
      final wantInbound = identity.peerId.compareTo(peer.identityId) > 0;
      final keepExisting = known.isInbound == wantInbound;
      if (keepExisting) {
        await peer.close();
        return;
      }
      await known.close();
      _peers.remove(peer.identityId);
    }
    _peers[peer.identityId] = peer;
    _subscriptions.add(
      Stream<void>.fromFuture(peer.closed).listen((_) => _onPeerGone(peer)),
    );
    _subscriptions.add(peer.frames.listen((frame) => _onFrame(peer, frame)));
    await _sendInventory(peer);
    await _maybeDialBack(peer);
  }

  /// 只处理「关掉的正是当前登记的那条」：全互联撞出来的重复连接被掐掉时，
  /// 不能顺手把留下那条也删了。
  void _onPeerGone(MeshPeer peer) {
    if (!identical(_peers[peer.identityId], peer)) {
      return;
    }
    final peerId = peer.identityId;
    _peers.remove(peerId);
    _remote.removeWhere((_, item) => item.ownerPeerId == peerId);
    _emit();
  }

  /// 对方报了监听端口就把它补进全互联；只让身份号小的一边拨，避免两条。
  Future<void> _maybeDialBack(MeshPeer peer) async {
    if (peer.listenPort <= 0) {
      return;
    }
    if (identity.peerId.compareTo(peer.identityId) >= 0) {
      return;
    }
    if (_peers.containsKey(peer.identityId)) {
      return;
    }
    try {
      await _dial(peer.remoteAddress.address, peer.listenPort);
    } on Object {
      // 拨不回去没关系，星形那条已经通了。
    }
  }

  Future<void> _sendInventory(MeshPeer peer) async {
    final inventory = await MeshInventory.sign(
      identity: identity,
      items: _localItems.values.toList(growable: false),
    );
    peer.sendJson(MeshMessageType.inventory, inventory.toJson());
  }

  void _onFrame(MeshPeer peer, MeshFrame frame) {
    switch (frame.type) {
      case MeshMessageType.inventory:
        unawaited(_onInventory(peer, frame));
      case MeshMessageType.want:
        unawaited(_onWant(peer, frame));
      case MeshMessageType.block:
        unawaited(_onBlock(peer, frame));
      case MeshMessageType.revoke:
        _onRevoke(peer, frame);
      case MeshMessageType.hello:
      case MeshMessageType.ping:
      case MeshMessageType.pong:
        break;
    }
  }

  Future<void> _onInventory(MeshPeer peer, MeshFrame frame) async {
    final Map<String, Object?> json;
    try {
      json = MeshFrameCodec.decodeJson(frame.payload);
    } on MeshProtocolException {
      return;
    }
    final inventory = MeshInventory.tryFromJson(json);
    if (inventory == null) {
      return;
    }
    final verified = await inventory.verify();
    for (final item in inventory.items) {
      _remote[item.contentId] = ShareRemoteItem(
        item: item,
        ownerPeerId: peer.identityId,
        ownerName: peer.displayName,
        manifestVerified: verified,
      );
    }
    _emit();
  }

  Future<void> _onWant(MeshPeer peer, MeshFrame frame) async {
    final Map<String, Object?> json;
    try {
      json = MeshFrameCodec.decodeJson(frame.payload);
    } on MeshProtocolException {
      return;
    }
    final want = MeshWant.tryFromJson(json);
    if (want == null) {
      return;
    }
    final file = _localFiles[want.contentId];
    final item = _localItems[want.contentId];
    if (file == null || item == null) {
      return;
    }
    final reason = await _evaluate(
      item,
      manifestVerified: true,
      receivedContentId: want.contentId,
      file: file,
    );
    if (!reason.isAdmitted) {
      _fail('rejected:${reason.wireName}');
      return;
    }
    await MeshFileSender(
      peer: peer,
      contentId: want.contentId,
      file: file,
    ).serve(want);
  }

  Future<void> _onBlock(MeshPeer peer, MeshFrame frame) async {
    final MeshBlock block;
    try {
      block = MeshBlock.decodePayload(frame.payload);
    } on MeshProtocolException {
      return;
    }
    final receiver = _receivers[block.contentId];
    if (receiver == null) {
      return;
    }
    try {
      await receiver.accept(block);
    } on ArgumentError {
      await receiver.abort();
      _receivers.remove(block.contentId);
      _fail('收到的块与条目对不上');
      return;
    }
    final progress = <String, double>{
      ..._state.inboundProgress,
      block.contentId: receiver.totalBlocks == 0
          ? 1
          : receiver.receivedBytes / receiver.item.sizeBytes,
    };
    _state = _state.copyWith(inboundProgress: progress);
    _emit();
    if (!receiver.isComplete) {
      return;
    }
    final result = await receiver.finish();
    _receivers.remove(block.contentId);
    final entry = _remote[block.contentId];
    final progressAfter = <String, double>{..._state.inboundProgress}
      ..remove(block.contentId);
    if (!result.verified) {
      _state = _state.copyWith(inboundProgress: progressAfter);
      _fail('收到的内容和声明的不一致，已丢弃');
      return;
    }
    // 收端自己再过一遍闸门：不信发送端的「我已经验过了」。
    final reason = await _evaluate(
      receiver.item,
      manifestVerified: entry?.manifestVerified ?? false,
      receivedContentId: receiver.item.contentId,
      file: File(result.path),
    );
    if (!reason.isAdmitted) {
      await File(result.path).delete();
      _state = _state.copyWith(inboundProgress: progressAfter);
      _fail('房间没有收下这条（${reason.wireName}）');
      return;
    }
    final inboxEntry = ShareInboxEntry(
      item: receiver.item,
      path: result.path,
      fromPeerId: entry?.ownerPeerId ?? peer.identityId,
      fromName: entry?.ownerName ?? peer.displayName,
      receivedAt: DateTime.now().toUtc(),
    );
    final entries = [..._state.inbox, inboxEntry];
    await inbox.save(entries);
    _state = _state.copyWith(inbox: entries, inboundProgress: progressAfter);
    _emit();
  }

  /// 闸门的五个输入全部来自本地：清单验签、字节重算、台账、证据、查重占位。
  Future<ShareAdmissionReason> _evaluate(
    ShareItem item, {
    required bool manifestVerified,
    required String receivedContentId,
    File? file,
  }) async {
    final ledgerHit = await (ledger?.has(item.contentId) ?? Future.value(false));
    final blocked = await (blocklist?.has(item.contentId) ?? Future.value(false));
    // 查重只对「手上有文件」的路径有意义：发块前是本机文件，收到后是临时文件。
    final matched = file == null
        ? null
        : await recordingLookup?.call(item, file);
    // 标识核验只对手上有字节、且自称为生成物的条目做：读得出来才算，读不出来不认。
    final labelVerified = item.provenance.isGenerated &&
        file != null &&
        await labelWriter.hasRequiredLabels(file);
    return ShareAdmission.evaluate(
      ShareAdmissionInput(
        item: item,
        manifestVerified: manifestVerified,
        ledgerHit: ledgerHit,
        labelVerified: labelVerified,
        blocked: blocked,
        receivedContentId: receivedContentId,
        // 查重接不上时是 null（「没查」），不是「查过没问题」。
        matchedRecording: matched,
        evidenceVerified: item.evidenceHashes.isNotEmpty,
        roomItemCount: _remote.length,
        roomBytes: _remote.values.fold<int>(0, (sum, entry) => sum + entry.item.sizeBytes),
      ),
    );
  }

  Future<void> _onRevoke(MeshPeer peer, MeshFrame frame) async {
    final Map<String, Object?> json;
    try {
      json = MeshFrameCodec.decodeJson(frame.payload);
    } on MeshProtocolException {
      return;
    }
    final revoke = MeshRevoke.tryFromJson(json);
    if (revoke == null) {
      return;
    }
    _remote.remove(revoke.contentId);
    await blocklist?.add(revoke.contentId);
    await _dropInbox(revoke.contentId);
    _emit();
  }

  /// 作者撤销了，或者本人举报了：本地收件也必须跟着消失。
  Future<void> _dropInbox(String contentId) async {
    final hits = _state.inbox
        .where((entry) => entry.item.contentId == contentId)
        .toList(growable: false);
    if (hits.isEmpty) {
      return;
    }
    for (final entry in hits) {
      try {
        final file = File(entry.path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // 文件已经不在了也算删过，索引还要清。
      }
      await inbox.forget(entry);
    }
    _state = _state.copyWith(
      inbox: _state.inbox
          .where((entry) => entry.item.contentId != contentId)
          .toList(growable: false),
    );
  }

  /// 本机加一条要分享的东西。发布前先过准入闸门。
  ///
  /// 生成物在这里被强制换成「分享副本」：开头加提示音、容器里写四条隐式标识，
  /// 再用副本的最终字节重算内容编号。任何一步没成都拒发，绝不退化成原样外发。
  Future<bool> addLocalItem(ShareItem item, File file) async {
    final publish = item.provenance.isGenerated
        ? await _stampDerivedCopy(item, file)
        : item;
    if (publish == null) {
      return false;
    }
    if (!ShareAdmission.canPublish(publish)) {
      _fail('这条不满足分享条件：要么是本机生成的，要么有可以核对的权利声明');
      return false;
    }
    _localItems[publish.contentId] = publish;
    _localFiles[publish.contentId] = publish == item
        ? file
        : _derivedCopies[publish.contentId]!.file;
    _emit();
    for (final peer in _peers.values) {
      await _sendInventory(peer);
    }
    return true;
  }

  /// 造出带标识的分享副本，并把条目换成副本的事实；失败返回 null 并已 _fail。
  Future<ShareItem?> _stampDerivedCopy(ShareItem item, File file) async {
    final builder = copyBuilder;
    final outboxDirectory = outbox;
    if (builder == null || outboxDirectory == null) {
      // 没装配副本管线（单测与旧配置）：条目原样走闸门，标识完整性仍由 canPublish 拦。
      return item;
    }
    // 按源编号分子目录：不同源的同名文件不会撞，同源重建是幂等覆盖。
    final stage = Directory(
      '${outboxDirectory.path}/${item.contentId.substring(0, 12)}',
    );
    await stage.create(recursive: true);
    final built = await builder.build(file, directory: stage);
    final copy = built.file;
    if (built.outcome != ShareCopyOutcome.built || copy == null) {
      _fail(
        '生成物要先做出带标识的分享副本，这步没成：'
        '${built.message ?? built.outcome.name}',
      );
      return null;
    }
    final stamped = await labelWriter.stamp(
      copy,
      disclosure: item.aiDisclosure,
      originContentId: item.contentId,
    );
    if (stamped.outcome != ShareLabelOutcome.stamped &&
        stamped.outcome != ShareLabelOutcome.alreadyStamped) {
      await _discard(copy);
      _fail('分享副本的 AI 标识没写进去：${stamped.message ?? stamped.outcome.name}');
      return null;
    }
    // 字节已经变了：编号与体积必须按副本最终字节重算，否则收端一定判编号不符。
    final copyId = await MeshCrypto.contentIdOfFile(copy);
    _derivedCopies[copyId] = (file: copy, originContentId: item.contentId);
    return ShareItem(
      contentId: copyId,
      name: _baseName(copy.path),
      artist: item.artist,
      sizeBytes: await copy.length(),
      durationMs: built.durationMs ?? item.durationMs,
      provenance: item.provenance,
      createdAt: item.createdAt,
      evidenceHashes: item.evidenceHashes,
      aiDisclosure: item.aiDisclosure,
    );
  }

  static String _baseName(String path) {
    final separator = path.lastIndexOf(Platform.pathSeparator);
    return separator < 0 ? path : path.substring(separator + 1);
  }

  Future<void> _discard(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // 半成品删不掉也不影响结论：这条已经拒发，登记表里没有它。
    }
  }

  /// 把别人的一条收到收件区。
  Future<void> request(ShareItem item) async {
    final remote = _remote[item.contentId];
    if (remote == null) {
      return;
    }
    if (!remote.manifestVerified) {
      _fail('这条清单没过签名，先不接收');
      return;
    }
    final peer = _peers[remote.ownerPeerId];
    if (peer == null) {
      _fail('分享这条的人已经离开房间');
      return;
    }
    final path = await inbox.pathFor(item.contentId, item.name);
    final receiver = MeshFileReceiver(item: item, destination: path);
    _receivers[item.contentId] = receiver;
    final total = receiver.totalBlocks;
    peer.sendJson(
      MeshMessageType.want,
      MeshWant(contentId: item.contentId, fromBlock: 0, blockCount: total).toJson(),
    );
  }

  /// 状态只在这里成形：什么时候变都只改内部表，发出去的永远是派生结果。
  /// 本人下架：从房间清单里拿掉，并通知房里的人别再传、已传的删掉。
  ///
  /// 只下架分享关系，不动用户磁盘上那份原始文件。
  ///
  /// 和收到别人的撤销、以及自己举报走同一套收口：编号进本机黑名单。否则
  /// 房里还留着这份的人回头又能把它塞回我的收件箱，撤销就成了单向通知。
  Future<void> revoke(String contentId, {String reason = 'revoked'}) async {
    if (_localItems.remove(contentId) == null) {
      return;
    }
    _localFiles.remove(contentId);
    await blocklist?.add(contentId, reason: reason);
    final derived = _derivedCopies.remove(contentId);
    if (derived != null) {
      // 源编号一起进黑名单：只封副本，别人把原始那份再传一遍就又回来了。
      await blocklist?.add(derived.originContentId, reason: reason);
      await _discard(derived.file);
    }
    _room.broadcastJson(
      MeshMessageType.revoke,
      MeshRevoke(contentId: contentId, reason: reason).toJson(),
    );
    _emit();
  }

  /// 举报并下架：本机删掉这条，记一条举报留痕，不外发。
  Future<void> report(ShareInboxEntry entry, {String reason = 'unknown'}) async {
    final store = reports;
    if (store != null) {
      await store.add(
        ShareReport(
          contentId: entry.item.contentId,
          name: entry.item.name,
          reason: reason,
          createdAt: DateTime.now().toUtc(),
          fromPeerId: entry.fromPeerId,
        ),
      );
    }
    // 举报等同于作者撤销：告诉房里别人别再传，也记住这个编号别再收。
    await blocklist?.add(entry.item.contentId);
    _room.broadcastJson(
      MeshMessageType.revoke,
      MeshRevoke(contentId: entry.item.contentId, reason: reason).toJson(),
    );
    _remote.remove(entry.item.contentId);
    await _dropInbox(entry.item.contentId);
    _emit();
  }

  void _emit() {
    _state = _state.copyWith(
      peers: _peers.values
          .map(
            (peer) => SharePeerInfo(
              peerId: peer.identityId,
              displayName: peer.displayName,
              isHost: false,
            ),
          )
          .toList(growable: false),
      localItems: _localItems.values.toList(growable: false),
      remoteItems: _remote.values.toList(growable: false)
        ..sort((left, right) => left.item.contentId.compareTo(right.item.contentId)),
      isPubliclyReachable: publiclyReachable,
    );
    if (!_states.isClosed) {
      _states.add(_state);
    }
  }

  void _fail(String message) {
    _state = _state.copyWith(lastError: message, phase: ShareSessionPhase.joined);
    _emit();
  }

  /// 收件区（含已落盘索引）。
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final peer in _peers.values.toList(growable: false)) {
      await peer.close();
    }
    _peers.clear();
    for (final derived in _derivedCopies.values) {
      await _discard(derived.file);
    }
    _derivedCopies.clear();
    await _room.close();
    await _discovery.dispose();
    _state = _state.copyWith(phase: ShareSessionPhase.closed);
    _emit();
    await _states.close();
  }

}
