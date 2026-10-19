import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/utils/logger.dart';

/// 窗口管理服务
/// 使用 window_manager 插件统一管理桌面端窗口行为
/// 使用事件驱动（WindowListener）替代轮询，减少 CPU 开销
class WindowManagerService with WindowListener {
  static final WindowManagerService _instance = WindowManagerService._();
  factory WindowManagerService() => _instance;
  WindowManagerService._();

  /// 初始化窗口管理器
  static Future<void> init() async {
    // 仅在桌面端初始化
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;

    try {
      Log.info('开始初始化窗口管理器');
      await windowManager.ensureInitialized();
      Log.info('窗口管理器初始化完成');

      final instance = WindowManagerService();

      // 设置窗口选项
      WindowOptions windowOptions = WindowOptions(
        size: const Size(
          PlatformConstants.desktopWindowWidth,
          PlatformConstants.desktopWindowHeight,
        ),
        minimumSize: const Size(
          PlatformConstants.desktopWindowMinWidth,
          PlatformConstants.desktopWindowMinHeight,
        ),
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      Log.info(
        '窗口选项设置完成，最小尺寸: ${PlatformConstants.desktopWindowMinWidth}x${PlatformConstants.desktopWindowMinHeight}',
      );

      // 注册事件监听（替代 Timer 轮询）
      windowManager.addListener(instance);

      // 等待窗口准备就绪后显示
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        Log.info('窗口显示和聚焦完成');

        // 显式设置最小窗口尺寸
        await WindowManagerService.setMinimumSize();
      });
    } catch (e, stackTrace) {
      Log.error('窗口管理器初始化失败: $e', stackTrace);
    }
  }

  // ========== WindowListener 回调 — 事件驱动 ==========

  @override
  void onWindowResize() {
    // 窗口大小变化由 CompactShell 的 LayoutBuilder 自动响应。
  }

  @override
  void onWindowMaximize() {
    Log.info('窗口已最大化');
  }

  @override
  void onWindowUnmaximize() {
    Log.info('窗口已取消最大化');
  }

  @override
  void onWindowFocus() {
    // 窗口获得焦点
  }

  @override
  void onWindowClose() {
    Log.info('窗口关闭');
  }

  // ========== 公开 API ==========

  /// 设置窗口大小
  static Future<void> setSize(Size size) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setSize(size);
  }

  /// 设置窗口最小尺寸
  static Future<void> setMinimumSize() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    Log.info(
      '设置窗口最小尺寸为: ${PlatformConstants.desktopWindowMinWidth}x${PlatformConstants.desktopWindowMinHeight}',
    );
    await windowManager.setMinimumSize(
      const Size(
        PlatformConstants.desktopWindowMinWidth,
        PlatformConstants.desktopWindowMinHeight,
      ),
    );
  }

  /// 设置窗口最大尺寸
  static Future<void> setMaximumSize(Size size) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setMaximumSize(size);
  }

  /// 设置窗口位置
  static Future<void> setPosition(Offset position) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setPosition(position);
  }

  /// 设置窗口居中
  static Future<void> center() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.center();
  }

  /// 最小化窗口
  static Future<void> minimize() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.minimize();
  }

  /// 最大化窗口
  static Future<void> maximize() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.maximize();
  }

  /// 恢复窗口（取消最大化）
  static Future<void> unmaximize() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.unmaximize();
  }

  /// 检查窗口是否已最大化
  static Future<bool> isMaximized() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return false;
    return await windowManager.isMaximized();
  }

  /// 全屏切换
  static Future<void> setFullScreen(bool isFullScreen) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setFullScreen(isFullScreen);
  }

  /// 设置窗口标题
  static Future<void> setTitle(String title) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setTitle(title);
  }

  /// 设置是否跳过任务栏
  static Future<void> setSkipTaskbar(bool skip) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setSkipTaskbar(skip);
  }

  /// 设置是否始终置顶
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  /// 检查窗口是否可见
  static Future<bool> isVisible() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return false;
    return await windowManager.isVisible();
  }

  /// 显示窗口
  static Future<void> show() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.show();
  }

  /// 隐藏窗口
  static Future<void> hide() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.hide();
  }

  /// 聚焦窗口
  static Future<void> focus() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.focus();
  }

  /// 开始拖拽窗口（用于无边框窗口）
  static Future<void> startDragging() async {
    if (kIsWeb || !(PlatformConstants.isDesktop)) return;
    await windowManager.startDragging();
  }
}
