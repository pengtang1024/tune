import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/window_layout_store.dart';
import 'package:tune/utils/logger.dart';

/// 窗口管理服务
/// 使用 window_manager 插件统一管理桌面端窗口行为
/// 使用事件驱动（WindowListener）替代轮询，减少 CPU 开销
class WindowManagerService with WindowListener {
  static final WindowManagerService _instance = WindowManagerService._();
  factory WindowManagerService() => _instance;
  WindowManagerService._();

  /// What to do when the user closes the window.
  ///
  /// The desktop integration decides whether the window is only hidden, so the
  /// service does not decide on its own.
  static Future<void> Function()? _closeHandler;

  /// The document the window writes its size, place and form into.
  WindowLayoutStore? _layout;

  /// The form read at start. A mini or immersive window must not write its
  /// own size over the size the normal form returns to.
  WindowForm _form = WindowForm.normal;

  /// Whether the window is maximized right now.
  bool _maximized = false;

  /// The last geometry of the normal form, kept while the window is
  /// maximized: unmaximizing returns to it instead of to the screen size.
  WindowGeometry? _lastNormal;

  Timer? _persistTimer;

  /// The form asked for while the previous move was still landing.
  ///
  /// A reader who leaves mini before the resize has landed must end in the
  /// size of the form they chose last, not of the one in the middle.
  WindowForm? _pendingForm;

  /// Whether a move is running.
  bool _applying = false;

  /// The size of the mini window, kept here so this layer does not read the
  /// layout breakpoints of the app layer.
  static const Size _miniSize = Size(
    PlatformConstants.desktopMiniWindowWidth,
    PlatformConstants.desktopMiniWindowHeight,
  );

  /// A maximum the window will never reach, used to lift the mini limit.
  ///
  /// The plugin can clear a maximum on Linux but not on Windows, so the normal
  /// and immersive forms ask for a bound larger than any screen instead.
  static const Size _noMaximum = Size(100000, 100000);

