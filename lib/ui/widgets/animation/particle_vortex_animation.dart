import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class ParticleVortexAnimation extends ThemedAnimationBase {
  const ParticleVortexAnimation({super.key});

  @override
  State<ParticleVortexAnimation> createState() =>
      _ParticleVortexAnimationState();
}

class _ParticleVortexAnimationState
    extends ThemedAnimationStateBase<ParticleVortexAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 4));
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
          painter: _ParticleVortexPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ParticleVortexPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ParticleVortexPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制50个粒子形成旋涡状旋转流动
    final particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      // 粒子初始角度
      final initialAngle = (i * 2 * pi / particleCount);

      // 粒子距中心的距离
      final distance = 5 + (i % 10) * 3;

      // 转速随音量升高而加快（通过progress模拟）
      final rotationSpeed = 1 + progress;

      // 计算当前角度
      final angle = initialAngle + progress * 2 * pi * rotationSpeed;

      // 粒子位置
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      // 粒子距中心越近转速越快，颜色也越深
      final speedFactor = 1 - (distance / 35);
      final colorIntensity = 0.3 + 0.7 * speedFactor;

      // 使用主题色并根据距离调整透明度
      paint.color = theme.colorScheme.primary.withValues(alpha: colorIntensity);

      // 绘制粒子
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleVortexPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
