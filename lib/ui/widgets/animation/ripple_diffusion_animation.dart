import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class RippleDiffusionAnimation extends ThemedAnimationBase {
  const RippleDiffusionAnimation({super.key});

  @override
  State<RippleDiffusionAnimation> createState() =>
      _RippleDiffusionAnimationState();
}

class _RippleDiffusionAnimationState
    extends ThemedAnimationStateBase<RippleDiffusionAnimation> {
  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _RipplePainter(controller.value, theme),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _RipplePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制3个同心圆波纹
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress * 3 + i) % 3 / 3;
      final radius = 10 + rippleProgress * 30;
      final opacity = 1.0 - rippleProgress;

      paint.color = theme.colorScheme.primary.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
