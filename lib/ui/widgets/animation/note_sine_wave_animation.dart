import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class NoteSineWaveAnimation extends ThemedAnimationBase {
  const NoteSineWaveAnimation({super.key});

  @override
  State<NoteSineWaveAnimation> createState() => _NoteSineWaveAnimationState();
}

class _NoteSineWaveAnimationState
    extends ThemedAnimationStateBase<NoteSineWaveAnimation> {
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
          painter: _SineWavePainter(controller.value, theme),
        );
      },
    );
  }
}

class _SineWavePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _SineWavePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    // 绘制3个沿正弦曲线移动的音符
    for (int i = 0; i < 3; i++) {
      final x = (progress * size.width + i * 30) % (size.width + 60) - 30;
      
      // 正弦波公式: y = A * sin(B * (x - C)) + D
      final amplitude = 10.0; // 振幅
      final frequency = 0.05; // 频率
      final y = size.height / 2 + amplitude * sin(frequency * x + progress * 2 * pi);
      
      // 音符大小随位置变化
      final scale = 0.8 + 0.2 * (1 + sin(frequency * x + progress * 2 * pi)) / 2;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      
      // 使用主题色绘制音符
      final colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ];
      final notePaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(0, 0), 6, notePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SineWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}