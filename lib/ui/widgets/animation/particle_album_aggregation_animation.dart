import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class ParticleAlbumAggregationAnimation extends ThemedAnimationBase {
  const ParticleAlbumAggregationAnimation({super.key});

  @override
  State<ParticleAlbumAggregationAnimation> createState() =>
      _ParticleAlbumAggregationAnimationState();
}

class _ParticleAlbumAggregationAnimationState
    extends ThemedAnimationStateBase<ParticleAlbumAggregationAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
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
          painter: _ParticleAlbumAggregationPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ParticleAlbumAggregationPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ParticleAlbumAggregationPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final particleCount = 20;

    // 绘制从四周向中心聚合的粒子
    for (int i = 0; i < particleCount; i++) {
      // 初始位置 - 随机分布在画布周围
      final angle = (i * 2 * pi / particleCount) + (progress * pi / 4);
      final distance = size.width * 0.4;
      final initialX = center.dx + distance * cos(angle);
      final initialY = center.dy + distance * sin(angle);

      // 目标位置 - 逐渐向中心聚集
      final targetX = center.dx;
      final targetY = center.dy;

      // 当前位置 - 基于进度的插值
      final currentX = initialX + (targetX - initialX) * progress;
      final currentY = initialY + (targetY - initialY) * progress;

      // 粒子大小随进度变化
      final particleSize = 2.0 + progress * 2.0;

      // 粒子颜色 - 使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
        theme.colorScheme.error,
      ];

      paint.color = colors[i % colors.length].withOpacity(0.7 + progress * 0.3);

      canvas.drawCircle(Offset(currentX, currentY), particleSize, paint);
    }

    // 当聚合完成时，绘制中心的专辑封面轮廓
    if (progress > 0.7) {
      final scale = (progress - 0.7) / 0.3;
      paint.color = theme.colorScheme.onSurface.withOpacity(scale * 0.5);
      canvas.drawCircle(center, 20 * scale, paint);

      // 绘制专辑封面内的音乐符号
      if (scale > 0.5) {
        final iconPaint = Paint()
          ..color = theme.colorScheme.onSurface.withOpacity(scale)
          ..style = PaintingStyle.fill;

        // 简化的音乐符号
        canvas.drawCircle(
            Offset(center.dx - 5, center.dy - 5), 3 * scale, iconPaint);
        canvas.drawCircle(
            Offset(center.dx + 5, center.dy - 5), 3 * scale, iconPaint);
        canvas.drawRect(
            Rect.fromLTWH(center.dx - 6, center.dy, 12, 8 * scale), iconPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
