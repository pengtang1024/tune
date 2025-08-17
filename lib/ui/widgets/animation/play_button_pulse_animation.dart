import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

/// 播放按钮脉冲动画组件
/// 显示播放按钮周围的脉冲效果
class PlayButtonPulseAnimation extends ThemedAnimationBase {
  final double size;
  final int pulseCount;

  const PlayButtonPulseAnimation({
    super.key,
    this.size = 60.0,
    this.pulseCount = 3,
  });

  @override
  State<PlayButtonPulseAnimation> createState() =>
      _PlayButtonPulseAnimationState();
}

class _PlayButtonPulseAnimationState
    extends ThemedAnimationStateBase<PlayButtonPulseAnimation> {
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatAnimation();

    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PlayButtonPulsePainter(_pulseAnimation.value, theme, widget.pulseCount),
        );
      },
    );
  }
}

class _PlayButtonPulsePainter extends CustomPainter {
  final double pulseProgress;
  final ThemeData theme;
  final int pulseCount;

  _PlayButtonPulsePainter(this.pulseProgress, this.theme, this.pulseCount);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3;
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制多个脉冲圆环
    for (int i = 0; i < pulseCount; i++) {
      // 计算当前脉冲的进度
      final ringProgress = (pulseProgress * pulseCount + i) % pulseCount / pulseCount;

      // 计算半径和透明度
      final radius = baseRadius + ringProgress * (size.width / 2 - baseRadius);
      final opacity = 1.0 - ringProgress;

      // 设置画笔颜色
      paint.color = theme.colorScheme.primary.withValues(alpha: opacity * 0.4);

      // 绘制圆环
      canvas.drawCircle(center, radius, paint);
    }

    // 绘制中心的播放按钮
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, baseRadius, paint);

    // 绘制播放图标
    paint.color = theme.colorScheme.onPrimary;
    final iconSize = baseRadius * 0.6;
    final path = Path();
    path.moveTo(center.dx - iconSize * 0.4, center.dy - iconSize * 0.5);
    path.lineTo(center.dx - iconSize * 0.4, center.dy + iconSize * 0.5);
    path.lineTo(center.dx + iconSize * 0.6, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayButtonPulsePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.pulseCount != pulseCount;
  }
}
