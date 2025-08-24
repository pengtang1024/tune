import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频可视化环形动画组件
/// 显示环形音频可视化效果
class AudioVisualizerRingAnimation extends ThemedAnimationBase {
  final int barCount;
  final double size;

  const AudioVisualizerRingAnimation({
    super.key,
    this.barCount = 60,
    this.size = 200.0,
  });

  @override
  State<AudioVisualizerRingAnimation> createState() =>
      _AudioVisualizerRingAnimationState();
}

class _AudioVisualizerRingAnimationState
    extends ThemedAnimationStateBase<AudioVisualizerRingAnimation> {
  late Animation<double> _visualizerAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _visualizerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _visualizerAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AudioVisualizerRingPainter(
            _visualizerAnimation.value,
            theme,
            widget.barCount,
          ),
        );
      },
    );
  }
}

class _AudioVisualizerRingPainter extends CustomPainter {
  final double visualizerProgress;
  final ThemeData theme;
  final int barCount;

  _AudioVisualizerRingPainter(
    this.visualizerProgress,
    this.theme,
    this.barCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.7;
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制音频可视化环形
    for (int i = 0; i < barCount; i++) {
      // 计算角度
      final angle = 2 * pi * i / barCount;
      final nextAngle = 2 * pi * (i + 1) / barCount;

      // 计算音频强度
      final frequency = sin(visualizerProgress * 2 * pi + i * 0.2);
      final intensity = (frequency + 1) / 2; // 范围 0-1

      // 计算条形高度
      final barHeight = radius * 0.3 * intensity;

      // 计算条形位置
      final innerRadius = radius - barHeight;
      final outerRadius = radius;

      // 创建路径
      final path = Path();
      final startPoint = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      final nextStartPoint = Offset(
        center.dx + innerRadius * cos(nextAngle),
        center.dy + innerRadius * sin(nextAngle),
      );
      final nextEndPoint = Offset(
        center.dx + outerRadius * cos(nextAngle),
        center.dy + outerRadius * sin(nextAngle),
      );

      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(endPoint.dx, endPoint.dy);
      path.lineTo(nextEndPoint.dx, nextEndPoint.dy);
      path.lineTo(nextStartPoint.dx, nextStartPoint.dy);
      path.close();

      // 设置颜色，使用主题色系
      // 根据位置选择不同的主题颜色
      if (i < barCount ~/ 3) {
        paint.color = theme.colorScheme.primary;
      } else if (i < 2 * barCount ~/ 3) {
        paint.color = theme.colorScheme.secondary;
      } else {
        paint.color = theme.colorScheme.tertiary;
      }

      // 添加透明度变化
      paint.color = paint.color.withValues(alpha: 0.8 * intensity);

      // 绘制条形
      canvas.drawPath(path, paint);
    }

    // 绘制中心圆点
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant _AudioVisualizerRingPainter oldDelegate) {
    return oldDelegate.visualizerProgress != visualizerProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.barCount != barCount;
  }
}
