import 'package:flutter/material.dart';
import 'themed_animation_base.dart';

class LyricsHighlightAnimation extends ThemedAnimationBase {
  const LyricsHighlightAnimation({super.key});

  @override
  State<LyricsHighlightAnimation> createState() =>
      _LyricsHighlightAnimationState();
}

class _LyricsHighlightAnimationState
    extends ThemedAnimationStateBase<LyricsHighlightAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 3000));
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
          painter: _LyricsHighlightPainter(_animation.value, theme),
        );
      },
    );
  }
}

class _LyricsHighlightPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;
  final String text = "这是一句歌词示例";

  _LyricsHighlightPainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 创建基础文本画笔
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 绘制整行歌词（灰色）
    textPainter.paint(canvas, const Offset(0, 10));

    // 计算高亮字符的数量
    final highlightCount = (text.length * progress).toInt();

    if (highlightCount > 0) {
      // 创建高亮部分的文本画笔
      final highlightTextPainter = TextPainter(
        text: TextSpan(
          text: text.substring(0, highlightCount),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      highlightTextPainter.layout();

      // 绘制高亮部分
      highlightTextPainter.paint(canvas, const Offset(0, 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}