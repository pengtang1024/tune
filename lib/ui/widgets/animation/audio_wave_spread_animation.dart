import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频波形扩散动画组件
/// 显示波纹扩散效果
class AudioWaveSpreadAnimation extends ThemedAnimationBase {
  final double size;
  final int ringCount;

  const AudioWaveSpreadAnimation({
    super.key,
    this.size = 200.0,
    this.ringCount = 5,
  });

  @override
  State<AudioWaveSpreadAnimation> createState() =>
      _AudioWaveSpreadAnimationState();
}

class _AudioWaveSpreadAnimationState
    extends ThemedAnimationStateBase<AudioWaveSpreadAnimation> {
  late Animation<double> _spreadAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _spreadAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _spreadAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AudioWaveSpreadPainter(
            _spreadAnimation.value,
            theme,
            widget.ringCount,
          ),
        );
      },
    );
  }
}

class _AudioWaveSpreadPainter extends CustomPainter {
  final double spreadProgress;
  final ThemeData theme;
  final int ringCount;

  _AudioWaveSpreadPainter(this.spreadProgress, this.theme, this.ringCount);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制多个扩散圆环
    for (int i = 0; i < ringCount; i++) {
      // 计算当前圆环的进度
      final ringProgress =
          (spreadProgress * ringCount + i) % ringCount / ringCount;

      // 计算半径和透明度
      final radius = ringProgress * maxRadius;
      final opacity = 1.0 - ringProgress;

      // 设置画笔颜色
      paint.color = theme.colorScheme.primary.withValues(alpha: opacity * 0.7);

      // 绘制圆环
      canvas.drawCircle(center, radius, paint);
    }

    // 绘制中心的波形点
    paint.style = PaintingStyle.fill;
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 5.0, paint);
  }

  @override
  bool shouldRepaint(covariant _AudioWaveSpreadPainter oldDelegate) {
    return oldDelegate.spreadProgress != spreadProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.ringCount != ringCount;
  }
}
