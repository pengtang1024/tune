import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class ShareButtonParticleAnimation extends ThemedAnimationBase {
  const ShareButtonParticleAnimation({super.key});

  @override
  State<ShareButtonParticleAnimation> createState() =>
      _ShareButtonParticleAnimationState();
}

class _ShareButtonParticleAnimationState
    extends ThemedAnimationStateBase<ShareButtonParticleAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _ShareButtonParticlePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ShareButtonParticlePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ShareButtonParticlePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制中心的分享图标
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = theme.colorScheme.primary;

    // 绘制中心圆圈
    canvas.drawCircle(center, 10, paint);

    // 绘制分享箭头
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = theme.colorScheme.primary;

    // 第一个箭头
    canvas.drawLine(Offset(center.dx - 15, center.dy),
        Offset(center.dx - 5, center.dy - 5), arrowPaint);
    canvas.drawLine(Offset(center.dx - 15, center.dy),
        Offset(center.dx - 5, center.dy + 5), arrowPaint);

    // 第二个箭头
    canvas.drawLine(Offset(center.dx, center.dy - 15),
        Offset(center.dx + 5, center.dy - 5), arrowPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 15),
        Offset(center.dx - 5, center.dy - 5), arrowPaint);

    // 第三个箭头
    canvas.drawLine(Offset(center.dx + 15, center.dy),
        Offset(center.dx + 5, center.dy - 5), arrowPaint);
    canvas.drawLine(Offset(center.dx + 15, center.dy),
        Offset(center.dx + 5, center.dy + 5), arrowPaint);

    // 绘制扩散的粒子效果
    if (progress > 0) {
      final particleProgress = (progress * 5).clamp(0.0, 1.0);
      final particleCount = 12;

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 2 * pi / particleCount);
        final baseDistance = particleProgress * 30;
        final distance = baseDistance * (0.8 + 0.4 * (i % 3) / 3);

        // 粒子大小逐渐缩小至消失
        final particleSize = 3.0 * (1 - particleProgress);

        final x = center.dx + distance * cos(angle);
        final y = center.dy + distance * sin(angle);

        paint.style = PaintingStyle.fill;

        // 使用主题色的多种变体
        final colors = [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
          theme.colorScheme.tertiary,
        ];

        paint.color = colors[i % colors.length].withValues(alpha: 1.0 - particleProgress);
        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
