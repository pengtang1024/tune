import 'share_store.dart';

/// 本机生成台账。
///
/// 它记的是「这台机器上确实产出过这条内容」——在没有任何服务端的方案里，
/// 这是唯一不需要信任别人的证据。M0 没有生成器，所以条目由用户在添加文件时
/// 自己声明为「AI 生成」后写入；等本地方案接上生成链路，写入点挪到生成完成那一刻，
/// 台账才真正变成强证据（见 `docs/ai-music-sharing.md` §4）。
///
/// 事实落在 `share_events`（`kind = 'generated'`）：同一条内容既要能「声明为生成」
/// 又要能「分享出去」，条目行只有一行，装不下两件事。
class ShareLedger {
  ShareLedger(this.store);

  final ShareStore store;

  /// 记一条内容。重复记不算错，返回是否真的新增。
  Future<bool> add(String contentId) async {
    if (store.hasGenerated(contentId)) {
      return false;
    }
    store.noteGenerated(contentId);
    return true;
  }

  Future<bool> has(String contentId) async => store.hasGenerated(contentId);
}
