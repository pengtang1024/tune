import 'share_store.dart';

/// 下架黑名单：举报过、或被作者撤销过的内容编号。
///
/// 它不删收件、也不删分享，只是让同一条内容再也进不来（闸门第一步就挡）。
class ShareBlocklist {
  ShareBlocklist(this.store);

  final ShareStore store;

  Future<bool> has(String contentId) async => store.isBlocked(contentId);

  Future<bool> add(String contentId, {String reason = 'reported'}) async {
    if (store.isBlocked(contentId)) {
      return false;
    }
    store.block(contentId, reason: reason);
    return true;
  }
}
