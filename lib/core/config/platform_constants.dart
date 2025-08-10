import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// 平台相关常量
class PlatformConstants {
  /// 桌面端窗口默认宽度
  static const double desktopWindowWidth = 1200;

  /// 桌面端窗口默认高度
  static const double desktopWindowHeight = 800;

  /// 是否为移动端
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 是否为桌面端
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 是否为Web端
  static bool get isWeb => kIsWeb;
}