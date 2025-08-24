import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音乐粒子连接动画组件
/// 显示连接粒子效果
class MusicParticleConnectAnimation extends ThemedAnimationBase {
  final int particleCount;
  final double size;

  const MusicParticleConnectAnimation({
    super.key,
    this.particleCount = 20,
    this.size = 200.0,
  });

  @override
  State<MusicParticleConnectAnimation> createState() =>
      _MusicParticleConnectAnimationState();
}

class _MusicParticleConnectAnimationState
    extends ThemedAnimationStateBase<MusicParticleConnectAnimation> {
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MusicParticleConnectPainter(
            _particleAnimation.value,
            theme,
            widget.particleCount,
          ),
        );
      },
    );
  }
}

class _MusicParticleConnectPainter extends CustomPainter {
  final double particleProgress;
  final ThemeData theme;
  final int particleCount;

  _MusicParticleConnectPainter(
    this.particleProgress,
    this.theme,
    this.particleCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 存储粒子位置
    final particles = <Offset>[];

    // 绘制粒子
    for (int i = 0; i < particleCount; i++) {
      // 计算粒子位置
      final x = (sin(particleProgress * 2 * pi + i * 0.5) + 1) / 2 * size.width;
      final y =
          (cos(particleProgress * 2 * pi + i * 0.3) + 1) / 2 * size.height;
      final position = Offset(x, y);
      particles.add(position);

      // 设置粒子颜色，使用主题色系
      // 根据索引选择不同的主题颜色
      if (i % 3 == 0) {
        paint.color = theme.colorScheme.primary;
      } else if (i % 3 == 1) {
        paint.color = theme.colorScheme.secondary;
      } else {
        paint.color = theme.colorScheme.tertiary;
      }

      // 添加透明度变化
      paint.color = paint.color.withValues(alpha: 0.7);

      // 绘制粒子
      canvas.drawCircle(position, 3.0, paint);
    }

    // 绘制连接线
    for (int i = 0; i < particleCount; i++) {
      for (int j = i + 1; j < particleCount; j++) {
        // 计算距离
        final dx = particles[i].dx - particles[j].dx;
        final dy = particles[i].dy - particles[j].dy;
        final distance = sqrt(dx * dx + dy * dy);

        // 如果距离小于阈值，绘制连接线
        if (distance < 80.0) {
          // 设置连接线颜色，使用主题色系
          connectionPaint.color = theme.colorScheme.primary.withValues(
            alpha: 0.3 * (1 - distance / 80.0),
          );

          // 绘制连接线
          canvas.drawLine(particles[i], particles[j], connectionPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MusicParticleConnectPainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.particleCount != particleCount;
  }
}
