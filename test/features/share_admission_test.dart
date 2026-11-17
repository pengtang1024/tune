import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/domain/share_admission.dart';
import 'package:tune/features/share/domain/share_ai_disclosure.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';

const String _cid = '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';

const ShareAiDisclosure _completeDisclosure = ShareAiDisclosure(
  isSynthetic: true,
  providerName: 'Tune 本地生成',
  contentNumber: 'gen-20261116-0001',
);

ShareItem _item({
  String contentId = _cid,
  int sizeBytes = 4096,
  ShareProvenance provenance = ShareProvenance.ownRecording,
  Set<String> evidenceHashes = const <String>{'sha256:contract'},
  ShareAiDisclosure aiDisclosure = ShareAiDisclosure.none,
}) {
  return ShareItem(
    contentId: contentId,
    name: '夜航',
    sizeBytes: sizeBytes,
    provenance: provenance,
    evidenceHashes: evidenceHashes,
    aiDisclosure: aiDisclosure,
    createdAt: DateTime.utc(2026, 11, 16),
  );
}

ShareAdmissionReason _evaluate({
  ShareItem? item,
  bool manifestVerified = true,
  bool ledgerHit = false,
  String? receivedContentId,
  String? matchedRecording,
  bool evidenceVerified = true,
  bool blocked = false,
  int roomItemCount = 0,
  int roomBytes = 0,
  ShareAdmissionPolicy policy = const ShareAdmissionPolicy(),
}) {
  return ShareAdmission.evaluate(
    ShareAdmissionInput(
      item: item ?? _item(),
      manifestVerified: manifestVerified,
      ledgerHit: ledgerHit,
      receivedContentId: receivedContentId,
      matchedRecording: matchedRecording,
      evidenceVerified: evidenceVerified,
      blocked: blocked,
      roomItemCount: roomItemCount,
      roomBytes: roomBytes,
      policy: policy,
    ),
  );
}

