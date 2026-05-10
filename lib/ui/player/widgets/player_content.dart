import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/player/states/play_mode.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class PlayerContent extends ConsumerWidget {
  const PlayerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);

    return Column(
      children: [
        const SizedBox(height: AppDesignSystem.spacing24),
        const _AlbumArt().withScaleIn(),
        const SizedBox(height: AppDesignSystem.spacing32),
        _SongInfo(
          title: playerState.currentSong?.title ?? '未知歌曲',
          artist: playerState.currentSong?.artist ?? '未知艺术家',
          album: playerState.currentSong?.album ?? '未知专辑',
        ).withSlideIn(delay: const Duration(milliseconds: 150)),
        const SizedBox(height: AppDesignSystem.spacing32),
        const _PlayerControlsRow().withFadeIn(delay: const Duration(milliseconds: 250)),
        const SizedBox(height: AppDesignSystem.spacing24),
        const _PlayModeControl().withFadeIn(delay: const Duration(milliseconds: 350)),
      ],
    );
  }
}

class _AlbumArt extends ConsumerStatefulWidget {
  const _AlbumArt();

  @override
  ConsumerState<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends ConsumerState<_AlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < AppDesignSystem.breakpointMobile;
    final artSize = isCompact
        ? AppDesignSystem.albumCoverSize200
        : AppDesignSystem.albumCoverSize240;

    final artPath = playerState.currentSong?.albumArtPath;

    return AnimatedContainer(
      duration: AppDesignSystem.duration300,
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        borderRadius: AppDesignSystem.borderRadius24,
        boxShadow: AppDesignSystem.shadowColored,
      ),
      child: ClipRRect(
        borderRadius: AppDesignSystem.borderRadius24,
        child: artPath != null && artPath.isNotEmpty
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: Image.file(
                  File(artPath),
                  width: artSize,
                  height: artSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultArt(),
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    if (frame == null) {
                      return _defaultArt();
                    }
                    _fadeController.forward();
                    return child;
                  },
                ),
              )
            : _defaultArt(),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppDesignSystem.primaryGradient,
      ),
      child: const Icon(
        Icons.music_note_rounded,
        size: AppDesignSystem.iconSize80,
        color: Colors.white,
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final String title;
  final String artist;
  final String album;

  const _SongInfo({
    required this.title,
    required this.artist,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          title,
          style: AppDesignSystem.textTheme.headlineMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          '$artist — $album',
          style: AppDesignSystem.textTheme.titleMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PlayerControlsRow extends StatelessWidget {
  const _PlayerControlsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        PlayerVolume(),
        SizedBox(width: AppDesignSystem.spacing32),
        PlayerSpeed(),
      ],
    );
  }
}

class _PlayModeControl extends ConsumerWidget {
  const _PlayModeControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final loc = context.loc;

    IconData getModeIcon() {
      switch (playerState.playMode) {
        case PlayMode.shuffle:
          return Icons.shuffle;
        case PlayMode.repeatOne:
          return Icons.repeat_one;
        default:
          return Icons.repeat;
      }
    }

    String getModeTooltip() {
      switch (playerState.playMode) {
        case PlayMode.shuffle:
          return loc.shuffle;
        case PlayMode.repeatOne:
          return loc.repeat_one;
        default:
          return loc.repeat_all;
      }
    }

    return AppInteractions.pressableScale(
      onTap: playerNotifier.togglePlayMode,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing20,
          vertical: AppDesignSystem.spacing12,
        ),
        decoration: BoxDecoration(
          color: AppDesignSystem.primary.withValues(alpha: 0.08),
          borderRadius: AppDesignSystem.borderRadius16,
          border: Border.all(
            color: AppDesignSystem.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getModeTooltip(),
              style: AppDesignSystem.textTheme.labelLarge?.copyWith(
                color: AppDesignSystem.primary,
                fontWeight: AppDesignSystem.fontWeightMedium,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Icon(getModeIcon(), color: AppDesignSystem.primary),
          ],
        ),
      ),
    );
  }
}
