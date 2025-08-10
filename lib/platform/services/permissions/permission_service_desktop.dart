/// 桌面端权限（直接返回允许）
class PermissionServiceDesktop {
  /// 请求存储权限
  Future<bool> requestStoragePermission() async {
    // 桌面端通常不需要特殊权限
    return true;
  }

  /// 请求音频权限
  Future<bool> requestAudioPermission() async {
    // 桌面端通常不需要特殊权限
    return true;
  }
}