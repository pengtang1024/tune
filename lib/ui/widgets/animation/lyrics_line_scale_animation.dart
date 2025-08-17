import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

class LyricsLineScaleAnimation extends ThemedAnimationBase {
  const LyricsLineScaleAnimation({super.key});

  @override
  State<LyricsLineScaleAnimation> createState() =>
      _LyricsLineScaleAnimationState();
}

class _LyricsLineScaleAnimationState
    extends ThemedAnimationStateBase<LyricsLineScaleAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatReverseAnimation();

    _animation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: CustomPaint(
            size: const Size(80, 60),
            painter: _LyricsLineScalePainter(theme),
          ),
        );
      },
    );
  }
}

class _LyricsLineScalePainter extends CustomPainter {
  final ThemeData theme;

  _LyricsLineScalePainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制当前歌词行
    const text = "当前歌词行";
    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 居中绘制
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // 绘制非当前行（灰色）
    final otherStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 14.0,
    );

    final otherTextPainter = TextPainter(
      text: TextSpan(text: "其他歌词行", style: otherStyle),
      textDirection: TextDirection.ltr,
    );
    otherTextPainter.layout();

    otherTextPainter.paint(
      canvas,
      Offset(
        (size.width - otherTextPainter.width) / 2,
        (size.height - otherTextPainter.height) / 2 - 20,
      ),
    );

    otherTextPainter.text = TextSpan(text: "其他歌词行", style: otherStyle);
    otherTextPainter.layout();
    otherTextPainter.paint(
      canvas,
      Offset(
        (size.width - otherTextPainter.width) / 2,
        (size.height - otherTextPainter.height) / 2 + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LyricsLineScalePainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}