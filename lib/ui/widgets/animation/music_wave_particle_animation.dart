import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音乐波形粒子动画组件
/// 显示波形粒子效果
class MusicWaveParticleAnimation extends ThemedAnimationBase {
  final int particleCount;
  final double size;

  const MusicWaveParticleAnimation({
    super.key,
    this.particleCount = 30,
    this.size = 200.0,
  });

  @override
  State<MusicWaveParticleAnimation> createState() =>
      _MusicWaveParticleAnimationState();
}

class _MusicWaveParticleAnimationState
    extends ThemedAnimationStateBase<MusicWaveParticleAnimation> {
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MusicWaveParticlePainter(
            _waveAnimation.value,
            theme,
            widget.particleCount,
          ),
        );
      },
    );
  }
}

class _MusicWaveParticlePainter extends CustomPainter {
  final double waveProgress;
  final ThemeData theme;
  final int particleCount;

  _MusicWaveParticlePainter(this.waveProgress, this.theme, this.particleCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 存储粒子位置
    final particles = <Offset>[];

    // 绘制波形粒子
    for (int i = 0; i < particleCount; i++) {
      // 计算粒子位置
      final x = i * size.width / (particleCount - 1);
      final waveValue = sin(waveProgress * 2 * pi + i * 0.3);
      final y = size.height / 2 + waveValue * size.height / 4;
      final position = Offset(x, y);
      particles.add(position);

      // 设置颜色，使用主题色系
      // 根据索引选择不同的主题颜色
      if (i % 3 == 0) {
        paint.color = theme.colorScheme.primary;
      } else if (i % 3 == 1) {
        paint.color = theme.colorScheme.secondary;
      } else {
        paint.color = theme.colorScheme.tertiary;
      }

      // 添加透明度变化
      paint.color = paint.color.withValues(alpha: 0.8);

      // 绘制粒子
      canvas.drawCircle(position, 4.0, paint);
    }

    // 绘制连接线
    linePaint.color = theme.colorScheme.primary.withValues(alpha: 0.5);
    for (int i = 0; i < particles.length - 1; i++) {
      canvas.drawLine(particles[i], particles[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MusicWaveParticlePainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.particleCount != particleCount;
  }
}
