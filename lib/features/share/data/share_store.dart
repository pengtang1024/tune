import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../domain/share_ai_disclosure.dart';
import '../domain/share_item.dart';
import '../domain/share_provenance.dart';
import '../domain/share_session_state.dart';
import 'share_reports.dart';

/// 分享的元数据表：三张（房间、条目、事件）。
///
/// 为什么不继续用 JSON 快照：收件箱、生成台账、举报、黑名单这四份数据都要
/// 「写一条不丢别的」，四个文件各自读改写就得自己造一套锁；而 `library.db`
/// 已经开着 WAL 与 `busy_timeout`，同一份库上的写入由它排队。
///
/// 行里的方向（`direction`）是这三张表能装下四类事实的原因：
/// `shared` 我要分享的、`received` 收到的、`generated` 本机生成台账。
/// `removed_at` 表示撤销/举报后软删——记录还要留着回答「什么时候下架过」。
class ShareStore {
  ShareStore._(this._db) {
    _createTables();
  }

  /// 打开（或创建）分享表所在的库。
  factory ShareStore.open(File file) {
    file.parent.createSync(recursive: true);
    final db = sqlite3.open(file.path);
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = NORMAL');
    db.execute('PRAGMA busy_timeout = 5000');
    return ShareStore._(db);
  }

  /// 测试用：只在内存里，不落盘。
  factory ShareStore.inMemory() => ShareStore._(sqlite3.openInMemory());

  final Database _db;

