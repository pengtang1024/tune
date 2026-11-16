// ignore_for_file: constant_identifier_names

import 'dart:io' show Platform;

/// 平台常量配置
/// 包含各平台相关的常量定义
class PlatformConstants {
  // 平台检测 - 使用运行时检测
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isFuchsia => Platform.isFuchsia;

  /// 检查是否为桌面平台
  static bool get isDesktop {
    try {
      return Platform.isWindows || Platform.isLinux;
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
  static const double desktopWindowWidth = 1120;

  /// 桌面端窗口默认高度
  static const double desktopWindowHeight = 760;

  /// 桌面端窗口最小宽度：落在手机档位里（窄于
  /// `LayoutBreakpoints.phoneMaxWidth` 的 600），所以拉到最窄得到的是手机
  /// 布局——底部导航 + 单行播放条 + 整页内容，而不是把桌面三栏压扁。
  /// 布局层从这里取值，不在别处另写一份数字。
  static const double desktopWindowMinWidth = 560;

  /// 桌面端窗口最小高度
  static const double desktopWindowMinHeight = 520;

  /// mini 形态的窗口宽度：只留播放条
  static const double desktopMiniWindowWidth = 360;

  /// mini 形态的窗口高度：与底栏同高，另加底部一条 2px 的进度线。
  ///
  /// 迷你窗口没有原生标题栏，这 88 全是播放条本身；旧值 132 是给标题栏
  /// 留的余量，真用了标题栏，条就只能缩在窗口中间。
  static const double desktopMiniWindowHeight = 88;
}
