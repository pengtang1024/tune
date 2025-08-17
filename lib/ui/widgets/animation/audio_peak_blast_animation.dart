import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class AudioPeakBlastAnimation extends ThemedAnimationBase {
  const AudioPeakBlastAnimation({super.key});

  @override
  State<AudioPeakBlastAnimation> createState() =>
      _AudioPeakBlastAnimationState();
}

class _AudioPeakBlastAnimationState
    extends ThemedAnimationStateBase<AudioPeakBlastAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1000));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _AudioPeakBlastPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _AudioPeakBlastPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _AudioPeakBlastPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制中心圆形
    final baseRadius = 15.0;
    final currentRadius = baseRadius * (1 + progress * 2);

    // 中心圆使用主题主色
    paint.color = theme.colorScheme.primary.withValues(alpha: 1.0 - progress * 0.7);
    canvas.drawCircle(center, baseRadius * (1 - progress), paint);

    // 绘制冲击波
    if (progress > 0) {
      final waveRadius = currentRadius * 0.8;
      paint.strokeWidth = 3.0;
      paint.style = PaintingStyle.stroke;
      paint.color = theme.colorScheme.secondary.withValues(alpha: 0.8 - progress * 0.7);
      canvas.drawCircle(center, waveRadius, paint);

      // 绘制向外扩散的粒子
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final blastRadius = currentRadius * 0.7;
        final x = center.dx + blastRadius * cos(angle);
        final y = center.dy + blastRadius * sin(angle);

        paint.style = PaintingStyle.fill;
        paint.color = theme.colorScheme.tertiary.withValues(alpha: 0.7 - progress);
        canvas.drawCircle(Offset(x, y), 3 * (1 - progress), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
