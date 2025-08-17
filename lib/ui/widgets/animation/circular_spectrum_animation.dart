import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class CircularSpectrumAnimation extends ThemedAnimationBase {
  const CircularSpectrumAnimation({super.key});

  @override
  State<CircularSpectrumAnimation> createState() =>
      _CircularSpectrumAnimationState();
}

class _CircularSpectrumAnimationState
    extends ThemedAnimationStateBase<CircularSpectrumAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _CircularSpectrumPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _CircularSpectrumPainter extends CustomPainter {
  final double animationValue;
  final ThemeData theme;

  _CircularSpectrumPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.8),
          theme.colorScheme.secondary.withValues(alpha: 0.5),
          theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // 绘制多个同心圆环
    for (int i = 0; i < 3; i++) {
      final currentRadius = radius * (0.4 + i * 0.2);
      final barCount = 16 + i * 8;
      final barHeight = 8.0 + i * 4;

      for (int j = 0; j < barCount; j++) {
        final angle = (j * 2 * pi / barCount) + animationValue * pi;
        final heightFactor = (0.5 + 0.5 * sin(animationValue * 2 * pi + j * 0.3))
            .clamp(0.2, 1.0);
        
        final startPoint = Offset(
          center.dx +
              (currentRadius - barHeight * heightFactor / 2) * cos(angle),
          center.dy +
              (currentRadius - barHeight * heightFactor / 2) * sin(angle),
        );
        
        final endPoint = Offset(
          center.dx +
              (currentRadius + barHeight * heightFactor / 2) * cos(angle),
          center.dy +
              (currentRadius + barHeight * heightFactor / 2) * sin(angle),
        );
        
        paint.strokeWidth = 3.0;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircularSpectrumPainter oldDelegate) {
    return theme != oldDelegate.theme;
  }
}