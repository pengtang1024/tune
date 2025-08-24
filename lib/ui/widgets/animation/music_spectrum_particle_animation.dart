import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音乐频谱粒子动画组件
/// 显示频谱粒子效果
class MusicSpectrumParticleAnimation extends ThemedAnimationBase {
  final int particleRowCount;
  final int particleColumnCount;
  final double size;

  const MusicSpectrumParticleAnimation({
    super.key,
    this.particleRowCount = 8,
    this.particleColumnCount = 12,
    this.size = 200.0,
  });

  @override
  State<MusicSpectrumParticleAnimation> createState() =>
      _MusicSpectrumParticleAnimationState();
}

class _MusicSpectrumParticleAnimationState
    extends ThemedAnimationStateBase<MusicSpectrumParticleAnimation> {
  late Animation<double> _spectrumAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _spectrumAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _spectrumAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MusicSpectrumParticlePainter(
            _spectrumAnimation.value,
            theme,
            widget.particleRowCount,
            widget.particleColumnCount,
          ),
        );
      },
    );
  }
}

class _MusicSpectrumParticlePainter extends CustomPainter {
  final double spectrumProgress;
  final ThemeData theme;
  final int particleRowCount;
  final int particleColumnCount;

  _MusicSpectrumParticlePainter(
    this.spectrumProgress,
    this.theme,
    this.particleRowCount,
    this.particleColumnCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 计算粒子网格参数
    final cellWidth = size.width / particleColumnCount;
    final cellHeight = size.height / particleRowCount;

    // 绘制频谱粒子
    for (int row = 0; row < particleRowCount; row++) {
      for (int col = 0; col < particleColumnCount; col++) {
        // 计算频谱强度
        final frequency = sin(spectrumProgress * 2 * pi + (row + col) * 0.4);
        final intensity = (frequency + 1) / 2; // 范围 0-1

        // 计算粒子大小
        final particleSize = 3.0 + 5.0 * intensity;

        // 计算粒子位置
        final x = col * cellWidth + cellWidth / 2;
        final y = row * cellHeight + cellHeight / 2;

        // 设置颜色，使用主题色系
        // 根据行列位置选择不同的主题颜色
        if (row < particleRowCount ~/ 3) {
          paint.color = theme.colorScheme.primary;
        } else if (row < 2 * particleRowCount ~/ 3) {
          paint.color = theme.colorScheme.secondary;
        } else {
          paint.color = theme.colorScheme.tertiary;
        }

        // 添加透明度变化
        paint.color = paint.color.withValues(alpha: 0.8 * intensity);

        // 绘制粒子
        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MusicSpectrumParticlePainter oldDelegate) {
    return oldDelegate.spectrumProgress != spectrumProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.particleRowCount != particleRowCount ||
        oldDelegate.particleColumnCount != particleColumnCount;
  }
}
