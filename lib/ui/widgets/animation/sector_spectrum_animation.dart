import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class SectorSpectrumAnimation extends ThemedAnimationBase {
  const SectorSpectrumAnimation({super.key});

  @override
  State<SectorSpectrumAnimation> createState() =>
      _SectorSpectrumAnimationState();
}

class _SectorSpectrumAnimationState
    extends ThemedAnimationStateBase<SectorSpectrumAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
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
          painter: _SectorSpectrumPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _SectorSpectrumPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _SectorSpectrumPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;

    // 音量模拟值（0-100%）
    final volume = (50 + 50 * sin(progress * 2 * pi)).clamp(0.0, 100.0);
    
    // 扇形角度 = 音量 × 3.6°
    final sectorAngle = volume * 3.6 * pi / 180;
    
    // 绘制3条平行线，随角度同步展开
    final lineCount = 3;
    for (int i = 0; i < lineCount; i++) {
      // 线条距离中心的距离
      final radius = 20.0 + i * 10.0;
      
      // 线条颜色与音量关联（高音量偏亮）
      final brightness = 0.5 + 0.5 * (volume / 100);
      paint.color = HSLColor.fromColor(theme.colorScheme.primary)
          .withLightness(brightness)
          .toColor();
      
      // 绘制扇形弧线
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -sectorAngle / 2, // 起始角度
        sectorAngle, // 扫描角度
        false, // 不闭合
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SectorSpectrumPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}