import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 平台检测工具类
/// 
/// 用于检测当前运行的平台环境，包括Web、桌面端和移动端
class PlatformDetector {
  /// 检测是否为Web平台
  static bool get isWeb => kIsWeb;

  /// 检测是否为桌面平台（Windows、macOS、Linux）
  static bool get isDesktop {
    if (kIsWeb) return false;
    return [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(defaultTargetPlatform);
  }

  /// 检测是否为移动平台（Android、iOS）
  static bool get isMobile {
    if (kIsWeb) return false;
    return [
      TargetPlatform.android,
      TargetPlatform.iOS,
    ].contains(defaultTargetPlatform);
  }

  /// 检查是否应该使用移动端布局
  /// 
  /// 当屏幕宽度小于指定阈值时，使用移动端布局
  /// 这适用于Web和桌面端窗口缩小的情况
  static bool shouldUseMobileLayout(BuildContext context, {double threshold = 768}) {
    final width = MediaQuery.of(context).size.width;
    return width < threshold;
  }

  /// 根据屏幕尺寸和平台类型返回相应的列数
  /// 
  /// Web和桌面端根据屏幕宽度动态计算列数
  /// 移动端或小屏幕设备固定显示较少列数
  static int getGridCrossAxisCount(BuildContext context) {
    // 如果是移动端或者屏幕较小，使用移动端布局
    if (isMobile || shouldUseMobileLayout(context)) {
      return 2; // 移动端固定显示2列
    }

    // Web和桌面端根据屏幕宽度动态计算列数
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 6; // 大屏幕显示6列
    } else if (width > 1000) {
      return 5; // 中等屏幕显示5列
    } else if (width > 800) {
      return 4; // 较小屏幕显示4列
    } else {
      return 3; // 默认显示3列
    }
  }

  /// 根据屏幕尺寸和平台类型返回相应的间距
  static double getGridSpacing(BuildContext context) {
    // 如果是移动端或者屏幕较小，使用移动端间距
    if (isMobile || shouldUseMobileLayout(context)) {
      return 12.0; // 移动端使用较小的间距
    } else {
      return 20.0; // Web和桌面端使用更大的间距
    }
  }

  /// 根据屏幕尺寸和平台类型返回相应的宽高比
  static double getCardAspectRatio(BuildContext context) {
    // 如果是移动端或者屏幕较小，使用移动端宽高比
    if (isMobile || shouldUseMobileLayout(context)) {
      return 4 / 5; // 移动端使用4:5的宽高比
    } else {
      return 5 / 6; // Web和桌面端使用5:6的宽高比
    }
  }
}