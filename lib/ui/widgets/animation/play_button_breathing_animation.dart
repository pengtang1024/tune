import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class PlayButtonBreathingAnimation extends ThemedAnimationBase {
  const PlayButtonBreathingAnimation({super.key});

  @override
  State<PlayButtonBreathingAnimation> createState() =>
      _PlayButtonBreathingAnimationState();
}

class _PlayButtonBreathingAnimationState
    extends ThemedAnimationStateBase<PlayButtonBreathingAnimation> {
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 2));
    repeatReverseAnimation();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
