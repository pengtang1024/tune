import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class SpectrumWaterfallAnimation extends ThemedAnimationBase {
  const SpectrumWaterfallAnimation({super.key});

  @override
  State<SpectrumWaterfallAnimation> createState() =>
      _SpectrumWaterfallAnimationState();
}

class _SpectrumWaterfallAnimationState
    extends ThemedAnimationStateBase<SpectrumWaterfallAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _SpectrumWaterfallPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _SpectrumWaterfallPainter extends CustomPainter {
  final double animationValue;
  final ThemeData theme;

  _SpectrumWaterfallPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barCount = 32;
    final barWidth = size.width / barCount;

    // 绘制瀑布频谱
    for (int i = 0; i < barCount; i++) {
      // 频谱高度基于时间变化的正弦波
      final heightFactor = 0.5 +
          0.5 *
              sin(animationValue * 4 * pi +
                  i * 0.3); // 不同柱子有相位差，形成波浪效果
      final barHeight = size.height * heightFactor * 0.8;

      // 透明度随高度变化
      final opacityFactor = 0.3 + 0.7 * (barHeight / size.height);
      final opacity = opacityFactor.clamp(0.1, 0.8);

      // 根据频率选择颜色（使用主题色）
      Color color;
      if (i < barCount / 3) {
        // 低频 - 使用主题主色
        color = theme.colorScheme.primary.withOpacity(opacity);
      } else if (i < 2 * barCount / 3) {
        // 中频 - 使用主题次色
        color = theme.colorScheme.secondary.withOpacity(opacity);
      } else {
        // 高频 - 使用主题第三色
        color = theme.colorScheme.tertiary.withOpacity(opacity);
      }

      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - barHeight, barWidth - 1,
            barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