  void dispose() => _db.close();

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS share_rooms (
        room_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        room_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        closed_at INTEGER
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS share_items (
        content_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artist TEXT,
        duration_ms INTEGER,
        size_bytes INTEGER NOT NULL,
        provenance TEXT NOT NULL,
        evidence_hashes TEXT NOT NULL,
        ai_disclosure TEXT NOT NULL,
        direction TEXT NOT NULL,
        owner_peer TEXT,
        room_id TEXT,
        inbox_path TEXT,
        from_name TEXT,
        created_at INTEGER NOT NULL,
        received_at INTEGER,
        removed_at INTEGER,
        removed_reason TEXT
      )
    ''');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_share_items_direction '
        'ON share_items (direction, removed_at)');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS share_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id TEXT,
        kind TEXT NOT NULL,
        reason TEXT,
        peer_id TEXT,
        at INTEGER NOT NULL
      )
    ''');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_share_events_content '
        'ON share_events (content_id, at)');
  }

  // ---- 房间 ----------------------------------------------------------------

  void recordRoom({
    required String roomId,
    required String name,
    required String roomKeyHex,
  }) {
    _db.execute(
      'INSERT INTO share_rooms (room_id, name, room_key, created_at) '
      'VALUES (?, ?, ?, ?) '
      'ON CONFLICT(room_id) DO UPDATE SET '
      'name = excluded.name, room_key = excluded.room_key, closed_at = NULL',
      [roomId, name, roomKeyHex, DateTime.now().millisecondsSinceEpoch],
    );
  }

  void closeRoom(String roomId) {
    _db.execute(
      'UPDATE share_rooms SET closed_at = ? WHERE room_id = ? AND closed_at IS NULL',
      [DateTime.now().millisecondsSinceEpoch, roomId],
    );
  }

  // ---- 条目 ----------------------------------------------------------------

  /// 我要分享的一条。同一条重复登记只更新事实，不新增行。
  void rememberShared(ShareItem item, {String roomId = ''}) {
    _upsertItem(item, direction: 'shared', roomId: roomId);
    logEvent('shared', contentId: item.contentId);
  }

  /// 收到的一条：记下它落在哪、从哪来，收件箱就是按这些行读出来的。
  void rememberReceived(
    ShareItem item, {
    required String path,
    required String fromPeerId,
    required String fromName,
    int? at,
  }) {
    _upsertItem(
      item,
      direction: 'received',
      ownerPeer: fromPeerId,
      inboxPath: path,
      receivedAt: at ?? DateTime.now().millisecondsSinceEpoch,
      receivedFrom: fromName,
    );
    logEvent('received', contentId: item.contentId, peerId: fromPeerId);
  }

  void _upsertItem(
    ShareItem item, {
    required String direction,
    String roomId = '',
    String? ownerPeer,
    String? inboxPath,
    int? receivedAt,
    String? receivedFrom,
  }) {
    _db.execute(
      'INSERT INTO share_items (content_id, name, artist, duration_ms, size_bytes, '
      'provenance, evidence_hashes, ai_disclosure, direction, owner_peer, room_id, '
      'inbox_path, from_name, created_at, received_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(content_id) DO UPDATE SET '
      'name = excluded.name, artist = excluded.artist, '
      'duration_ms = excluded.duration_ms, size_bytes = excluded.size_bytes, '
      'provenance = excluded.provenance, evidence_hashes = excluded.evidence_hashes, '
      'ai_disclosure = excluded.ai_disclosure, direction = excluded.direction, '
      'owner_peer = COALESCE(excluded.owner_peer, share_items.owner_peer), '
      'room_id = CASE WHEN excluded.room_id = \'\' THEN share_items.room_id '
      'ELSE excluded.room_id END, '
      'inbox_path = COALESCE(excluded.inbox_path, share_items.inbox_path), '
      'from_name = COALESCE(excluded.from_name, share_items.from_name), '
      'received_at = COALESCE(excluded.received_at, share_items.received_at)',
      [
        item.contentId,
        item.name,
        item.artist,
        item.durationMs,
        item.sizeBytes,
        item.provenance.wireName,
        jsonEncode(item.evidenceHashes.toList()..sort()),
        jsonEncode(item.aiDisclosure.toJson()),
        direction,
        ownerPeer,
        roomId,
        inboxPath,
        receivedFrom,
        item.createdAt.millisecondsSinceEpoch,
        receivedAt,
      ],
    );
  }

  bool isShared(String contentId) => _db.select(
        'SELECT 1 FROM share_items WHERE content_id = ? '
        'AND direction = ? AND removed_at IS NULL',
        [contentId, 'shared'],
      ).isNotEmpty;

  /// 生成台账：本机声明这是生成物的事实。
  ///
  /// 记在事件里而不是条目上：同一条内容既可能「我声明是生成物」又可能「我分享
  /// 出去」，条目行只有一行，方向字段装不下两件事。
  void noteGenerated(String contentId) {
    logEvent('generated', contentId: contentId);
  }

  bool hasGenerated(String contentId) => _db.select(
        'SELECT 1 FROM share_events WHERE kind = ? AND content_id = ?',
        ['generated', contentId],
      ).isNotEmpty;

  /// 撤销/举报：软删。记录留着，回答「什么时候下架过」。
  void markRemoved(String contentId, {required String reason}) {
    _db.execute(
      'UPDATE share_items SET removed_at = ?, removed_reason = ? '
      'WHERE content_id = ?',
      [DateTime.now().millisecondsSinceEpoch, reason, contentId],
    );
  }

  /// 收件箱：收到的东西按时间倒序。
  List<ShareInboxEntry> receivedEntries() {
    final rows = _db.select(
      'SELECT * FROM share_items WHERE direction = ? AND removed_at IS NULL '
      'ORDER BY received_at DESC',
      ['received'],
    );
    final entries = <ShareInboxEntry>[];
    for (final row in rows) {
      final entry = _entryOf(row);
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  ShareInboxEntry? _entryOf(Row row) {
    final item = _itemOf(row);
    final path = row['inbox_path'];
    if (item == null || path is! String) {
      return null;
    }
    final receivedAt = row['received_at'];
    final fromPeer = row['owner_peer'];
    return ShareInboxEntry(
      item: item,
      path: path,
      fromPeerId: fromPeer is String ? fromPeer : '',
      fromName: row['from_name'] as String? ?? '',
      receivedAt: receivedAt is int
          ? DateTime.fromMillisecondsSinceEpoch(receivedAt)
          : item.createdAt,
    );
  }

  ShareItem? _itemOf(Row row) {
    final provenance = ShareProvenance.parse(row['provenance'] as String? ?? '');
    if (provenance == null) {
      return null;
    }
    final hashes = _decodeList(row['evidence_hashes']);
    final disclosure = _decodeMap(row['ai_disclosure']);
    return ShareItem(
      contentId: row['content_id'] as String,
      name: row['name'] as String? ?? '',
      artist: row['artist'] as String?,
      sizeBytes: row['size_bytes'] as int? ?? 0,
      durationMs: row['duration_ms'] as int?,
      provenance: provenance,
      evidenceHashes: hashes.toSet(),
      aiDisclosure: ShareAiDisclosure.fromJson(disclosure),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int? ?? 0,
      ),
    );
  }

  List<String> _decodeList(Object? raw) {
    if (raw is! String) {
      return const <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.whereType<String>().toList() : const <String>[];
    } on FormatException {
      return const <String>[];
    }
  }

  Map<String, Object?> _decodeMap(Object? raw) {
    if (raw is! String) {
      return const <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.cast<String, Object?>()
          : const <String, Object?>{};
    } on FormatException {
      return const <String, Object?>{};
    }
  }

  // ---- 举报与黑名单 --------------------------------------------------------

  void addReport(ShareReport report) {
    logEvent(
      'reported',
      contentId: report.contentId,
      reason: report.reason,
      peerId: report.fromPeerId,
    );
  }

  List<ShareReport> reports() {
    final rows = _db.select(
      'SELECT * FROM share_events WHERE kind = ? ORDER BY at DESC',
      ['reported'],
    );
    final reports = <ShareReport>[];
    for (final row in rows) {
      final contentId = row['content_id'];
      if (contentId is! String || contentId.isEmpty) {
        continue;
      }
      final name = _nameOf(contentId);
      reports.add(
        ShareReport(
          contentId: contentId,
          name: name,
          reason: row['reason'] as String? ?? 'unknown',
          createdAt: DateTime.fromMillisecondsSinceEpoch(row['at'] as int? ?? 0),
          fromPeerId: row['peer_id'] as String? ?? '',
        ),
      );
    }
    return reports;
  }

  String _nameOf(String contentId) {
    final rows = _db.select(
      'SELECT name FROM share_items WHERE content_id = ?',
      [contentId],
    );
    final name = rows.isEmpty ? null : rows.first['name'];
    return name is String ? name : '';
  }

  void block(String contentId, {String reason = 'reported'}) {
    logEvent('blocked', contentId: contentId, reason: reason);
  }

  bool isBlocked(String contentId) => _db.select(
        'SELECT 1 FROM share_events WHERE kind = ? AND content_id = ?',
        ['blocked', contentId],
      ).isNotEmpty;

  // ---- 事件 ----------------------------------------------------------------

  void logEvent(
    String kind, {
    String? contentId,
    String? reason,
    String? peerId,
  }) {
    _db.execute(
      'INSERT INTO share_events (content_id, kind, reason, peer_id, at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        contentId,
        kind,
        reason,
        peerId,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  /// `events` 目前只给测试与排障用，界面还没有「历史」这一段。
  List<({String kind, String? contentId, DateTime at})> events(
    String contentId,
  ) {
    final rows = _db.select(
      'SELECT kind, content_id, at FROM share_events WHERE content_id = ? '
      'ORDER BY at ASC',
      [contentId],
    );
    return [
      for (final row in rows)
        (
          kind: row['kind'] as String,
          contentId: row['content_id'] as String?,
          at: DateTime.fromMillisecondsSinceEpoch(row['at'] as int? ?? 0),
        ),
    ];
  }
}
