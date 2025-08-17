import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class PlayPauseRotationAnimation extends ThemedAnimationBase {
  const PlayPauseRotationAnimation({super.key});

  @override
  State<PlayPauseRotationAnimation> createState() =>
      _PlayPauseRotationAnimationState();
}

class _PlayPauseRotationAnimationState
    extends ThemedAnimationStateBase<PlayPauseRotationAnimation> {
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(milliseconds: 600));
    repeatReverseAnimation();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
