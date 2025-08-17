import 'dart:math';
import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

/// 音频可视化动画组件
/// 显示音乐播放时的音频波形效果
class AudioVisualizerAnimation extends ThemedAnimationBase {
  final int barCount;
  final Color? color;

  const AudioVisualizerAnimation({
    super.key,
    this.barCount = 20,
    this.color,
  });

  @override
  State<AudioVisualizerAnimation> createState() =>
      _AudioVisualizerAnimationState();
}

class _AudioVisualizerAnimationState
    extends ThemedAnimationStateBase<AudioVisualizerAnimation> {
  late List<Animation<double>> _barAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 1500));
    repeatReverseAnimation();

    // 创建每个柱子的动画
    _barAnimations = List.generate(widget.barCount, (index) {
      // 为每个柱子设置不同的动画延迟和曲线
      final delay = (index % 5) * 0.1;
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(delay, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    // 创建透明度动画
    _opacityAnimations = List.generate(widget.barCount, (index) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    });
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.barCount * 6.0, 40.0),
          painter: _AudioVisualizerPainter(
            barAnimations: _barAnimations,
            opacityAnimations: _opacityAnimations,
            color: widget.color ?? theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _AudioVisualizerPainter extends CustomPainter {
  final List<Animation<double>> barAnimations;
  final List<Animation<double>> opacityAnimations;
  final Color color;

  _AudioVisualizerPainter({
    required this.barAnimations,
    required this.opacityAnimations,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = barAnimations.length;
    final barWidth = size.width / barCount;
    final maxHeight = size.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (int i = 0; i < barCount; i++) {
      final barHeight = maxHeight * barAnimations[i].value;
      final opacity = opacityAnimations[i].value;
      
      // 计算柱子的位置
      final left = i * barWidth + 1;
      final top = (maxHeight - barHeight) / 2;
      final right = (i + 1) * barWidth - 1;
      final bottom = top + barHeight;

      // 设置颜色和透明度
      paint.color = color.withValues(alpha: opacity);

      // 绘制圆角矩形柱子
      final rect = Rect.fromLTRB(left, top, right, bottom);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AudioVisualizerPainter oldDelegate) {
    return oldDelegate.barAnimations != barAnimations ||
        oldDelegate.opacityAnimations != opacityAnimations ||
        oldDelegate.color != color;
  }
}