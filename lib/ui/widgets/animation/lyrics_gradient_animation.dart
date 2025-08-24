import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class LyricsGradientAnimation extends ThemedAnimationBase {
  const LyricsGradientAnimation({super.key});

  @override
  State<LyricsGradientAnimation> createState() =>
      _LyricsGradientAnimationState();
}

class _LyricsGradientAnimationState
    extends ThemedAnimationStateBase<LyricsGradientAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _LyricsGradientWidget(progress: _animation.value, theme: theme);
      },
    );
  }
}

class _LyricsGradientWidget extends StatelessWidget {
  final double progress;
  final ThemeData theme;

  const _LyricsGradientWidget({required this.progress, required this.theme});

  @override
  Widget build(BuildContext context) {
    const text = "当前播放歌词行";
    final normalStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 14,
    );

    final highlightStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    return Stack(
      children: [
        // 绘制普通文本
        Text(text, style: normalStyle),
        // 绘制渐变遮罩
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [theme.colorScheme.onSurface, theme.colorScheme.primary],
              stops: [0.0, progress],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Text(text, style: highlightStyle),
        ),
      ],
    );
  }
}
