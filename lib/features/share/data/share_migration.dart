import 'dart:convert';
import 'dart:io';

import '../domain/share_session_state.dart';
import 'share_reports.dart';
import 'share_store.dart';

/// 把 M0/M1 的四个 JSON 快照搬进 `share_*` 表。
///
/// 只在文件还在的时候搬一次：搬完把原文件改成 `.migrated`，下次启动不再读它。
/// 坏文件当作「没有这份」——迁移失败不该让分享页打不开。
Future<void> importLegacyShareJson(ShareStore store, Directory shareDir) async {
  await _importLedger(store, File('${shareDir.path}/ledger.json'));
  await _importBlocked(store, File('${shareDir.path}/blocked.json'));
  await _importReports(store, File('${shareDir.path}/reports.json'));
  await _importInbox(store, File('${shareDir.path}/inbox/index.json'));
}

Future<void> _importLedger(ShareStore store, File file) async {
  final ids = _stringList(await _readOrNull(file), 'contentIds');
  if (ids.isEmpty && !await file.exists()) {
    return;
  }
  for (final id in ids) {
    store.noteGenerated(id);
  }
  await _retire(file);
}

Future<void> _importBlocked(ShareStore store, File file) async {
  final ids = _stringList(await _readOrNull(file), 'contentIds');
  if (ids.isEmpty && !await file.exists()) {
    return;
  }
  for (final id in ids) {
    store.block(id, reason: 'migrated');
  }
  await _retire(file);
}

Future<void> _importReports(ShareStore store, File file) async {
  final body = await _readOrNull(file);
  if (body == null) {
    return;
  }
  for (final report in ShareReport.listFromJson(body)) {
    store.addReport(report);
  }
  await _retire(file);
}

Future<void> _importInbox(ShareStore store, File file) async {
  final body = await _readOrNull(file);
  if (body == null) {
    return;
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return _retire(file);
  }
  if (decoded is List) {
    for (final raw in decoded) {
      if (raw is! Map) {
        continue;
      }
      final entry = ShareInboxEntry.tryFromJson(raw.cast<String, Object?>());
      if (entry == null) {
        continue;
      }
      store.rememberReceived(
        entry.item,
        path: entry.path,
        fromPeerId: entry.fromPeerId,
        fromName: entry.fromName,
        at: entry.receivedAt.millisecondsSinceEpoch,
      );
    }
  }
  await _retire(file);
}

Future<String?> _readOrNull(File file) async {
  try {
    if (!await file.exists()) {
      return null;
    }
    return await file.readAsString();
  } on FileSystemException {
    return null;
  }
}

List<String> _stringList(String? body, String key) {
  if (body == null) {
    return const <String>[];
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return const <String>[];
    }
    final raw = decoded[key];
    return raw is List ? raw.whereType<String>().toList() : const <String>[];
  } on FormatException {
    return const <String>[];
  }
}

/// 搬完就改名，避免下次启动重复导入。
Future<void> _retire(File file) async {
  try {
    if (await file.exists()) {
      await file.rename('${file.path}.migrated');
    }
  } on FileSystemException {
    // 改名失败不影响已经写进库的事实。
  }
}
