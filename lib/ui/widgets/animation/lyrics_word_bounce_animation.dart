import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class LyricsWordBounceAnimation extends ThemedAnimationBase {
  const LyricsWordBounceAnimation({super.key});

  @override
  State<LyricsWordBounceAnimation> createState() =>
      _LyricsWordBounceAnimationState();
}

class _LyricsWordBounceAnimationState
    extends ThemedAnimationStateBase<LyricsWordBounceAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
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
          painter: _LyricsWordBouncePainter(_animation.value, theme),
        );
      },
    );
  }
}

class _LyricsWordBouncePainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  _LyricsWordBouncePainter(this.progress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制当前歌词句子"音乐播放器"
    const text = "音乐播放器";
    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    );

    // 绘制非当前句（灰色）
    final otherStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 14.0,
    );

    final otherTextPainter = TextPainter(
      text: TextSpan(text: "上一句歌词", style: otherStyle),
      textDirection: TextDirection.ltr,
    );
    otherTextPainter.layout();
    otherTextPainter.paint(
      canvas,
      Offset(
        (size.width - otherTextPainter.width) / 2,
        0,
      ),
    );

    // 绘制当前句
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    // 逐字绘制并添加弹跳效果
    final wordCount = text.characters.length;
    double currentX = textOffset.dx;
    
    for (int i = 0; i < wordCount; i++) {
      final word = text.characters.elementAt(i);
      final wordSpan = TextSpan(text: word, style: style);
      final wordPainter = TextPainter(
        text: wordSpan,
        textDirection: TextDirection.ltr,
      );
      wordPainter.layout();
      
      // 弹跳曲线为衰减正弦波
      final wordProgress = (progress * wordCount + i) % wordCount / wordCount;
      final bounceHeight = 10.0 * sin(wordProgress * 4 * pi) * exp(-wordProgress * 3);
      
      final wordOffset = Offset(
        currentX,
        textOffset.dy - bounceHeight,
      );
      
      wordPainter.paint(canvas, wordOffset);
      currentX += wordPainter.width;
    }

    // 绘制下一句（灰色）
    final nextTextPainter = TextPainter(
      text: TextSpan(text: "下一句歌词", style: otherStyle),
      textDirection: TextDirection.ltr,
    );
    nextTextPainter.layout();
    nextTextPainter.paint(
      canvas,
      Offset(
        (size.width - nextTextPainter.width) / 2,
        size.height - nextTextPainter.height,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LyricsWordBouncePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}