import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class ProgressBarSegmentedLoadingAnimation extends ThemedAnimationBase {
  const ProgressBarSegmentedLoadingAnimation({super.key});

  @override
  State<ProgressBarSegmentedLoadingAnimation> createState() =>
      _ProgressBarSegmentedLoadingAnimationState();
}

class _ProgressBarSegmentedLoadingAnimationState
    extends ThemedAnimationStateBase<ProgressBarSegmentedLoadingAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
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
          painter: _ProgressBarSegmentedLoadingPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ProgressBarSegmentedLoadingPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _ProgressBarSegmentedLoadingPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制进度条背景
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 5, size.width, 10),
      paint,
    );

    // 模拟分段加载（最多显示10段）
    final segmentCount = 10;
    final segmentWidth = size.width / segmentCount;
    
    for (int i = 0; i < segmentCount; i++) {
      // 计算每个段落的状态
      final segmentProgress = (progress * segmentCount + i) % segmentCount / segmentCount;
      
      // 段落位置
      final x = i * segmentWidth;
      
      // 根据状态设置颜色
      if (segmentProgress < 0.5) {
        // 已缓存段显示实体色
        paint.color = theme.colorScheme.primary;
        canvas.drawRect(
          Rect.fromLTWH(x, size.height / 2 - 5, segmentWidth - 1, 10),
          paint,
        );
      } else if (segmentProgress < 0.8) {
        // 未缓存段显示灰色
        paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
        canvas.drawRect(
          Rect.fromLTWH(x, size.height / 2 - 5, segmentWidth - 1, 10),
          paint,
        );
      } else {
        // 缓存中段落闪烁
        final blink = 0.8 + 0.2 * sin(segmentProgress * 4 * pi);
        paint.color = theme.colorScheme.primary.withValues(alpha: blink);
        canvas.drawRect(
          Rect.fromLTWH(x, size.height / 2 - 5, segmentWidth - 1, 10),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBarSegmentedLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}