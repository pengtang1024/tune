import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音乐节拍粒子动画组件
/// 显示音乐节拍粒子扩散效果
class MusicBeatParticleAnimation extends ThemedAnimationBase {
  final int particleGroupCount;
  final int particlesPerGroup;
  final double size;

  const MusicBeatParticleAnimation({
    super.key,
    this.particleGroupCount = 5,
    this.particlesPerGroup = 8,
    this.size = 200.0,
  });

  @override
  State<MusicBeatParticleAnimation> createState() =>
      _MusicBeatParticleAnimationState();
}

class _MusicBeatParticleAnimationState
    extends ThemedAnimationStateBase<MusicBeatParticleAnimation> {
  late Animation<double> _beatAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _beatAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _beatAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MusicBeatParticlePainter(
            _beatAnimation.value,
            theme,
            widget.particleGroupCount,
            widget.particlesPerGroup,
          ),
        );
      },
    );
  }
}

class _MusicBeatParticlePainter extends CustomPainter {
  final double beatProgress;
  final ThemeData theme;
  final int particleGroupCount;
  final int particlesPerGroup;

  _MusicBeatParticlePainter(
    this.beatProgress,
    this.theme,
    this.particleGroupCount,
    this.particlesPerGroup,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 * 0.9;
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制粒子扩散效果
    for (int group = 0; group < particleGroupCount; group++) {
      // 计算组的扩散进度
      final groupProgress =
          ((beatProgress * particleGroupCount - group) / particleGroupCount)
              .clamp(0.0, 1.0);

      // 计算组的半径
      final groupRadius = maxRadius * groupProgress;

      // 绘制组内的粒子
      for (int i = 0; i < particlesPerGroup; i++) {
        // 计算粒子角度
        final angle = 2 * pi * i / particlesPerGroup;

        // 计算粒子位置
        final x = center.dx + groupRadius * cos(angle);
        final y = center.dy + groupRadius * sin(angle);

        // 计算粒子大小（随着扩散逐渐减小）
        final particleSize = 4.0 * (1 - groupProgress * 0.7);

        // 设置颜色，使用主题色系
        // 根据组别选择不同的主题颜色
        if (group % 3 == 0) {
          paint.color = theme.colorScheme.primary;
        } else if (group % 3 == 1) {
          paint.color = theme.colorScheme.secondary;
        } else {
          paint.color = theme.colorScheme.tertiary;
        }

        // 添加透明度变化
        paint.color = paint.color.withValues(
          alpha: 0.8 * (1 - groupProgress * 0.5),
        );

        // 绘制粒子
        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }

    // 绘制中心节拍圆点
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 8.0 * (1 - beatProgress * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant _MusicBeatParticlePainter oldDelegate) {
    return oldDelegate.beatProgress != beatProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.particleGroupCount != particleGroupCount ||
        oldDelegate.particlesPerGroup != particlesPerGroup;
  }
}
