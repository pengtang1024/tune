import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class AudioWaveElasticAnimation extends ThemedAnimationBase {
  const AudioWaveElasticAnimation({super.key});

  @override
  State<AudioWaveElasticAnimation> createState() =>
      _AudioWaveElasticAnimationState();
}

class _AudioWaveElasticAnimationState
    extends ThemedAnimationStateBase<AudioWaveElasticAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(
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
          painter: _AudioWaveElasticPainter(_animation.value, theme),
          child: child,
        );
      },
    );
  }
}

class _AudioWaveElasticPainter extends CustomPainter {
  final double animation;
  final ThemeData theme;

  _AudioWaveElasticPainter(this.animation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final pointCount = 50;
    final amplitude = size.height * 0.3;

    // 移动到起始点
    path.moveTo(0, size.height / 2);

    // 绘制波形线
    for (int i = 1; i <= pointCount; i++) {
      final x = i * size.width / pointCount;
      // 波形公式: y = A * sin(B * x + C)
      final y = size.height / 2 +
          amplitude * sin((i / pointCount) * 2 * pi + animation);

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // 绘制波峰高光点
    final highlightPaint = Paint()
      ..color = theme.colorScheme.onPrimary
      ..style = PaintingStyle.fill;

    final highlightX = size.width / 2;
    final highlightY = size.height / 2 +
        amplitude * sin(0.5 * 2 * pi + animation);

    canvas.drawCircle(Offset(highlightX, highlightY), 3, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _AudioWaveElasticPainter oldDelegate) =>
      animation != oldDelegate.animation || theme != oldDelegate.theme;
}
