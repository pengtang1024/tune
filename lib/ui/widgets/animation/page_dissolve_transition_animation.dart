import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class PageDissolveTransitionAnimation extends ThemedAnimationBase {
  const PageDissolveTransitionAnimation({super.key});

  @override
  State<PageDissolveTransitionAnimation> createState() =>
      _PageDissolveTransitionAnimationState();
}

class _PageDissolveTransitionAnimationState
    extends ThemedAnimationStateBase<PageDissolveTransitionAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 400));
    repeatReverseAnimation();

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
          painter: _PageDissolveTransitionPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _PageDissolveTransitionPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _PageDissolveTransitionPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 模拟页面溶解过渡效果
    // 使用噪声纹理实现溶解效果（简化版）
    final random = Random(12345); // 固定种子确保一致性
    
    // 绘制网格点来模拟噪声效果
    final gridSize = 10;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // 根据噪声值和进度决定是否绘制点
        final noiseValue = random.nextDouble();
        if (noiseValue < progress) {
          // 使用主题色并根据进度调整
          final colorIntensity = 0.5 + 0.5 * progress;
          paint.color = HSLColor.fromColor(theme.colorScheme.primary)
              .withLightness(colorIntensity)
              .toColor();
          
          canvas.drawRect(
            Rect.fromLTWH(
              i * cellWidth,
              j * cellHeight,
              cellWidth,
              cellHeight,
            ),
            paint,
          );
        }
      }
    }
    
    // 添加边缘模糊效果（简化）
    final blurPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.3 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      blurPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PageDissolveTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}