import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class LoadingDotBounceAnimation extends ThemedAnimationBase {
  const LoadingDotBounceAnimation({super.key});

  @override
  State<LoadingDotBounceAnimation> createState() =>
      _LoadingDotBounceAnimationState();
}

class _LoadingDotBounceAnimationState
    extends ThemedAnimationStateBase<LoadingDotBounceAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1200));
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
          painter: _LoadingDotBouncePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _LoadingDotBouncePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _LoadingDotBouncePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    // 绘制3个圆点上下交替跳动（A→B→C循环）
    final dotCount = 3;
    final dotRadius = 5.0;
    final dotSpacing = 20.0;

    for (int i = 0; i < dotCount; i++) {
      // 跳动高度随机（5-10px）
      final maxHeight = 5 + i * 2.5;

      // 计算跳动进度
      final dotProgress = (progress * dotCount + i) % dotCount / dotCount;
      final jumpProgress = (dotProgress * 3) % 1.0;

      // 跳动曲线（上升和下降）
      double bounce;
      if (jumpProgress < 0.5) {
        // 上升阶段
        bounce = maxHeight * (jumpProgress * 2);
      } else {
        // 下降阶段
        bounce = maxHeight * (1 - (jumpProgress - 0.5) * 2);
      }

      // 圆点位置
      final x = center.dx + (i - 1) * dotSpacing;
      final y = center.dy - bounce;

      // 圆点颜色
      paint.color = theme.colorScheme.primary.withValues(alpha: 0.7 + 0.3 * (1 - bounce / maxHeight));

      // 绘制圆点
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingDotBouncePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
