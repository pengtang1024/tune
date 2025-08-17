import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class NoteRainAnimation extends ThemedAnimationBase {
  const NoteRainAnimation({super.key});

  @override
  State<NoteRainAnimation> createState() => _NoteRainAnimationState();
}

class _NoteRainAnimationState
    extends ThemedAnimationStateBase<NoteRainAnimation> {
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
          painter: _NoteRainPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _NoteRainPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _NoteRainPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制5个下落的音符
    final noteCount = 5;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < noteCount; i++) {
      final random = Random(i * 100);
      // 音符的水平位置随机
      final x = random.nextDouble() * size.width;

      // 音符的垂直位置基于时间和初始位置
      final startY = (random.nextDouble() * -size.height).toInt().toDouble();
      final endY = size.height;
      final y = startY + (endY - startY) * ((progress + i * 0.2) % 1.0);

      // 音符旋转角度
      final rotation = (progress * 2 * pi + i) % (2 * pi);

      // 使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
        theme.colorScheme.error,
        theme.colorScheme.surfaceTint,
      ];
      paint.color = colors[i % colors.length];

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // 绘制音符
      canvas.drawCircle(Offset(0, 0), 4, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NoteRainPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
