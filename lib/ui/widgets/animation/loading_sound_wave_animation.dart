import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class LoadingSoundWaveAnimation extends ThemedAnimationBase {
  const LoadingSoundWaveAnimation({super.key});

  @override
  State<LoadingSoundWaveAnimation> createState() =>
      _LoadingSoundWaveAnimationState();
}

class _LoadingSoundWaveAnimationState
    extends ThemedAnimationStateBase<LoadingSoundWaveAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
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
          painter: _LoadingSoundWavePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _LoadingSoundWavePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _LoadingSoundWavePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;

    // 动态调整线条数量（高端5条，低端3条，这里简化为3-5条）
    final lineCount = 3 + (2 * progress).toInt();

    for (int i = 0; i < lineCount; i++) {
      final path = Path();

      // 线条间距
      final lineSpacing = size.width / (lineCount + 1);
      final x = (i + 1) * lineSpacing;

      // 波动幅度随加载进度增加
      final amplitude = 5 + 10 * progress;

      // 每条线频率不同
      final frequency = 0.05 + i * 0.02;

      // 移动到起始点
      path.moveTo(x, size.height);

      // 绘制上下波动的声波线
      final pointCount = 20;
      for (int j = 1; j <= pointCount; j++) {
        final y = size.height - j * size.height / pointCount;
        final offsetX = amplitude * sin(frequency * y + progress * 2 * pi);
        path.lineTo(x + offsetX, y);
      }

      // 线条颜色使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
        theme.colorScheme.error,
        theme.colorScheme.surfaceTint,
      ];
      paint.color = colors[i % colors.length];
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingSoundWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
