import 'dart:io';

import '../domain/share_session_state.dart';
import 'share_store.dart';

/// 收件目录：收到的东西先落这里，用户点「加入音乐库」才算进库。
///
/// 文件留在磁盘上，索引在 `share_items` 里（`direction = 'received'`）。
/// 「哪些在收件箱里」就是「哪些行没被软删」——不再另存一份 JSON。
class ShareInbox {
  ShareInbox(this.store, this.directory);

  final ShareStore store;
  final Directory directory;

  /// 读收件箱；条目坏掉就跳过，不让一行坏数据挡住整页。
  Future<List<ShareInboxEntry>> load() async => store.receivedEntries();

  /// 收下一条：文件已经在 [ShareInboxEntry.path]，这里只登记事实。
  Future<void> save(List<ShareInboxEntry> entries) async {
    for (final entry in entries) {
      if (store.receivedEntries().any(
        (known) => known.item.contentId == entry.item.contentId,
      )) {
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

  /// 收到的东西落盘用的路径：内容编号 + 原扩展名，重名不会互相覆盖。
  Future<String> pathFor(String contentId, String name) async {
    await directory.create(recursive: true);
    final dot = name.lastIndexOf('.');
    final suffix = dot > 0 && name.length - dot <= 6 ? name.substring(dot) : '';
    return '${directory.path}/${contentId.substring(0, 16)}$suffix';
  }

  /// 从收件箱移除（软删：记录留着，能回答「什么时候下架过」）。
  Future<void> forget(ShareInboxEntry entry) async {
    store.markRemoved(entry.item.contentId, reason: 'forgotten');
  }
}