void main() {
  group('本地黑名单', () {
    test('撤销或举报过的编号直接拒绝，连台账也不认', () {
      final reason = _evaluate(
        item: _item(
          provenance: ShareProvenance.generated,
          aiDisclosure: _completeDisclosure,
          evidenceHashes: const <String>{},
        ),
        ledgerHit: true,
        blocked: true,
      );
      expect(reason, ShareAdmissionReason.rejectedBlocked);
      expect(reason.isAdmitted, isFalse);
    });
  });

  group('生成台账是最强证据', () {
    test('台账命中且标识完整 → 放行', () {
      final reason = _evaluate(
        item: _item(
          provenance: ShareProvenance.generated,
          aiDisclosure: _completeDisclosure,
          evidenceHashes: const <String>{},
        ),
        ledgerHit: true,
      );
      expect(reason, ShareAdmissionReason.admittedFromLedger);
      expect(reason.isAdmitted, isTrue);
    });

    test('台账命中但标识不完整 → 拒绝', () {
      final reason = _evaluate(
        item: _item(
          provenance: ShareProvenance.generated,
          aiDisclosure: const ShareAiDisclosure(isSynthetic: true),
        ),
        ledgerHit: true,
      );
      expect(reason, ShareAdmissionReason.rejectedMissingAiDisclosure);
      expect(reason.isAdmitted, isFalse);
    });

    test('生成物没进过本机台账 → 拒绝，不认对端自述', () {
      expect(
        _evaluate(
          item: _item(
            provenance: ShareProvenance.generated,
            aiDisclosure: _completeDisclosure,
          ),
        ),
        ShareAdmissionReason.rejectedUnprovenGeneration,
      );
    });
  });

  group('字节与清单的可校验性', () {
    test('收到字节算出的编号不符 → 拒绝', () {
      expect(
        _evaluate(receivedContentId: 'f' * 64),
        ShareAdmissionReason.rejectedContentMismatch,
      );
    });

    test('编号相符时继续往前走', () {
      expect(
        _evaluate(receivedContentId: _cid),
        ShareAdmissionReason.admittedFromDeclaration,
      );
    });

    test('清单没验签 → 拒绝，哪怕证据齐全', () {
      expect(
        _evaluate(manifestVerified: false),
        ShareAdmissionReason.rejectedManifestUnverified,
      );
    });

    test('坏编号（长度或字符不对）→ 拒绝', () {
      expect(
        _evaluate(item: _item(contentId: 'A' * 64)),
        ShareAdmissionReason.rejectedMalformedContentId,
      );
      expect(
        _evaluate(item: _item(contentId: 'abc')),
        ShareAdmissionReason.rejectedMalformedContentId,
      );
    });
  });

  group('查重与声明', () {
    test('台账命中但撞上已知商业录音 → 仍然拒绝', () {
      expect(
        _evaluate(
          item: _item(
            provenance: ShareProvenance.generated,
            aiDisclosure: _completeDisclosure,
            evidenceHashes: const <String>{},
          ),
          ledgerHit: true,
          matchedRecording: '某首商业歌',
        ),
        ShareAdmissionReason.rejectedKnownRecording,
      );
    });

    test('撞上已知商业录音 → 拒绝，声明的权利再大也不行', () {
      expect(
        _evaluate(matchedRecording: '某首商业歌'),
        ShareAdmissionReason.rejectedKnownRecording,
      );
    });

    test('自己录音 + 证据已核验 → 放行', () {
      expect(
        _evaluate(item: _item(provenance: ShareProvenance.ownRecording)),
        ShareAdmissionReason.admittedFromDeclaration,
      );
    });

    test('自己有授权但没有可校验证据 → 拒绝', () {
      expect(
        _evaluate(item: _item(evidenceHashes: const <String>{})),
        ShareAdmissionReason.rejectedMissingEvidence,
      );
      expect(
        _evaluate(evidenceVerified: false),
        ShareAdmissionReason.rejectedMissingEvidence,
      );
    });
  });

  group('房间预算', () {
    test('单条超上限 → 拒绝', () {
      expect(
        _evaluate(item: _item(sizeBytes: 65 * 1024 * 1024)),
        ShareAdmissionReason.rejectedOversizeItem,
      );
    });

    test('房间条目已满 → 拒绝', () {
      expect(
        _evaluate(roomItemCount: 500),
        ShareAdmissionReason.rejectedRoomFull,
      );
    });

    test('房间字节超预算 → 拒绝', () {
      expect(
        _evaluate(roomBytes: 2 * 1024 * 1024 * 1024 - 1),
        ShareAdmissionReason.rejectedRoomBytes,
      );
    });
  });

  group('发送侧的出门检查', () {
    test('生成物标识不完整不许发', () {
      expect(
        ShareAdmission.canPublish(
          _item(provenance: ShareProvenance.generated),
        ),
        isFalse,
      );
      expect(
        ShareAdmission.canPublish(
          _item(
            provenance: ShareProvenance.generated,
            aiDisclosure: _completeDisclosure,
          ),
        ),
        isTrue,
      );
    });

    test('非生成物要有至少一项凭证', () {
      expect(
        ShareAdmission.canPublish(_item(evidenceHashes: const <String>{})),
        isFalse,
      );
      expect(
        ShareAdmission.canPublish(
          _item(provenance: ShareProvenance.licensed),
        ),
        isTrue,
      );
    });
  });

  group('条目事实的反序列化', () {
    test('往返保住字段', () {
      final item = _item(
        provenance: ShareProvenance.generated,
        aiDisclosure: _completeDisclosure,
        sizeBytes: 2048,
      );
      final restored = ShareItem.tryFromJson(item.toJson());
      expect(restored, isNotNull);
      expect(restored!.name, item.name);
      expect(restored.provenance, ShareProvenance.generated);
      expect(restored.aiDisclosure.isComplete, isTrue);
      expect(restored.sizeBytes, 2048);
    });

    test('缺字段或认不出缘起 → null', () {
      final json = _item().toJson();
      expect(ShareItem.tryFromJson(<String, Object?>{}), isNull);
      final badProvenance = <String, Object?>{...json, 'provenance': 'stolen'};
      expect(ShareItem.tryFromJson(badProvenance), isNull);
      final badDate = <String, Object?>{...json, 'createdAt': 'yesterday'};
      expect(ShareItem.tryFromJson(badDate), isNull);
    });
  });
}
