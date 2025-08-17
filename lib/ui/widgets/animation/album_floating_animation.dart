import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class AlbumFloatingAnimation extends ThemedAnimationBase {
  const AlbumFloatingAnimation({super.key});

  @override
  State<AlbumFloatingAnimation> createState() => _AlbumFloatingAnimationState();
}

class _AlbumFloatingAnimationState
    extends ThemedAnimationStateBase<AlbumFloatingAnimation> {
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();

    _floatAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _AlbumFloatingPainter(
              _floatAnimation.value, _rotateAnimation.value, theme),
        );
      },
    );
  }
}

class _AlbumFloatingPainter extends CustomPainter {
  final double floatAnimation;
  final double rotateAnimation;
  final ThemeData theme;

  _AlbumFloatingPainter(
      this.floatAnimation, this.rotateAnimation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 计算浮动偏移量（基于正弦波）
    final floatOffset = 5 * sin(floatAnimation);

    // 绘制专辑封面
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 专辑封面背景
    paint.color = theme.colorScheme.primaryContainer;
    canvas.drawCircle(Offset(center.dx, center.dy + floatOffset), 25, paint);

    // 专辑封面边框
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(center.dx, center.dy + floatOffset), 25, paint);

    // 绘制专辑封面内容（音乐符号）
    paint.style = PaintingStyle.fill;
    paint.color = theme.colorScheme.onPrimaryContainer;
    
    canvas.save();
    canvas.translate(center.dx, center.dy + floatOffset);
    canvas.rotate(rotateAnimation);
    
    // 绘制音乐符号
    canvas.drawCircle(Offset(-6, -3), 3, paint);
    canvas.drawCircle(Offset(6, -3), 3, paint);
    canvas.drawCircle(Offset(0, 6), 3, paint);
    
    canvas.restore();
    
    // 绘制投影（增强悬浮感）
    final shadowPaint = Paint()
      ..color = theme.colorScheme.shadow.withValues(alpha: 0.3 - 0.1 * sin(floatAnimation).abs())
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 30 - floatOffset),
        width: 40,
        height: 10 - 2 * sin(floatAnimation).abs(),
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}