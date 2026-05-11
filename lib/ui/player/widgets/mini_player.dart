import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);

    if (playerState.currentSong == null) {
      return const SizedBox.shrink();
    }

    final song = playerState.currentSong!;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AppInteractions.clickableCard(
          borderRadius: BorderRadius.zero,
          onTap: () => context.push('/player'),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildArtwork(song.albumArtPath),
                const SizedBox(width: AppDesignSystem.spacing12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                          fontWeight: AppDesignSystem.fontWeightSemiBold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${song.artist} - ${song.album}',
                        style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildControls(playerState, playerNotifier),
                if (playerState.isPlaying)
                  const SizedBox(width: AppDesignSystem.spacing4),
                if (playerState.isPlaying)
                  SizedBox(width: 32, child: _MiniVisualizer(isPlaying: playerState.isPlaying)),
                const SizedBox(width: AppDesignSystem.spacing8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(String? albumArt) {
    if (albumArt != null && albumArt.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Image.file(
          File(albumArt),
          width: 64, height: 64, fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildDefaultArtwork(),
        ),
      );
    }
    return _buildDefaultArtwork();
  }

  Widget _buildDefaultArtwork() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: AppDesignSystem.iconSize32),
    );
  }

  Widget _buildControls(dynamic playerState, dynamic playerNotifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: playerState.isPlaying
              ? () { HapticFeedback.lightImpact(); playerNotifier.pause(); }
              : () { HapticFeedback.lightImpact(); playerNotifier.play(); },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppDesignSystem.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: AppDesignSystem.iconSize24,
              color: AppDesignSystem.primary,
            ),
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing4),
        AppInteractions.pressableScale(
          scaleValue: 0.9,
          onTap: playerNotifier.next,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.skip_next,
              size: AppDesignSystem.iconSize24,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniVisualizer extends StatefulWidget {
  final bool isPlaying;
  const _MiniVisualizer({required this.isPlaying});

  @override
  State<_MiniVisualizer> createState() => _MiniVisualizerState();
}

class _MiniVisualizerState extends State<_MiniVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MiniVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barCount = 5;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(barCount, (i) {
            final h = widget.isPlaying
                ? 6.0 + 12.0 * _random.nextDouble()
                : 3.0;
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppDesignSystem.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
