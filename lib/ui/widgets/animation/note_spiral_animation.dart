import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class NoteSpiralAnimation extends ThemedAnimationBase {
  const NoteSpiralAnimation({super.key});

  @override
  State<NoteSpiralAnimation> createState() => _NoteSpiralAnimationState();
}

class _NoteSpiralAnimationState
    extends ThemedAnimationStateBase<NoteSpiralAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 4));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _SpiralNotePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _SpiralNotePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _SpiralNotePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制3个螺旋上升的音符
    final noteCount = 3;
    for (int i = 0; i < noteCount; i++) {
      // 时间偏移，使音符间隔均匀
      final timeOffset = i / noteCount;
      final currentProgress = (progress + timeOffset) % 1.0;

      // 计算螺旋参数
      final angle = currentProgress * 4 * 2 * pi; // 4圈
      final radius = currentProgress * 30; // 半径逐渐增大
      final height = currentProgress * size.height; // 上升高度

      // 计算音符位置
      final x = center.dx + radius * cos(angle);
      final y = center.dy - height;

      // 使用主题色并根据高度变化调整透明度
      final colorIntensity = 0.5 + 0.5 * currentProgress;
      paint.color = theme.colorScheme.primary.withValues(alpha: colorIntensity);

      // 绘制音符
      canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralNotePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
