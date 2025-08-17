import 'package:flutter/material.dart';
import 'dart:math';
import 'themed_animation_base.dart';

class AlbumRotationAnimation extends ThemedAnimationBase {
  const AlbumRotationAnimation({super.key});

  @override
  State<AlbumRotationAnimation> createState() => _AlbumRotationAnimationState();
}

class _AlbumRotationAnimationState extends ThemedAnimationStateBase<AlbumRotationAnimation> {
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    initAnimationController(const Duration(seconds: 4));
    repeatAnimation();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi, // 360度
    ).animate(controller);
  }

  @override
  Widget buildAnimationContent(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.onPrimaryContainer, width: 2),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}