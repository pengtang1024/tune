import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class AudioVisualizer extends ConsumerStatefulWidget {
  final int barCount;
  final double height;

  const AudioVisualizer({super.key, this.barCount = 24, this.height = 40});

  @override
  ConsumerState<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends ConsumerState<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateNotifierProvider);

    if (playerState.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!playerState.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }

    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.barCount > 30 ? 1.0 : 1.5),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final amplitude = playerState.isPlaying
                      ? (0.3 + 0.7 * _random.nextDouble() * (1 - (index / widget.barCount)))
                      : 0.1;
                  return Container(
                    height: widget.height * amplitude,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppDesignSystem.primary,
                          AppDesignSystem.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.barCount > 30 ? 1 : 2),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
