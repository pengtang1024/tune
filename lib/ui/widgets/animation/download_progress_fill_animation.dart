import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class DownloadProgressFillAnimation extends ThemedAnimationBase {
  const DownloadProgressFillAnimation({super.key});

  @override
  State<DownloadProgressFillAnimation> createState() =>
      _DownloadProgressFillAnimationState();
}

class _DownloadProgressFillAnimationState
    extends ThemedAnimationStateBase<DownloadProgressFillAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 4000));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
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
          painter: _DownloadProgressFillPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _DownloadProgressFillPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _DownloadProgressFillPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // 计算下载进度（前75%为填充，后25%为闪烁）
    final fillProgress = (progress * 1.33).clamp(0.0, 1.0);
    final blinkProgress = progress > 0.75 ? (progress - 0.75) * 4 : 0;

    // 绘制下载图标轮廓
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    
    // 外圆
    canvas.drawCircle(center, 25, paint);

    // 箭头（向下）
    final path = Path();
    path.moveTo(center.dx - 10, center.dy - 5);
    path.lineTo(center.dx, center.dy + 5);
    path.lineTo(center.dx + 10, center.dy - 5);
    canvas.drawPath(path, paint);

    // 竖线
    path.moveTo(center.dx, center.dy + 5);
    path.lineTo(center.dx, center.dy + 10);
    canvas.drawPath(path, paint);

    // 绘制填充效果
    if (fillProgress > 0) {
      paint.style = PaintingStyle.fill;
      paint.color = theme.colorScheme.primary.withValues(alpha: 0.7);

      // 创建扇形路径表示填充进度
      final rect = Rect.fromCircle(center: center, radius: 24);
      final startAngle = -pi / 2; // 从顶部开始
      final sweepAngle = 2 * pi * fillProgress;

      final fillPath = Path()
        ..moveTo(center.dx, center.dy)
        ..addArc(rect, startAngle, sweepAngle)
        ..close();

      canvas.drawPath(fillPath, paint);

      // 绘制内部箭头（已完成部分）
      if (fillProgress > 0.3) {
        final arrowPaint = Paint()
          ..color = theme.colorScheme.onPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final arrowPath = Path();
        arrowPath.moveTo(center.dx - 6, center.dy - 2);
        arrowPath.lineTo(center.dx, center.dy + 3);
        arrowPath.lineTo(center.dx + 6, center.dy - 2);
        canvas.drawPath(arrowPath, arrowPaint);

        arrowPath.moveTo(center.dx, center.dy + 3);
        arrowPath.lineTo(center.dx, center.dy + 7);
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

    // 完成时闪烁效果
    if (fillProgress >= 1.0 && blinkProgress > 0) {
      // 闪烁3次
      final blink = (sin(blinkProgress * 6 * pi).abs() * 3).toInt() % 3;
      if (blink > 0) {
        paint.style = PaintingStyle.fill;
        paint.color = theme.colorScheme.primary.withValues(alpha: 0.5);
        canvas.drawCircle(center, 25, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}