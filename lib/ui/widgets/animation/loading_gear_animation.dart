import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class LoadingGearAnimation extends ThemedAnimationBase {
  const LoadingGearAnimation({super.key});

  @override
  State<LoadingGearAnimation> createState() => _LoadingGearAnimationState();
}

class _LoadingGearAnimationState
    extends ThemedAnimationStateBase<LoadingGearAnimation> {
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _LoadingGearPainter(_rotationAnimation.value, theme),
        );
      },
    );
  }
}

class _LoadingGearPainter extends CustomPainter {
  final double rotation;
  final ThemeData theme;

  _LoadingGearPainter(this.rotation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制2个啮合齿轮（大齿轮慢，小齿轮快，转速比2:1）
    // 大齿轮
    canvas.save();
    canvas.translate(center.dx - 20, center.dy);
    canvas.rotate(rotation / 2); // 大齿轮慢

    paint.color = theme.colorScheme.primaryContainer;
    _drawGear(canvas, paint, 15, 8, theme); // 半径15，8个齿

    canvas.restore();

    // 小齿轮
    canvas.save();
    canvas.translate(center.dx + 20, center.dy);
    canvas.rotate(-rotation); // 小齿轮快，反向旋转

    paint.color = theme.colorScheme.secondaryContainer;
    _drawGear(canvas, paint, 10, 6, theme); // 半径10，6个齿

    canvas.restore();
  }

  // 绘制齿轮辅助方法
  void _drawGear(Canvas canvas, Paint paint, double radius, int toothCount, ThemeData theme) {
    final center = Offset(0, 0);

    // 绘制齿轮主体
    canvas.drawCircle(center, radius, paint);

    // 绘制齿状凸起
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.8);

    for (int i = 0; i < toothCount; i++) {
      final angle = i * 2 * pi / toothCount;
      final toothRadius = radius + 4;
      final toothX = toothRadius * cos(angle);
      final toothY = toothRadius * sin(angle);

      canvas.drawCircle(Offset(toothX, toothY), 2, paint);
    }

    // 绘制齿轮中心
    paint.color = theme.colorScheme.surface;
    canvas.drawCircle(center, radius / 2, paint);
  }

  @override
  bool shouldRepaint(covariant _LoadingGearPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.theme != theme;
  }
}