  /// 初始化窗口管理器
  static Future<void> init(PersistenceService persistence) async {
    // 仅在桌面端初始化
    if (!PlatformConstants.isDesktop) return;

    try {
      Log.info('开始初始化窗口管理器');
      await windowManager.ensureInitialized();
      Log.info('窗口管理器初始化完成');

      final instance = WindowManagerService();
      final layout = WindowLayoutStore(persistence);
      final saved = layout.readGeometry();
      instance._layout = layout;
      instance._form = layout.readForm();
      instance._lastNormal = saved;
      instance._maximized = saved?.maximized ?? false;

      // Immersive belongs to the now playing page, and a start has no page to
      // return to: a window saved in that form comes back as a normal one.
      if (instance._form == WindowForm.immersive) {
        instance._form = WindowForm.normal;
        await layout.saveForm(WindowForm.normal);
      }

      // 设置窗口选项
      WindowOptions windowOptions = WindowOptions(
        size:
            saved?.size ??
            const Size(
              PlatformConstants.desktopWindowWidth,
              PlatformConstants.desktopWindowHeight,
            ),
        minimumSize: const Size(
          PlatformConstants.desktopWindowMinWidth,
          PlatformConstants.desktopWindowMinHeight,
        ),
        // A window the reader moved comes back where they left it; a first
        // start lands in the middle of the screen.
        center: saved?.position == null,
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
        final position = saved?.position;
        if (position != null) await windowManager.setPosition(position);
        await windowManager.show();
        await windowManager.focus();
        Log.info('窗口显示和聚焦完成');

        // 显式设置最小窗口尺寸
        await WindowManagerService.setMinimumSize();

        // A mini window comes back as the bar it was. A maximized window comes
        // back maximized; its saved size stays the size the reader left, so
        // unmaximizing returns to it.
        if (instance._form == WindowForm.mini) {
          await instance._applyMini();
        } else if (instance._maximized) {
          await windowManager.maximize();
        }
      });
    } catch (e, stackTrace) {
      Log.error('窗口管理器初始化失败: $e', stackTrace);
    }
  }

  // ========== WindowListener 回调 — 事件驱动 ==========

  @override
  void onWindowResize() {
    // The shell rebuilds itself from the width it is given; the window only
    // has to remember the size the reader stopped at.
    _scheduleGeometrySave();
  }

  @override
  void onWindowMove() {
    _scheduleGeometrySave();
  }

  @override
  void onWindowRestore() {
    _scheduleGeometrySave();
  }

  @override
  void onWindowMaximize() {
    _maximized = true;
    _persistGeometry().ignore();
    Log.info('窗口已最大化');
  }

  @override
  void onWindowUnmaximize() {
    _maximized = false;
    // The window may report the old size for another frame, so the write
    // waits for the edge to settle like every other one.
    _scheduleGeometrySave();
    Log.info('窗口已取消最大化');
  }

  @override
  void onWindowFocus() {
    // 窗口获得焦点
  }

  @override
  void onWindowClose() {
    final handler = _closeHandler;
    if (handler == null) {
      Log.info('窗口关闭');
      return;
    }
    handler();
  }

  /// Waits for the reader to let go of the edge of the window.
  ///
  /// A drag sends an event several times a second; a file per event would put
  /// the disk in the middle of the gesture. The last event of the drag is the
  /// one that decides, so only it is written.
  void _scheduleGeometrySave() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 600), _persistGeometry);
  }

  /// Writes the geometry of the normal form.
  ///
  /// A mini or immersive window is not the size the reader chose for the
  /// normal form, so it never writes here.
  Future<void> _persistGeometry() async {
    final layout = _layout;
    if (layout == null || _form != WindowForm.normal) return;
    try {
      if (_maximized) {
        final normal = _lastNormal;
        if (normal == null) return;
        await layout.saveGeometry(normal.copyWith(maximized: true));
        return;
      }
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      final geometry = WindowGeometry(
        width: size.width,
        height: size.height,
        left: position.dx,
        top: position.dy,
      );
      _lastNormal = geometry;
      await layout.saveGeometry(geometry);
    } catch (error, stackTrace) {
      Log.error('保存窗口尺寸失败: $error\n$stackTrace');
    }
  }

  // ========== 形态切换 ==========

  /// Gives the window the size, the chrome and the place on the desktop that
  /// [form] needs.
  ///
  /// The form is state of the app, so the move happens here instead of in the
  /// widget that asked for it. The calls are serialized: a reader who leaves
  /// mini before the last resize has landed ends in the size of the form they
  /// chose last.
  Future<void> applyForm(WindowForm form) async {
    if (!PlatformConstants.isDesktop) return;
    if (_form == form && !_applying && _pendingForm == null) return;
    _pendingForm = form;
    if (_applying) return;
    _applying = true;
    try {
      while (_pendingForm != null) {
        final next = _pendingForm!;
        _pendingForm = null;
        if (next == _form) continue;
        // The size the reader chose belongs to the normal form. It is read
        // before the window leaves it, so returning does not measure the bar.
        if (_form == WindowForm.normal) await _persistGeometry();
        _form = next;
        await _applyWindow(next);
      }
    } catch (error, stackTrace) {
      Log.error('切换窗口形态失败: $error\n$stackTrace');
    } finally {
      _applying = false;
    }
  }

  Future<void> _applyWindow(WindowForm form) async {
    switch (form) {
      case WindowForm.normal:
        await _applyNormal();
      case WindowForm.mini:
        await _applyMini();
      case WindowForm.immersive:
        await _applyImmersive();
    }
  }

  /// Returns the window to the size, the place and the frame of the normal
  /// form.
  Future<void> _applyNormal() async {
    final geometry = _lastNormal ?? _layout?.readGeometry();
    await windowManager.setFullScreen(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setResizable(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setMaximumSize(_noMaximum);
    await windowManager.setMinimumSize(
      const Size(
        PlatformConstants.desktopWindowMinWidth,
        PlatformConstants.desktopWindowMinHeight,
      ),
    );
    if (geometry == null) return;
    await windowManager.setSize(geometry.size);
    final position = geometry.position;
    if (position != null) await windowManager.setPosition(position);
    if (geometry.maximized) {
      await windowManager.maximize();
      _maximized = true;
    }
  }

  /// Shrinks the window to the bar, keeps it above the other windows and out
  /// of the task bar.
  ///
  /// The bar is the whole window, so the frame has to go before the size is
  /// asked for: a frame keeps room for a shadow and a title bar, and a limit
  /// that lands while the frame is still there squeezes the bar into what is
  /// left over. The size is then pinned by equal minimum and maximum hints
  /// rather than by `setResizable(false)`, which GTK reads as "ignore the
  /// resize".
  Future<void> _applyMini() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
      _maximized = false;
    }
    await windowManager.setFullScreen(false);
    // The bar is the window, so the frame goes before anything else. A frame
    // keeps room for its own shadow and its title bar, and a window that still
    // holds them cannot be the size of the bar: GTK ends up squeezing the bar
    // into whatever is left over.
    if (PlatformConstants.isLinux) await windowManager.setAsFrameless();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(true);
    // Shrink first, pin afterwards, so the limit meets a window that is
    // already the size of the bar.
    await windowManager.setSize(_miniSize);
    await _awaitSize(_miniSize);
    await windowManager.setMinimumSize(_miniSize);
    await windowManager.setMaximumSize(_miniSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
  }

  /// Waits until the compositor has actually given the window the size.
  ///
  /// A resize is a request. Resizing on Wayland lands some frames later, and
  /// asking for a limit before it lands measures the old window instead of the
  /// bar.
  Future<void> _awaitSize(Size target) async {
    for (var i = 0; i < 15; i++) {
      final Size current = await windowManager.getSize();
      if (current == target) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Drops the frame and takes the whole screen, which is what the now
  /// playing page asks for.
  Future<void> _applyImmersive() async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setResizable(true);
    await windowManager.setMaximumSize(_noMaximum);
    await windowManager.setMinimumSize(
      const Size(
        PlatformConstants.desktopWindowMinWidth,
        PlatformConstants.desktopWindowMinHeight,
      ),
    );
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setFullScreen(true);
  }

  // ========== 公开 API ==========

  /// Sets what happens when the user closes the window.
  ///
  /// The window stays open until the handler says otherwise, so the handler
  /// has to hide the window or close it for good.
  static void setCloseHandler(Future<void> Function()? handler) {
    _closeHandler = handler;
  }

  /// Keeps the window from closing on its own.
  static Future<void> setPreventClose(bool prevent) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setPreventClose(prevent);
  }

  /// Closes the window for good, which ends the app.
  static Future<void> destroy() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.destroy();
  }

  /// 设置窗口大小
  static Future<void> setSize(Size size) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setSize(size);
  }

  /// 设置窗口最小尺寸
  static Future<void> setMinimumSize() async {
    if (!PlatformConstants.isDesktop) return;
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
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setMaximumSize(size);
  }

  /// 设置窗口位置
  static Future<void> setPosition(Offset position) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setPosition(position);
  }

  /// 设置窗口居中
  static Future<void> center() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.center();
  }

  /// 最小化窗口
  static Future<void> minimize() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.minimize();
  }

  /// 最大化窗口
  static Future<void> maximize() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.maximize();
  }

  /// 恢复窗口（取消最大化）
  static Future<void> unmaximize() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.unmaximize();
  }

  /// 检查窗口是否已最大化
  static Future<bool> isMaximized() async {
    if (!PlatformConstants.isDesktop) return false;
    return await windowManager.isMaximized();
  }

  /// 全屏切换
  static Future<void> setFullScreen(bool isFullScreen) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setFullScreen(isFullScreen);
  }

  /// 设置窗口标题
  static Future<void> setTitle(String title) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setTitle(title);
  }

  /// 设置是否跳过任务栏
  static Future<void> setSkipTaskbar(bool skip) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setSkipTaskbar(skip);
  }

  /// 设置是否始终置顶
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  /// 检查窗口是否可见
  static Future<bool> isVisible() async {
    if (!PlatformConstants.isDesktop) return false;
    return await windowManager.isVisible();
  }

  /// 显示窗口
  static Future<void> show() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.show();
  }

  /// 隐藏窗口
  static Future<void> hide() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.hide();
  }

  /// 聚焦窗口
  static Future<void> focus() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.focus();
  }

  /// 开始拖拽窗口（用于无边框窗口）
  static Future<void> startDragging() async {
    if (!PlatformConstants.isDesktop) return;
    await windowManager.startDragging();
  }
}
