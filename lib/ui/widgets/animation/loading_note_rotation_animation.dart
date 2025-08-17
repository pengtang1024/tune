import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class LoadingNoteRotationAnimation extends ThemedAnimationBase {
  const LoadingNoteRotationAnimation({super.key});

  @override
  State<LoadingNoteRotationAnimation> createState() =>
      _LoadingNoteRotationAnimationState();
}

class _LoadingNoteRotationAnimationState
    extends ThemedAnimationStateBase<LoadingNoteRotationAnimation> {
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _LoadingNotePainter(
            _rotationAnimation.value,
            _scaleAnimation.value,
            theme,
          ),
        );
      },
    );
  }
}

class _LoadingNotePainter extends CustomPainter {
  final double rotation;
  final double scale;
  final ThemeData theme;

  _LoadingNotePainter(this.rotation, this.scale, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制3个围绕中心点旋转的音符
    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * 2 * pi / 3);
      final distance = 20.0;

      final noteX = center.dx + distance * cos(angle);
      final noteY = center.dy + distance * sin(angle);

      // 音符大小随位置变化（近大远小，但这里简化处理）
      final noteScale = scale * (0.8 + 0.2 * sin(angle));

      // 使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ];
      paint.color = colors[i % colors.length];

      canvas.save();
      canvas.translate(noteX, noteY);
      canvas.scale(noteScale);

      // 绘制音符
      canvas.drawCircle(Offset(0, 0), 6, paint);
      canvas.restore();
    }

    // 绘制中心点
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(covariant _LoadingNotePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
           oldDelegate.scale != scale ||
           oldDelegate.theme != theme;
  }
}
