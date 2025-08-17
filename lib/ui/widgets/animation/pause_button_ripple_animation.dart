import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class PauseButtonRippleAnimation extends ThemedAnimationBase {
  const PauseButtonRippleAnimation({super.key});

  @override
  State<PauseButtonRippleAnimation> createState() =>
      _PauseButtonRippleAnimationState();
}

class _PauseButtonRippleAnimationState
    extends ThemedAnimationStateBase<PauseButtonRippleAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 600));
    repeatAnimation();
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _PauseRipplePainter(controller.value, theme),
        );
      },
    );
  }
}

class _PauseRipplePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _PauseRipplePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 绘制3圈环形波纹，振幅递减
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress * 3 + i) % 3 / 3;
      final radius = 10 + rippleProgress * 20;
      final opacity = 1.0 - rippleProgress;
      final scale = 1.0 + rippleProgress * 0.5;

      // 第一圈100%，第二圈80%，第三圈60%振幅
      final amplitudeFactor = [1.0, 0.8, 0.6][i];

      paint.color = theme.colorScheme.primary.withValues(alpha: opacity * amplitudeFactor);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.drawCircle(Offset(0, 0), radius, paint);
      canvas.restore();
    }

    // 绘制中心的暂停按钮
    paint.style = PaintingStyle.fill;
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(center, 10, paint);

    // 绘制暂停图标
    final iconPaint = Paint()
      ..color = theme.colorScheme.onPrimary
      ..style = PaintingStyle.fill;

    // 绘制两个竖条表示暂停
    final rectWidth = 3.0;
    final rectHeight = 8.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - rectWidth/2 - 1, center.dy),
        width: rectWidth,
        height: rectHeight,
      ),
      iconPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + rectWidth/2 + 1, center.dy),
        width: rectWidth,
        height: rectHeight,
      ),
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PauseRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
