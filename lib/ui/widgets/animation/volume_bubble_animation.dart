import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class VolumeBubbleAnimation extends ThemedAnimationBase {
  const VolumeBubbleAnimation({super.key});

  @override
  State<VolumeBubbleAnimation> createState() => _VolumeBubbleAnimationState();
}

class _VolumeBubbleAnimationState extends ThemedAnimationStateBase<VolumeBubbleAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 初始化控制器并启动循环动画
    initAnimationController(const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    repeatAnimation(); // 启动循环动画
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _VolumeBubblePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _VolumeBubblePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _VolumeBubblePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制多个气泡
    final bubbleCount = 8;
    for (int i = 0; i < bubbleCount; i++) {
      // 气泡位置基于时间进度
      final bubbleProgress = (progress * bubbleCount + i) % bubbleCount / bubbleCount;

      // 气泡位置
      final x = 20 + (i % 4) * 15.0;
      final y = size.height - 10 - bubbleProgress * (size.height - 20);

      // 气泡大小和透明度
      final radius = 3 + 5 * sin(bubbleProgress * pi);
      final opacity = (1 - bubbleProgress) * 0.8;

      // 气泡颜色
      paint.color = theme.colorScheme.primary.withValues(alpha:opacity);

      // 绘制气泡
      canvas.drawCircle(Offset(x, y), radius, paint);

      // 绘制高光
      paint.color = theme.colorScheme.onPrimary.withValues(alpha:opacity * 0.5);
      canvas.drawCircle(
        Offset(x - radius/3, y - radius/3),
        radius/3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
