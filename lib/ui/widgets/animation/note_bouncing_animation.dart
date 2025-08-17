import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class NoteBouncingAnimation extends ThemedAnimationBase {
  const NoteBouncingAnimation({super.key});

  @override
  State<NoteBouncingAnimation> createState() => _NoteBouncingAnimationState();
}

class _NoteBouncingAnimationState extends ThemedAnimationStateBase<NoteBouncingAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
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
          painter: _NoteBouncingPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _NoteBouncingPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _NoteBouncingPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制5个随机弹跳的音符
    final noteCount = 5;
    for (int i = 0; i < noteCount; i++) {
      // 音符位置基于时间进度和随机偏移
      final timeOffset = (progress * noteCount + i) % noteCount / noteCount;
      final x = 10 + i * 15.0;
      
      // 弹跳轨迹为衰减正弦波
      final bounceHeight = 30 * sin(timeOffset * 4 * pi) * exp(-timeOffset * 2);
      
      // 音符颜色随主题变化
      paint.color = i % 2 == 0 
        ? theme.colorScheme.primary 
        : theme.colorScheme.secondary;
      
      final notePath = Path();
      notePath.moveTo(x, size.height - 10 - bounceHeight);
      notePath.lineTo(x - 5, size.height - 15 - bounceHeight);
      notePath.lineTo(x, size.height - 25 - bounceHeight);
      notePath.lineTo(x + 5, size.height - 15 - bounceHeight);
      notePath.close();
      
      canvas.drawPath(notePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoteBouncingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}