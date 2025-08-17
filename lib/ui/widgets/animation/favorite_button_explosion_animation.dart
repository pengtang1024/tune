import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class FavoriteButtonExplosionAnimation extends ThemedAnimationBase {
  const FavoriteButtonExplosionAnimation({super.key});

  @override
  State<FavoriteButtonExplosionAnimation> createState() =>
      _FavoriteButtonExplosionAnimationState();
}

class _FavoriteButtonExplosionAnimationState
    extends ThemedAnimationStateBase<FavoriteButtonExplosionAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
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
          painter: _FavoriteButtonExplosionPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _FavoriteButtonExplosionPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _FavoriteButtonExplosionPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制心形按钮
    final buttonProgress = (progress * 3).clamp(0.0, 1.0);
    if (buttonProgress < 1.0) {
      // 心形路径
      final heartPath = Path();
      heartPath.moveTo(center.dx, center.dy + 5);
      
      // 创建心形的上半部分
      for (double i = 0; i <= 2 * pi; i += 0.1) {
        final x = 16 * pow(sin(i), 3);
        final y = -(13 * cos(i) - 5 * cos(2*i) - 2 * cos(3*i) - cos(4*i));
        heartPath.lineTo(
          center.dx + x * (1 - buttonProgress),
          center.dy + y * (1 - buttonProgress),
        );
      }
      
      heartPath.close();
      
      // 绘制心形
      paint.color = theme.colorScheme.primary.withValues(alpha: 1.0 - buttonProgress * 0.5);
      canvas.drawPath(heartPath, paint);
    }

    // 爆炸粒子效果
    if (progress > 0.3) {
      final explosionProgress = ((progress - 0.3) * 1.5).clamp(0.0, 1.0);
      final particleCount = 15;

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 2 * pi / particleCount) + explosionProgress * pi;
        final distance = explosionProgress * 25;
        final particleSize = 4.0 * (1 - explosionProgress);

        final position = Offset(
          center.dx + distance * cos(angle),
          center.dy + distance * sin(angle),
        );

        // 粒子颜色与主题色一致
        paint.color = theme.colorScheme.primary.withValues(alpha: 1.0 - explosionProgress);
        
        // 绘制星形粒子
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle);
        
        // 简化星形为菱形
        final path = Path();
        path.moveTo(0, -particleSize);
        path.lineTo(particleSize / 2, 0);
        path.lineTo(0, particleSize);
        path.lineTo(-particleSize / 2, 0);
        path.close();
        
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}