import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class WaveformGridAnimation extends ThemedAnimationBase {
  const WaveformGridAnimation({super.key});

  @override
  State<WaveformGridAnimation> createState() => _WaveformGridAnimationState();
}

class _WaveformGridAnimationState
    extends ThemedAnimationStateBase<WaveformGridAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatAnimation();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _WaveformGridPainter(controller.value, theme),
        );
      },
    );
  }
}

class _WaveformGridPainter extends CustomPainter {
  final double animation;
  final ThemeData theme;

  _WaveformGridPainter(this.animation, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;

    // 绘制多条波形线组成网格，每条线响应不同频段
    final lineCount = 3; // 简化为3条线
    
    for (int i = 0; i < lineCount; i++) {
      final path = Path();
      
      // 线间距随音量变化（音量大时间距宽）
      final volumeFactor = 0.8 + 0.2 * sin(animation);
      final verticalOffset = i * 15 * volumeFactor + 15;
      
      // 使用主题色的不同色调
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ];
      paint.color = colors[i % colors.length];
      
      // 移动到起始点
      path.moveTo(0, verticalOffset);
      
      // 绘制波形线
      final pointCount = 20;
      for (int j = 1; j <= pointCount; j++) {
        final x = j * size.width / pointCount;
        // 每条线响应不同频段（通过相位差实现）
        final phase = i * pi / 4;
        final y = verticalOffset + 8 * sin((j / pointCount) * 4 * pi + animation + phase);
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformGridPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.theme != theme;
  }
}