import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class AudioPeakFireworksAnimation extends ThemedAnimationBase {
  const AudioPeakFireworksAnimation({super.key});

  @override
  State<AudioPeakFireworksAnimation> createState() =>
      _AudioPeakFireworksAnimationState();
}

class _AudioPeakFireworksAnimationState
    extends ThemedAnimationStateBase<AudioPeakFireworksAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 600));
    repeatAnimation();

    _animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _FireworksPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _FireworksPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制多个爆发点（随机分布）
    final explosionCount = 3;
    final random = Random(123); // 固定种子确保一致性
    
    for (int i = 0; i < explosionCount; i++) {
      // 随机爆发点位置
      final explosionX = center.dx + (random.nextDouble() - 0.5) * size.width * 0.2;
      final explosionY = center.dy + (random.nextDouble() - 0.5) * size.height * 0.2;
      
      // 绘制粒子（类似烟花）
      final particleCount = 20;
      for (int j = 0; j < particleCount; j++) {
        final angle = j * 2 * pi / particleCount;
        final distance = progress * 25;
        final particleSize = 3.0 * (1 - progress);

        final position = Offset(
          explosionX + distance * cos(angle),
          explosionY + distance * sin(angle),
        );

        // 粒子颜色使用主题色
        final colors = [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
          theme.colorScheme.tertiary,
          theme.colorScheme.error,
          theme.colorScheme.surfaceTint
        ];
        paint.color = colors[j % colors.length].withValues(alpha: 1.0 - progress);
        canvas.drawCircle(position, particleSize, paint);
      }
    }

    // 绘制中心闪光
    if (progress < 0.3) {
      paint.color = theme.colorScheme.onSurface.withValues(alpha: 1.0 - progress * 3);
      canvas.drawCircle(center, 8 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}