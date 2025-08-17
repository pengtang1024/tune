import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

class ProgressPulseAnimation extends ThemedAnimationBase {
  const ProgressPulseAnimation({super.key});

  @override
  State<ProgressPulseAnimation> createState() => _ProgressPulseAnimationState();
}

class _ProgressPulseAnimationState
    extends ThemedAnimationStateBase<ProgressPulseAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 500));
    repeatReverseAnimation();

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
          painter: _ProgressPulsePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _ProgressPulsePainter extends CustomPainter {
  final double pulseScale;
  final ThemeData theme;

  _ProgressPulsePainter(this.pulseScale, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 绘制进度条
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 3, size.width, 6),
      paint,
    );

    // 绘制已完成的进度
    paint.color = theme.colorScheme.primary;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 3, size.width * 0.7, 6),
      paint,
    );

    // 绘制末端滑块
    final sliderX = size.width * 0.7;
    final sliderY = size.height / 2;
    
    // 脉冲效果通过缩放实现
    canvas.save();
    canvas.translate(sliderX, sliderY);
    canvas.scale(pulseScale);
    
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(Offset(0, 0), 8, paint);
    
    // 滑块内圈
    paint.color = theme.colorScheme.onPrimary;
    canvas.drawCircle(Offset(0, 0), 4, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressPulsePainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale || oldDelegate.theme != theme;
  }
}