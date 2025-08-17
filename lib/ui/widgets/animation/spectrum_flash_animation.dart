import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class SpectrumFlashAnimation extends ThemedAnimationBase {
  const SpectrumFlashAnimation({super.key});

  @override
  State<SpectrumFlashAnimation> createState() => _SpectrumFlashAnimationState();
}

class _SpectrumFlashAnimationState
    extends ThemedAnimationStateBase<SpectrumFlashAnimation> {
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
          painter: _SpectrumFlashPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _SpectrumFlashPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _SpectrumFlashPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制多个频谱柱
    final barCount = 15;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      // 计算柱子的高度
      final heightFactor = (0.3 +
              0.7 * sin(progress * 2 * pi + i * 0.5)).clamp(0.1, 1.0);
      final barHeight = size.height * heightFactor;

      // 计算闪烁亮度（80%-100%）
      final flashIntensity = 0.8 + 0.2 * sin(progress * 4 * pi + i);
      
      // 仅强度>50%的柱体参与闪烁
      final effectiveFlash = heightFactor > 0.5 ? flashIntensity : 1.0;

      // 根据频率选择颜色（使用主题色的不同色调）
      Color baseColor;
      if (i < barCount / 3) {
        // 低频 - 主色
        baseColor = theme.colorScheme.primary;
      } else if (i < 2 * barCount / 3) {
        // 中频 - 次色
        baseColor = theme.colorScheme.secondary;
      } else {
        // 高频 - 三级色
        baseColor = theme.colorScheme.tertiary;
      }

      // 应用闪烁效果
      paint.color = baseColor.withValues(alpha: effectiveFlash);

      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth, 
          size.height - barHeight, 
          barWidth - 1, 
          barHeight
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumFlashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}