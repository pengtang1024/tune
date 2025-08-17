import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class CubeSpectrumAnimation extends ThemedAnimationBase {
  const CubeSpectrumAnimation({super.key});

  @override
  State<CubeSpectrumAnimation> createState() => _CubeSpectrumAnimationState();
}

class _CubeSpectrumAnimationState
    extends ThemedAnimationStateBase<CubeSpectrumAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
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
          painter: _CubeSpectrumPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _CubeSpectrumPainter extends CustomPainter {
  final double animationValue;
  final ThemeData theme;

  _CubeSpectrumPainter(this.animationValue, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 计算缩放因子（基于动画值）
    final scaleFactor = 0.8 + 0.2 * (0.5 + 0.5 * sin(animationValue * 2 * pi));

    // 绘制立方体频谱
    for (int i = 0; i < 5; i++) {
      // 每个立方体有不同的大小和位置
      final offset = (i - 2) * 20 * scaleFactor;
      final heightFactor = 0.5 + 0.5 * sin(animationValue * 2 * pi + i * 0.5);
      final cubeSize = 15 * scaleFactor * (0.7 + 0.3 * heightFactor);

      // 绘制顶部
      final topWidth = cubeSize;
      final topHeight = cubeSize * 0.5;
      final topRect = Rect.fromLTWH(
        center.dx - topWidth / 2 + offset,
        center.dy - cubeSize / 2,
        topWidth,
        topHeight,
      );

      // 顶部颜色（使用主题主色，较暗）
      paint.color = theme.colorScheme.primary.withValues(alpha: 0.5);
      canvas.drawRect(topRect, paint);

      // 绘制侧面
      final sideWidth = cubeSize * 0.5;
      final sideHeight = cubeSize;
      final sideRect = Rect.fromLTWH(
        center.dx + topWidth / 2 + offset - sideWidth / 2,
        center.dy - cubeSize / 2,
        sideWidth,
        sideHeight,
      );

      // 侧面颜色（使用主题次色，中等亮度）
      paint.color = theme.colorScheme.secondary.withValues(alpha: 0.6);
      canvas.drawRect(sideRect, paint);

      // 绘制正面
      final frontWidth = cubeSize;
      final frontHeight = cubeSize;
      final frontRect = Rect.fromLTWH(
        center.dx - frontWidth / 2 + offset,
        center.dy - cubeSize / 2 + topHeight / 2,
        frontWidth,
        frontHeight,
      );

      // 正面颜色（使用主题第三色，较亮）
      paint.color = theme.colorScheme.tertiary.withValues(alpha: 0.7);
      canvas.drawRect(frontRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
