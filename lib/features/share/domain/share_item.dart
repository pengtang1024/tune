import 'share_ai_disclosure.dart';
import 'share_provenance.dart';

/// 房间清单里的一条内容。
///
/// 它只是一份「条目事实」：字节在本地生成或已存在，`contentId` 是字节的
/// SHA-256。谁可以拿它、以什么条件拿，由准入闸门判定，不写在条目上。
class ShareItem {
  const ShareItem({
    required this.contentId,
    required this.name,
    required this.sizeBytes,
    required this.provenance,
    required this.createdAt,
    this.artist,
    this.durationMs,
    this.evidenceHashes = const <String>{},
    this.aiDisclosure = ShareAiDisclosure.none,
  });

  /// 字节的 SHA-256，小写十六进制。内容寻址的唯一定位符。
  final String contentId;

  /// 展示名，通常是文件名去掉扩展名后的标题。
  final String name;

  final String? artist;

  /// 字节长度，用来在接收前核对空间与进度。
  final int sizeBytes;

  /// 时长；未知时为 null，读标签失败不该让条目消失。
  final int? durationMs;

  /// 用户可以主张的缘起。
  final ShareProvenance provenance;

  /// 可校验凭证的哈希（合同、生成台账行、录制说明的摘要）。
  final Set<String> evidenceHashes;

  final ShareAiDisclosure aiDisclosure;

  final DateTime createdAt;

  /// 内容编号的十六进制长度固定 64，别的一律视为坏数据。
  static bool isWellFormedContentId(String value) {
    if (value.length != 64) {
      return false;
    }
    for (final unit in value.codeUnits) {
      final isDigit = unit >= 0x30 && unit <= 0x39;
      final isLowerHex = unit >= 0x61 && unit <= 0x66;
      if (!isDigit && !isLowerHex) {
        return false;
      }
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'contentId': contentId,
    'name': name,
    if (artist != null) 'artist': artist,
    'sizeBytes': sizeBytes,
    if (durationMs != null) 'durationMs': durationMs,
    'provenance': provenance.wireName,
    'evidenceHashes': evidenceHashes.toList()..sort(),
    'aiDisclosure': aiDisclosure.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// 缺字段就返回 null：宁可丢掉一条坏条目，也不要让清单半可信。
  static ShareItem? tryFromJson(Map<String, Object?> json) {
    final contentId = json['contentId'];
    final name = json['name'];
    final sizeBytes = json['sizeBytes'];
    final provenance = json['provenance'];
    final createdAt = json['createdAt'];
    if (contentId is! String || name is! String || sizeBytes is! int) {
      return null;
    }
    if (provenance is! String || createdAt is! String) {
      return null;
    }
    final parsedProvenance = ShareProvenance.parse(provenance);
    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedProvenance == null || parsedCreatedAt == null) {
      return null;
    }
    final hashes = json['evidenceHashes'];
    final durationMs = json['durationMs'];
    final disclosure = json['aiDisclosure'];
    return ShareItem(
      contentId: contentId,
      name: name,
      artist: json['artist'] as String?,
      sizeBytes: sizeBytes,
      durationMs: durationMs is int ? durationMs : null,
      provenance: parsedProvenance,
      evidenceHashes: hashes is List
          ? hashes.whereType<String>().toSet()
          : const <String>{},
      aiDisclosure: disclosure is Map
          ? ShareAiDisclosure.fromJson(disclosure.cast<String, Object?>())
          : ShareAiDisclosure.none,
      createdAt: parsedCreatedAt,
    );
  }
}
