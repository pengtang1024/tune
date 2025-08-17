import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class PlayStatePulseAnimation extends ThemedAnimationBase {
  const PlayStatePulseAnimation({super.key});

  @override
  State<PlayStatePulseAnimation> createState() =>
      _PlayStatePulseAnimationState();
}

class _PlayStatePulseAnimationState
    extends ThemedAnimationStateBase<PlayStatePulseAnimation> {
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();

    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _PlayStatePulsePainter(_pulseAnimation.value, theme),
        );
      },
    );
  }
}

class _PlayStatePulsePainter extends CustomPainter {
  final double pulseProgress;
  final ThemeData theme;

  _PlayStatePulsePainter(this.pulseProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制3个脉冲圆环
    for (int i = 0; i < 3; i++) {
      final ringProgress = (pulseProgress * 3 + i) % 3 / 3;
      final radius = 20 + ringProgress * 20;
      final opacity = 1.0 - ringProgress;

      paint.color = theme.colorScheme.primary.withValues(alpha: opacity * 0.5);
      canvas.drawCircle(center, radius, paint);
    }

    // 绘制中心播放按钮
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 20, paint);

    // 绘制播放图标
    paint.color = theme.colorScheme.onPrimary;
    final path = Path();
    path.moveTo(center.dx - 8, center.dy - 8);
    path.lineTo(center.dx + 10, center.dy);
    path.lineTo(center.dx - 8, center.dy + 8);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayStatePulsePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress || oldDelegate.theme != theme;
  }
}
