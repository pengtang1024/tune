import 'share_item.dart';

/// 分享会话所处阶段。
enum ShareSessionPhase {
  /// 还没开房间，也没进房间。
  idle,

  /// 自己开的房间，正在等别人进来。
  hosting,

  /// 已经连上房间（自己开的房间也算）。
  joined,

  /// 房间已关。
  closed,
}

/// 房间里的一个人。
class SharePeerInfo {
  const SharePeerInfo({
    required this.peerId,
    required this.displayName,
    required this.isHost,
  });

  /// 稳定身份号（[MeshIdentity.peerId]）。
  final String peerId;
  final String displayName;
  final bool isHost;
}

/// 房间里别人在分享的一条。
class ShareRemoteItem {
  const ShareRemoteItem({
    required this.item,
    required this.ownerPeerId,
    required this.ownerName,
    required this.manifestVerified,
  });

  final ShareItem item;
  final String ownerPeerId;
  final String ownerName;

  /// 清单签名是否验过；没验过的条目只能看，不能收。
  final bool manifestVerified;
}

/// 已经收进本地、等用户决定要不要加入音乐库的一条。
class ShareInboxEntry {
  const ShareInboxEntry({
    required this.item,
    required this.path,
    required this.fromPeerId,
    required this.fromName,
    required this.receivedAt,
  });

  final ShareItem item;
  final String path;
  final String fromPeerId;
  final String fromName;
  final DateTime receivedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'item': item.toJson(),
    'path': path,
    'fromPeerId': fromPeerId,
    'fromName': fromName,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };

  static ShareInboxEntry? tryFromJson(Map<String, Object?> json) {
    final item = json['item'];
    final path = json['path'];
    final fromPeerId = json['fromPeerId'];
    final fromName = json['fromName'];
    final receivedAt = json['receivedAt'];
    if (item is! Map || path is! String || fromPeerId is! String) {
      return null;
    }
    if (fromName is! String || receivedAt is! String) {
      return null;
    }
    final parsedItem = ShareItem.tryFromJson(item.cast<String, Object?>());
    final parsedAt = DateTime.tryParse(receivedAt);
    if (parsedItem == null || parsedAt == null) {
      return null;
    }
    return ShareInboxEntry(
      item: parsedItem,
      path: path,
      fromPeerId: fromPeerId,
      fromName: fromName,
      receivedAt: parsedAt.toUtc(),
    );
  }
}

/// 分享页要画的一切。整份是不可变的，会话每次变化换一份新的。
class ShareSessionState {
  const ShareSessionState({
    required this.phase,
    required this.roomId,
    required this.inviteCode,
    required this.port,
    required this.peers,
    required this.remoteItems,
    required this.localItems,
    required this.inboundProgress,
    this.isPubliclyReachable = false,
    required this.inbox,
    this.lastError,
  });

  /// 还没开房间的初始状态。
  static const ShareSessionState idle = ShareSessionState(
    phase: ShareSessionPhase.idle,
    roomId: null,
    inviteCode: null,
    port: 0,
    peers: <SharePeerInfo>[],
    remoteItems: <ShareRemoteItem>[],
    localItems: <ShareItem>[],
    inboundProgress: <String, double>{},
    inbox: <ShareInboxEntry>[],
  );

  final ShareSessionPhase phase;

  /// 房间号（16 位十六进制）；没开房间时为空。
  final String? roomId;

  /// 给别人的邀请码；只有房主有。
  final String? inviteCode;

  /// 本机监听的端口。
  final int port;

  final List<SharePeerInfo> peers;
  final List<ShareRemoteItem> remoteItems;

  /// 本机正在分享的条目。
  final List<ShareItem> localItems;

  /// 正在接收的条目：内容编号 → 0..1 进度。
  final Map<String, double> inboundProgress;

  /// 房主那头自动探测到了可跨网直连的地址（公网 IPv6 或路由器映射）。
  final bool isPubliclyReachable;

  /// 收进本地、等用户决定是否加入音乐库的文件。
  final List<ShareInboxEntry> inbox;

  final String? lastError;

  bool get isActive =>
      phase == ShareSessionPhase.hosting || phase == ShareSessionPhase.joined;

  ShareSessionState copyWith({
    ShareSessionPhase? phase,
    String? roomId,
    String? inviteCode,
    int? port,
    List<SharePeerInfo>? peers,
    List<ShareRemoteItem>? remoteItems,
    List<ShareItem>? localItems,
    Map<String, double>? inboundProgress,
    bool? isPubliclyReachable,
    List<ShareInboxEntry>? inbox,
    String? lastError,
    bool clearError = false,
  }) {
    return ShareSessionState(
      phase: phase ?? this.phase,
      roomId: roomId ?? this.roomId,
      inviteCode: inviteCode ?? this.inviteCode,
      port: port ?? this.port,
      peers: peers ?? this.peers,
      remoteItems: remoteItems ?? this.remoteItems,
      localItems: localItems ?? this.localItems,
      inboundProgress: inboundProgress ?? this.inboundProgress,
      isPubliclyReachable: isPubliclyReachable ?? this.isPubliclyReachable,
      inbox: inbox ?? this.inbox,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
