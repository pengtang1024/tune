import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 均衡器条形动画组件
/// 显示动态均衡器效果
class EqualizerBarAnimation extends ThemedAnimationBase {
  final int barCount;
  final double width;
  final double height;

  const EqualizerBarAnimation({
    super.key,
    this.barCount = 10,
    this.width = 200.0,
    this.height = 100.0,
  });

  @override
  State<EqualizerBarAnimation> createState() => _EqualizerBarAnimationState();
}

class _EqualizerBarAnimationState
    extends ThemedAnimationStateBase<EqualizerBarAnimation> {
  late List<Animation<double>> _barAnimations;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();

    // 初始化多个动画控制器
    _controllers = List.generate(widget.barCount, (index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 500 + Random().nextInt(1000)),
        vsync: this,
      );
      controller.repeat(reverse: true);
      return controller;
    });

    // 创建条形动画
    _barAnimations = List.generate(widget.barCount, (index) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[index], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _EqualizerBarPainter(_barAnimations, theme),
        );
      },
    );
  }
}

class _EqualizerBarPainter extends CustomPainter {
  final List<Animation<double>> barAnimations;
  final ThemeData theme;

  _EqualizerBarPainter(this.barAnimations, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = barAnimations.length;
    final barWidth = size.width / barCount * 0.8;
    final barSpacing = size.width / barCount * 0.2;
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制每个条形
    for (int i = 0; i < barCount; i++) {
      final barHeight = barAnimations[i].value * size.height;
      final dx = i * (barWidth + barSpacing) + barSpacing / 2;
      final dy = size.height - barHeight;

      // 设置颜色（使用主题色的不同色调）
      final hue = (i * 360 / barCount) % 360;
      paint.color = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();

      // 绘制条形
      canvas.drawRect(Rect.fromLTWH(dx, dy, barWidth, barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerBarPainter oldDelegate) {
    for (int i = 0; i < barAnimations.length; i++) {
      if (barAnimations[i].value != oldDelegate.barAnimations[i].value) {
        return true;
      }
    }
    return false;
  }
}
