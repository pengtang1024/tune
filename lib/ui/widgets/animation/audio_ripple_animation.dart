import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 音频波纹动画组件
/// 显示水波纹扩散的效果
class AudioRippleAnimation extends ThemedAnimationBase {
  final double size;
  final int rippleCount;

  const AudioRippleAnimation({
    super.key,
    this.size = 200.0,
    this.rippleCount = 4,
  });

  @override
  State<AudioRippleAnimation> createState() => _AudioRippleAnimationState();
}

class _AudioRippleAnimationState
    extends ThemedAnimationStateBase<AudioRippleAnimation> {
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
    repeatAnimation();

    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AudioRipplePainter(
            _rippleAnimation.value,
            theme,
            widget.rippleCount,
          ),
        );
      },
    );
  }
}

class _AudioRipplePainter extends CustomPainter {
  final double rippleProgress;
  final ThemeData theme;
  final int rippleCount;

  _AudioRipplePainter(this.rippleProgress, this.theme, this.rippleCount);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // 绘制多个波纹
    for (int i = 0; i < rippleCount; i++) {
      // 计算当前波纹的进度
      final progress =
          (rippleProgress * rippleCount + i) % rippleCount / rippleCount;

      // 计算半径和透明度
      final radius = progress * maxRadius;
      final opacity = 1.0 - progress;

      // 设置画笔颜色
      paint.color = theme.colorScheme.primary.withValues(alpha: opacity * 0.6);

      // 绘制波纹
      canvas.drawCircle(center, radius, paint);
    }

    // 绘制中心的音频图标
    paint.style = PaintingStyle.fill;
    paint.color = theme.colorScheme.primary;
    _drawAudioIcon(canvas, center, 20.0, paint);
  }

  /// 绘制音频图标
  void _drawAudioIcon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    // 绘制音符
    path.moveTo(center.dx - size * 0.4, center.dy);
    path.lineTo(center.dx - size * 0.4, center.dy - size * 0.8);
    path.lineTo(center.dx + size * 0.2, center.dy - size * 0.4);
    path.lineTo(center.dx + size * 0.2, center.dy + size * 0.2);
    path.close();

    canvas.drawPath(path, paint);

    // 绘制声波线
    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(
        center: center + Offset(size * 0.6, 0),
        radius: size * 0.3,
      ),
      -pi / 4,
      pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center + Offset(size * 0.9, 0),
        radius: size * 0.5,
      ),
      -pi / 6,
      pi / 3,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AudioRipplePainter oldDelegate) {
    return oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.rippleCount != rippleCount;
  }
}
