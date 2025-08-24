import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 专辑封面粒子化动画组件
/// 显示专辑封面粒子化效果
class AlbumCoverParticleAnimation extends ThemedAnimationBase {
  final int particleCount;
  final double size;

  const AlbumCoverParticleAnimation({
    super.key,
    this.particleCount = 100,
    this.size = 200.0,
  });

  @override
  State<AlbumCoverParticleAnimation> createState() =>
      _AlbumCoverParticleAnimationState();
}

class _AlbumCoverParticleAnimationState
    extends ThemedAnimationStateBase<AlbumCoverParticleAnimation> {
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AlbumCoverParticlePainter(
            _particleAnimation.value,
            theme,
            widget.particleCount,
          ),
        );
      },
    );
  }
}

class _AlbumCoverParticlePainter extends CustomPainter {
  final double particleProgress;
  final ThemeData theme;
  final int particleCount;

  _AlbumCoverParticlePainter(
    this.particleProgress,
    this.theme,
    this.particleCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制粒子化专辑封面
    for (int i = 0; i < particleCount; i++) {
      // 计算粒子角度
      final angle = 2 * pi * i / particleCount;

      // 计算粒子初始位置（圆形排列）
      final initialX = center.dx + radius * cos(angle);
      final initialY = center.dy + radius * sin(angle);

      // 计算粒子偏移量（基于进度）
      final offsetRadius = particleProgress * radius * 2;
      final offsetX = offsetRadius * cos(angle * 3);
      final offsetY = offsetRadius * sin(angle * 2);

      // 计算粒子最终位置
      final x = initialX + offsetX;
      final y = initialY + offsetY;

      // 计算粒子大小（随着扩散逐渐减小）
      final particleSize = 3.0 * (1 - particleProgress * 0.8);

      // 设置颜色，使用主题色系
      final colorIndex = (i % 3);
      switch (colorIndex) {
        case 0:
          paint.color = theme.colorScheme.primary;
          break;
        case 1:
          paint.color = theme.colorScheme.secondary;
          break;
        case 2:
          paint.color = theme.colorScheme.tertiary;
          break;
        default:
          paint.color = theme.colorScheme.primary;
      }

      // 添加透明度变化
      paint.color = paint.color.withValues(
        alpha: 0.8 * (1 - particleProgress * 0.5),
      );

      // 绘制粒子
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // 在动画初期绘制中心专辑封面
    if (particleProgress < 0.5) {
      final coverRadius = radius * (1 - particleProgress * 2);
      paint.color = theme.colorScheme.primary;
      canvas.drawCircle(center, coverRadius, paint);

      // 绘制封面内圈
      paint.color = theme.colorScheme.surface;
      canvas.drawCircle(center, coverRadius * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AlbumCoverParticlePainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.particleCount != particleCount;
  }
}
