import 'package:flutter/material.dart';

/// 主题感知的动画基类
/// 
/// 所有需要响应主题变化的动画组件都应该继承自此类
abstract class ThemedAnimationBase extends StatefulWidget {
  const ThemedAnimationBase({super.key});
}

/// 主题感知的动画状态基类
abstract class ThemedAnimationStateBase<T extends ThemedAnimationBase> extends State<T>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取当前主题
    _theme = Theme.of(context);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当widget更新时重新获取主题
    _theme = Theme.of(context);
  }

  /// 获取当前主题
  ThemeData get theme => _theme;

  /// 获取动画控制器，供子类使用
  AnimationController get controller => _controller;

  /// 初始化动画控制器
  void initAnimationController(Duration duration) {
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );
  }

  /// 重复播放动画
  void repeatAnimation() {
    _controller.repeat();
  }

  /// 反向重复播放动画
  void repeatReverseAnimation() {
    _controller.repeat(reverse: true);
  }

  /// 播放一次动画
  void forwardAnimation() {
    _controller.forward();
  }

  /// 反向播放动画
  void reverseAnimation() {
    _controller.reverse();
  }

  /// 停止动画
  void stopAnimation() {
    _controller.stop();
  }

  /// 重置动画
  void resetAnimation() {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 子类需要实现此方法来构建动画内容
  Widget buildAnimationContent(BuildContext context, ThemeData theme);
  
  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return buildAnimationContent(context, _theme);
  }
}