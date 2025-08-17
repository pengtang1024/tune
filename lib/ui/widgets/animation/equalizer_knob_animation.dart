import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class EqualizerKnobAnimation extends ThemedAnimationBase {
  const EqualizerKnobAnimation({super.key});

  @override
  State<EqualizerKnobAnimation> createState() => _EqualizerKnobAnimationState();
}

class _EqualizerKnobAnimationState
    extends ThemedAnimationStateBase<EqualizerKnobAnimation> {
  late Animation<double> _rotationAnimation;
  late Animation<double> _reboundAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    _reboundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter:
              _EqualizerKnobPainter(_rotationAnimation.value, _reboundAnimation.value, theme),
        );
      },
    );
  }
}

class _EqualizerKnobPainter extends CustomPainter {
  final double rotationAngle;
  final double reboundProgress;
  final ThemeData theme;

  _EqualizerKnobPainter(this.rotationAngle, this.reboundProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制旋钮外圈
    paint.color = theme.colorScheme.primaryContainer;
    canvas.drawCircle(center, 25, paint);

    // 绘制旋钮边框
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5);
    canvas.drawCircle(center, 25, paint);

    // 绘制刻度线
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    // 绘制30条刻度线
    for (int i = 0; i < 30; i++) {
      final angle = (i * 12 - 90) * pi / 180; // 从顶部开始，每12°一条
      final startRadius = i % 3 == 0 ? 15 : 18; // 主刻度更靠近中心
      final endRadius = i % 3 == 0 ? 20 : 23; // 主刻度更长
      
      final startX = center.dx + startRadius * cos(angle);
      final startY = center.dy + startRadius * sin(angle);
      final endX = center.dx + endRadius * cos(angle);
      final endY = center.dy + endRadius * sin(angle);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // 计算回弹角度（±2°）
    final reboundAngle = 0.0349 * sin(reboundProgress * 2 * pi); // 2° in radians
    
    // 绘制旋钮指针
    paint.style = PaintingStyle.fill;
    paint.color = theme.colorScheme.primary;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle + reboundAngle);
    
    // 绘制指针形状
    final path = Path();
    path.moveTo(0, -15); // 指针尖端
    path.lineTo(-3, 0);
    path.lineTo(0, 3);
    path.lineTo(3, 0);
    path.close();
    
    canvas.drawPath(path, paint);
    
    canvas.restore();
    
    // 绘制旋钮中心点
    paint.color = theme.colorScheme.onPrimaryContainer;
    canvas.drawCircle(center, 4, paint);
    
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}