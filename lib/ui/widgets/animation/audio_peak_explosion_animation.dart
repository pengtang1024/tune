import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class AudioPeakExplosionAnimation extends ThemedAnimationBase {
  const AudioPeakExplosionAnimation({super.key});

  @override
  State<AudioPeakExplosionAnimation> createState() =>
      _AudioPeakExplosionAnimationState();
}

class _AudioPeakExplosionAnimationState
    extends ThemedAnimationStateBase<AudioPeakExplosionAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 500));
    repeatAnimation();

    _animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _ExplosionPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ExplosionPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制12个方向的粒子
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * pi / 12);
      final distance = progress * 30;
      final particleSize = 4.0 * (1 - progress);

      final position = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );

      paint.color = theme.colorScheme.primary.withOpacity(1.0 - progress);
      canvas.drawCircle(position, particleSize, paint);
    }

    // 绘制中心闪光
    paint.color = theme.colorScheme.secondary.withOpacity(1.0 - progress * 2);
    canvas.drawCircle(center, 5 * (1 - progress), paint);
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
