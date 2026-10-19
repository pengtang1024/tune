// ignore_for_file: constant_identifier_names

import 'dart:io' show Platform;

/// 平台常量配置
/// 包含各平台相关的常量定义
class PlatformConstants {
  // 平台检测 - 使用运行时检测
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isFuchsia => Platform.isFuchsia;

  /// 检查是否为桌面平台
  static bool get isDesktop {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否为移动平台
  static bool get isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// 桌面端窗口默认宽度：紧凑双栏播放器
  static const double desktopWindowWidth = 900;

  /// 桌面端窗口默认高度
  static const double desktopWindowHeight = 600;

  /// 桌面端窗口最小宽度：保证左播放器 + 右列表仍可用
  static const double desktopWindowMinWidth = 760;

  /// 桌面端窗口最小高度
  static const double desktopWindowMinHeight = 520;
}
