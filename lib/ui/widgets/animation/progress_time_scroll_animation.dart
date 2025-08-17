import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class ProgressTimeScrollAnimation extends ThemedAnimationBase {
  const ProgressTimeScrollAnimation({super.key});

  @override
  State<ProgressTimeScrollAnimation> createState() =>
      _ProgressTimeScrollAnimationState();
}

class _ProgressTimeScrollAnimationState
    extends ThemedAnimationStateBase<ProgressTimeScrollAnimation> {
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
          painter: _TimeScrollPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _TimeScrollPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _TimeScrollPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 模拟时间数字"1:23"的滚动效果
    final minutes = 1;
    final seconds = (23 + (progress * 60)).toInt() % 60;

    // 构造时间字符串
    final timeString = "$minutes:${seconds.toString().padLeft(2, '0')}";

    // 绘制时间文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeString,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(0, 1 * progress),
              blurRadius: 1,
              color: theme.colorScheme.shadow.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 居中绘制
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TimeScrollPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
