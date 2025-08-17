import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class AlbumPageFlipAnimation extends ThemedAnimationBase {
  const AlbumPageFlipAnimation({super.key});

  @override
  State<AlbumPageFlipAnimation> createState() => _AlbumPageFlipAnimationState();
}

class _AlbumPageFlipAnimationState
    extends ThemedAnimationStateBase<AlbumPageFlipAnimation> {
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 2000));
    repeatReverseAnimation();

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _AlbumPageFlipPainter(_flipAnimation.value, theme),
        );
      },
    );
  }
}

class _AlbumPageFlipPainter extends CustomPainter {
  final double flipProgress;
  final ThemeData theme;

  _AlbumPageFlipPainter(this.flipProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bookWidth = 40.0;
    final bookHeight = 50.0;

    // 绘制书本封面（背面）
    final backCoverPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx - bookWidth / 4, center.dy),
        width: bookWidth,
        height: bookHeight,
      ),
      backCoverPaint,
    );

    // 绘制书本封面文字
    final backTextPaint = Paint()
      ..color = theme.colorScheme.onPrimary
      ..style = PaintingStyle.fill;

    // 简化的字母和线条表示文字
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - bookWidth / 4 - 10, center.dy - 15, 20, 3),
      backTextPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - bookWidth / 4 - 8, center.dy - 10, 16, 2),
      backTextPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - bookWidth / 4, center.dy + 10), 5, backTextPaint);

    // 计算翻页角度（PI为完全翻开）
    final flipAngle = flipProgress * pi;

    // 计算正面页的透明度（翻页过程中逐渐消失）
    final frontOpacity = cos(flipAngle).abs();

    // 绘制正在翻动的页面
    final pagePaint = Paint()
      ..color = theme.colorScheme.surface
      ..style = PaintingStyle.fill;

    final pageBorderPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    // 设置翻页的旋转中心点
    canvas.translate(center.dx + bookWidth / 4, center.dy);
    canvas.rotate(flipAngle);

    // 绘制页面
    canvas.drawRect(
      Rect.fromLTWH(-bookWidth / 2, -bookHeight / 2, bookWidth / 2, bookHeight),
      pagePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-bookWidth / 2, -bookHeight / 2, bookWidth / 2, bookHeight),
      pageBorderPaint,
    );

    // 绘制页面内容（当页面接近垂直时更明显）
    if (frontOpacity > 0.3) {
      final contentOpacity = (frontOpacity - 0.3) / 0.7;
      final contentPaint = Paint()
        ..color = theme.colorScheme.onSurface.withValues(alpha: contentOpacity)
        ..style = PaintingStyle.fill;

      // 简化的音符符号
      canvas.drawCircle(Offset(-10, -10), 3, contentPaint);
      canvas.drawCircle(Offset(0, -10), 3, contentPaint);
      canvas.drawCircle(Offset(10, -10), 3, contentPaint);
      canvas.drawCircle(Offset(-5, 0), 3, contentPaint);
      canvas.drawCircle(Offset(5, 0), 3, contentPaint);
      canvas.drawCircle(Offset(0, 10), 5, contentPaint);
    }

    canvas.restore();

    // 绘制纸张褶皱阴影效果（简化）
    final shadowPaint = Paint()
      ..color = theme.colorScheme.shadow.withValues(alpha: 0.2 * (1 - frontOpacity.abs()))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 5, center.dy + 25),
        width: 40,
        height: 10,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}