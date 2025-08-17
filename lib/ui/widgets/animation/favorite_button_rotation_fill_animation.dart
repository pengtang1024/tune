import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class FavoriteButtonRotationFillAnimation extends ThemedAnimationBase {
  const FavoriteButtonRotationFillAnimation({super.key});

  @override
  State<FavoriteButtonRotationFillAnimation> createState() =>
      _FavoriteButtonRotationFillAnimationState();
}

class _FavoriteButtonRotationFillAnimationState
    extends ThemedAnimationStateBase<FavoriteButtonRotationFillAnimation> {
  late Animation<double> _rotationAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 300));
    repeatReverseAnimation();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
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
          painter: _FavoriteButtonRotationFillPainter(
            _rotationAnimation.value,
            _fillAnimation.value,
            theme,
          ),
        );
      },
    );
  }
}

class _FavoriteButtonRotationFillPainter extends CustomPainter {
  final double rotation;
  final double fillProgress;
  final ThemeData theme;

  _FavoriteButtonRotationFillPainter(this.rotation, this.fillProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制按钮
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // 绘制空心圆（未收藏状态）
    if (fillProgress < 1.0) {
      paint.color = theme.colorScheme.onSurface;
      canvas.drawCircle(Offset(0, 0), 25, paint);

      // 绘制空心部分
      paint.color = theme.colorScheme.surface;
      canvas.drawCircle(Offset(0, 0), 20, paint);
    }

    // 绘制填充效果（收藏状态）
    if (fillProgress > 0) {
      paint.color = theme.colorScheme.primary.withValues(alpha: fillProgress);
      canvas.drawCircle(Offset(0, 0), 25 * fillProgress, paint);
    }

    canvas.restore();

    // 绘制轻微抖动效果（完成时）
    if (fillProgress >= 1.0) {
      final shake = 0.1 * sin(rotation * 10);
      canvas.save();
      canvas.translate(center.dx + shake, center.dy + shake);

      paint.color = theme.colorScheme.primary;
      canvas.drawCircle(Offset(0, 0), 25, paint);

      canvas.restore();
    }

    // 绘制心形图标
    final iconPaint = Paint()
      ..color = fillProgress >= 1.0
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation / 2);

    // 简化的心形形状
    final path = Path();
    path.moveTo(0, -10);
    path.lineTo(-8, -16);
    path.lineTo(-12, -8);
    path.lineTo(-6, 0);
    path.lineTo(0, 8);
    path.lineTo(6, 0);
    path.lineTo(12, -8);
    path.lineTo(8, -16);
    path.close();
    canvas.drawPath(path, iconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FavoriteButtonRotationFillPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
           oldDelegate.fillProgress != fillProgress ||
           oldDelegate.theme != theme;
  }
}
