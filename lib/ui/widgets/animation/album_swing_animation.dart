import 'dart:math';

import 'package:flutter/material.dart';

import 'themed_animation_base.dart';

class AlbumSwingAnimation extends ThemedAnimationBase {
  const AlbumSwingAnimation({super.key});

  @override
  State<AlbumSwingAnimation> createState() => _AlbumSwingAnimationState();
}

class _AlbumSwingAnimationState extends ThemedAnimationStateBase<AlbumSwingAnimation> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 3));
    repeatAnimation();

    _animation = Tween<double>(begin: -pi/6, end: pi/6).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.album,
                color: theme.colorScheme.onPrimaryContainer,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}
