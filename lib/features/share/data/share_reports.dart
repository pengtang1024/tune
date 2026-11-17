import 'dart:convert';

import 'share_store.dart';

/// 一条举报记录：谁发的、什么内容、为什么举报。
///
/// 举报要留痕：内容是本地删掉了，但「什么时候因为什么下架过」得能查。
class ShareReport {
  const ShareReport({
    required this.contentId,
    required this.name,
    required this.reason,
    required this.createdAt,
    this.fromPeerId = '',
  });

  final String contentId;
  final String name;
  final String reason;
  final DateTime createdAt;
  final String fromPeerId;

  Map<String, Object?> toJson() => <String, Object?>{
    'contentId': contentId,
    'name': name,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'fromPeerId': fromPeerId,
  };

  static ShareReport? tryFromJson(Map<String, Object?> json) {
    final contentId = json['contentId'];
    final name = json['name'];
    final reason = json['reason'];
    final createdAt = json['createdAt'];
    final fromPeerId = json['fromPeerId'];
    if (contentId is! String || name is! String || reason is! String) {
      return null;
    }
    final parsed = createdAt is String ? DateTime.tryParse(createdAt) : null;
    if (parsed == null) {
      return null;
    }
    return ShareReport(
      contentId: contentId,
      name: name,
      reason: reason,
      createdAt: parsed,
      fromPeerId: fromPeerId is String ? fromPeerId : '',
    );
  }

  /// 迁移旧 JSON 时用得到的那份形状。
  static List<ShareReport> listFromJson(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return const <ShareReport>[];
    }
    if (decoded is! Map) {
      return const <ShareReport>[];
    }
    final raw = decoded['reports'];
    if (raw is! List) {
      return const <ShareReport>[];
    }
    final reports = <ShareReport>[];
    for (final item in raw) {
      if (item is Map) {
        final report = tryFromJson(item.cast<String, Object?>());
        if (report != null) {
          reports.add(report);
        }
      }
    }
    return reports;
  }
}

/// 举报台账：事实在 `share_events`（`kind = 'reported'`）。
class ShareReports {
  ShareReports(this.store);

  final ShareStore store;

  Future<List<ShareReport>> load() async => store.reports();

  Future<void> add(ShareReport report) async => store.addReport(report);
}
