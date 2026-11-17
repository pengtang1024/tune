import 'share_item.dart';

/// 准入判定的一条理由。名字是稳定的，日志与测试都按它断言。
enum ShareAdmissionReason {
  /// 命中本机生成台账：唯一不需要信任任何人的证据。
  admittedFromLedger('admitted_from_ledger'),

  /// 版权声明加可校验凭证，且没有撞上已知商业录音。
  admittedFromDeclaration('admitted_from_declaration'),

  rejectedMalformedContentId('rejected_malformed_content_id'),
  rejectedBlocked('rejected_blocked'),
  rejectedOversizeItem('rejected_oversize_item'),
  rejectedContentMismatch('rejected_content_mismatch'),
  rejectedManifestUnverified('rejected_manifest_unverified'),
  rejectedKnownRecording('rejected_known_recording'),
  rejectedMissingAiDisclosure('rejected_missing_ai_disclosure'),
  rejectedUnprovenGeneration('rejected_unproven_generation'),
  rejectedMissingEvidence('rejected_missing_evidence'),
  rejectedRoomFull('rejected_room_full'),
  rejectedRoomBytes('rejected_room_bytes');

  const ShareAdmissionReason(this.wireName);

  final String wireName;

  bool get isAdmitted =>
      this == ShareAdmissionReason.admittedFromLedger ||
      this == ShareAdmissionReason.admittedFromDeclaration;
}

/// 一条候选内容进房前能拿到的全部证据。
///
/// 证据由收端自己算（`receivedContentId`）或从可信的本地存储读
/// （`ledgerHit`），不采信对端自述。`matchedRecording` 为 null 表示查重没命中，
/// 不是「没查」——没查的情况不要走这个入口。
class ShareAdmissionInput {
  const ShareAdmissionInput({
    required this.item,
    required this.manifestVerified,
    required this.ledgerHit,
    this.receivedContentId,
    this.matchedRecording,
    this.evidenceVerified = false,
    this.blocked = false,
    this.roomItemCount = 0,
    this.roomBytes = 0,
    this.policy = const ShareAdmissionPolicy(),
  });

  final ShareItem item;
  final bool manifestVerified;
  final bool ledgerHit;

  /// 收到的字节现算出来的内容编号；还没收到字节时为 null。
  final String? receivedContentId;

  /// AcoustID 查重命中的已知商业录音（标题或 id），没命中为 null。
  final String? matchedRecording;

  /// 至少一项凭证哈希已经在本地核对过。
  final bool evidenceVerified;

  /// 本地黑名单里已有：撤销过、举报过的编号不再接收。
  final bool blocked;

  final int roomItemCount;
  final int roomBytes;
  final ShareAdmissionPolicy policy;
}

/// 房间的容量上限。这些数字是合规设计的一部分：房间是交换，不是曲库。
class ShareAdmissionPolicy {
  const ShareAdmissionPolicy({
    this.maxItemBytes = 64 * 1024 * 1024,
    this.maxItemsPerRoom = 500,
    this.maxRoomBytes = 2 * 1024 * 1024 * 1024,
  });

  final int maxItemBytes;
  final int maxItemsPerRoom;
  final int maxRoomBytes;
}

/// 准入闸门：纯规则、无 I/O、无全局状态。
///
/// 顺序是刻意的——先排除「字节都不对」与「清单没验签」，再认最强证据，
/// 然后是查重，最后才看声明。任何一步失败都直接拒绝，不放行。
abstract final class ShareAdmission {
  static ShareAdmissionReason evaluate(ShareAdmissionInput input) {
    final item = input.item;
    if (!ShareItem.isWellFormedContentId(item.contentId)) {
      return ShareAdmissionReason.rejectedMalformedContentId;
    }
    if (item.sizeBytes < 0 || item.sizeBytes > input.policy.maxItemBytes) {
      return ShareAdmissionReason.rejectedOversizeItem;
    }
    if (input.blocked) {
      return ShareAdmissionReason.rejectedBlocked;
    }
    if (input.roomItemCount >= input.policy.maxItemsPerRoom) {
      return ShareAdmissionReason.rejectedRoomFull;
    }
    if (input.roomBytes + item.sizeBytes > input.policy.maxRoomBytes) {
      return ShareAdmissionReason.rejectedRoomBytes;
    }
    final received = input.receivedContentId;
    if (received != null && received != item.contentId) {
      return ShareAdmissionReason.rejectedContentMismatch;
    }
    if (!input.manifestVerified) {
      return ShareAdmissionReason.rejectedManifestUnverified;
    }
    // 查重命中优先于台账：自己声明的「生成物」也可能是把商业曲改名混进来的。
    if (input.matchedRecording != null) {
      return ShareAdmissionReason.rejectedKnownRecording;
    }
    if (input.ledgerHit) {
      return item.provenance.isGenerated && !item.aiDisclosure.isComplete
          ? ShareAdmissionReason.rejectedMissingAiDisclosure
          : ShareAdmissionReason.admittedFromLedger;
    }
    if (item.provenance.isGenerated) {
      return ShareAdmissionReason.rejectedUnprovenGeneration;
    }
    if (item.evidenceHashes.isEmpty || !input.evidenceVerified) {
      return ShareAdmissionReason.rejectedMissingEvidence;
    }
    return ShareAdmissionReason.admittedFromDeclaration;
  }

  /// 生成物必须先有完整标识才许出门（发送侧调用，比收端更早拦一道）。
  static bool canPublish(ShareItem item) {
    if (item.provenance.isGenerated) {
      return item.aiDisclosure.isComplete;
    }
    return item.evidenceHashes.isNotEmpty;
  }
}
