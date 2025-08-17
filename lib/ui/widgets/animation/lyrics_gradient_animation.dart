import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'themed_animation_base.dart';

class LyricsGradientAnimation extends ThemedAnimationBase {
  const LyricsGradientAnimation({super.key});

  @override
  State<LyricsGradientAnimation> createState() => _LyricsGradientAnimationState();
}

class _LyricsGradientAnimationState
    extends ThemedAnimationStateBase<LyricsGradientAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 60),
          painter: _LyricsGradientPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _LyricsGradientPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _LyricsGradientPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制当前歌词行
    final text = "当前播放歌词行";
    final normalStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 14,
    );
    
    final normalTextPainter = TextPainter(
      text: TextSpan(text: text, style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    normalTextPainter.layout();
    
    // 绘制非当前行（灰色）
    normalTextPainter.paint(canvas, const Offset(0, 10));
    
    // 创建渐变色遮罩
    final gradientRect = Rect.fromLTWH(0, 0, size.width * progress, size.height);
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.width * progress, 0),
      [
        theme.colorScheme.onSurface,
        theme.colorScheme.primary,
      ],
    );
    
    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.srcIn;
    
    // 使用遮罩绘制当前行
    canvas.saveLayer(Offset.zero & size, paint);
    
    final highlightStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    
    final highlightTextPainter = TextPainter(
      text: TextSpan(text: text, style: highlightStyle),
      textDirection: TextDirection.ltr,
    );
    highlightTextPainter.layout();
    highlightTextPainter.paint(canvas, const Offset(0, 10));
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LyricsGradientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}