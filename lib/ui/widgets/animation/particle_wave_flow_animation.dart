import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class ParticleWaveFlowAnimation extends ThemedAnimationBase {
  const ParticleWaveFlowAnimation({super.key});

  @override
  State<ParticleWaveFlowAnimation> createState() =>
      _ParticleWaveFlowAnimationState();
}

class _ParticleWaveFlowAnimationState
    extends ThemedAnimationStateBase<ParticleWaveFlowAnimation> {
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
          painter: _ParticleWaveFlowPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ParticleWaveFlowPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ParticleWaveFlowPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 先绘制波形路径
    final path = Path();
    path.moveTo(0, size.height / 2);
    
    final pointCount = 20;
    for (int i = 1; i <= pointCount; i++) {
      final x = i * size.width / pointCount;
      // 波形公式: y = A * sin(B * x + C)
      final y = size.height / 2 + 10 * sin((i / pointCount) * 4 * pi + progress * 2 * pi);
      path.lineTo(x, y);
    }
    
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = theme.colorScheme.primary;
    canvas.drawPath(path, paint);

    // 绘制30个粒子随音频沿波形路径流动
    final particleCount = 30;
    for (int i = 0; i < particleCount; i++) {
      // 粒子在路径上的位置
      final particleProgress = (progress + i * 0.1) % 1.0;
      final x = particleProgress * size.width;
      
      // 根据波形计算y坐标
      final y = size.height / 2 + 10 * sin(particleProgress * 4 * pi + progress * 2 * pi);
      
      // 粒子经过波峰时轻微上浮，波谷时轻微下沉
      final waveOffset = 2 * sin(particleProgress * 4 * pi + progress * 2 * pi);
      
      // 使用主题色
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ];
      
      // 粒子颜色
      paint.style = PaintingStyle.fill;
      paint.color = colors[i % colors.length].withValues(alpha: 0.7);
      
      // 绘制粒子
      canvas.drawCircle(Offset(x, y + waveOffset), 2, paint);
      
      // 绘制半透明尾迹（前几个位置）
      for (int j = 1; j <= 3; j++) {
        final trailProgress = (particleProgress - j * 0.02) % 1.0;
        final trailX = trailProgress * size.width;
        final trailY = size.height / 2 + 10 * sin(trailProgress * 4 * pi + progress * 2 * pi);
        final trailOffset = 2 * sin(trailProgress * 4 * pi + progress * 2 * pi);
        
        paint.color = colors[i % colors.length].withValues(alpha: 0.7 - j * 0.2);
        canvas.drawCircle(Offset(trailX, trailY + trailOffset), 1.5 - j * 0.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleWaveFlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}