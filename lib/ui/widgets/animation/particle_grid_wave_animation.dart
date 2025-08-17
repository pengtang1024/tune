import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class ParticleGridWaveAnimation extends ThemedAnimationBase {
  const ParticleGridWaveAnimation({super.key});

  @override
  State<ParticleGridWaveAnimation> createState() =>
      _ParticleGridWaveAnimationState();
}

class _ParticleGridWaveAnimationState
    extends ThemedAnimationStateBase<ParticleGridWaveAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _ParticleGridWavePainter(controller.value, theme),
        );
      },
    );
  }
}

class _ParticleGridWavePainter extends CustomPainter {
  final double animation;
  final ThemeData theme;

  _ParticleGridWavePainter(this.animation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 创建5x5的粒子网格
    final gridSize = 5;
    final cellSize = size.width / gridSize;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // 计算粒子位置
        final x = i * cellSize + cellSize / 2;
        final y = j * cellSize + cellSize / 2;
        
        // 根据音频波动计算粒子的垂直位移
        // 低频影响底部粒子，高频影响顶部粒子
        final frequencyFactor = j / (gridSize - 1); // 0-1之间，底部为0，顶部为1
        final waveHeight = 10 * sin(animation + i * 0.5 + j * 0.3);
        final offsetY = waveHeight * (1 - frequencyFactor);
        
        // 使用主题色并根据高度变化调整透明度
        final colorIntensity = 0.5 + 0.5 * (1 - frequencyFactor);
        paint.color = theme.colorScheme.primary.withValues(alpha: colorIntensity);
        
        // 绘制粒子
        canvas.drawCircle(
          Offset(x, y + offsetY),
          3,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleGridWavePainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.theme != theme;
  }
}