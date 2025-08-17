import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

class PlayButtonFillAnimation extends ThemedAnimationBase {
  const PlayButtonFillAnimation({super.key});

  @override
  State<PlayButtonFillAnimation> createState() =>
      _PlayButtonFillAnimationState();
}

class _PlayButtonFillAnimationState
    extends ThemedAnimationStateBase<PlayButtonFillAnimation> {
  late Animation<double> _fillAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 900));
    repeatAnimation();

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: const Size(80, 60),
            painter: _PlayButtonFillPainter(_fillAnimation.value, theme),
          ),
        );
      },
    );
  }
}

class _PlayButtonFillPainter extends CustomPainter {
  final double fillProgress;
  final ThemeData theme;

  _PlayButtonFillPainter(this.fillProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 3次脉冲式填充，填充范围逐次扩大
    double currentFill = 0;
    if (fillProgress < 1.0 / 3) {
      // 第一次填充30%
      currentFill = 0.3 * (fillProgress * 3);
    } else if (fillProgress < 2.0 / 3) {
      // 第二次填充60%
      currentFill = 0.3 + 0.3 * ((fillProgress - 1.0 / 3) * 3);
    } else {
      // 第三次填充100%
      currentFill = 0.6 + 0.4 * ((fillProgress - 2.0 / 3) * 3);
    }

    // 绘制按钮边缘
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    canvas.drawCircle(center, 30, paint);

    // 绘制填充部分
    if (currentFill > 0) {
      paint.color = theme.colorScheme.primary.withValues(alpha: 0.5 + 0.5 * currentFill);
      canvas.drawCircle(center, 30 * currentFill, paint);
    }

    // 绘制播放图标
    final iconPaint = Paint()
      ..color = theme.colorScheme.onPrimary
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx - 10, center.dy - 12);
    path.lineTo(center.dx - 10, center.dy + 12);
    path.lineTo(center.dx + 12, center.dy);
    path.close();
    canvas.drawPath(path, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _PlayButtonFillPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress || oldDelegate.theme != theme;
  }
}