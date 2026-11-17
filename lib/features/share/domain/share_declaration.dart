import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'share_ai_disclosure.dart';
import 'share_item.dart';
import 'share_provenance.dart';

/// 用户给一条内容做的声明。
///
/// 客户端证明不了「这真是 AI 生成的」，也证明不了「这真是你自己录的」。
/// 能做的只有两件事：把声明固定成一条可核对的记录（哈希进条目里），
/// 以及让没声明的条目根本进不了房间。这条边界写在
/// `docs/ai-music-sharing.md` §1。
class ShareDeclaration {
  const ShareDeclaration({
    required this.provenance,
    required this.declaredAt,
    this.note,
  });

  /// 声明里允许附一句说明，比如「本地模型生成，提示词见备注」。
  final ShareProvenance provenance;
  final DateTime declaredAt;
  final String? note;

  /// 声明正文：改动任何一个字段都会算出不同的哈希。
  String canonicalText(String contentId) {
    return 'tune-share-declaration-v1|${provenance.wireName}|$contentId|'
        '${declaredAt.toUtc().toIso8601String()}|${note ?? ''}';
  }

  /// 声明的证据哈希，进 `ShareItem.evidenceHashes`。
  String evidenceHash(String contentId) {
    return sha256.convert(utf8.encode(canonicalText(contentId))).toString();
  }

  /// 按声明拼一条可以发出去的条目。
  ///
  /// 声明为「生成」时自动带齐 AI 标识（提供者填本机，内容编号由内容派生），
  /// 这是合规底线：没有标识的生成物不该进房间。
  ShareItem toItem({
    required String contentId,
    required String name,
    required int sizeBytes,
    String? artist,
    int? durationMs,
  }) {
    final generated = provenance.isGenerated;
    return ShareItem(
      contentId: contentId,
      name: name,
      artist: artist,
      sizeBytes: sizeBytes,
      durationMs: durationMs,
      provenance: provenance,
      createdAt: declaredAt.toUtc(),
      evidenceHashes: <String>{evidenceHash(contentId)},
      aiDisclosure: generated
          ? ShareAiDisclosure(
              isSynthetic: true,
              providerName: '本机生成',
              providerCode: 'tune-local',
              contentNumber: 'tune-${contentId.substring(0, 12)}',
            )
          : ShareAiDisclosure.none,
    );
  }
}
