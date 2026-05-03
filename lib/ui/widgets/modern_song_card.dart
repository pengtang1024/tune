import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_song_card_utils.dart';

class ModernSongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;
  final bool isPlaying;
  final bool isSelected;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool showAlbumArt;
  final bool showArtist;
  final bool showAlbum;
  final bool showDuration;

  const ModernSongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onPlay,
    this.onMore,
    this.isPlaying = false,
    this.isSelected = false,
    this.width,
    this.height,
    this.margin,
    this.showAlbumArt = true,
    this.showArtist = true,
    this.showAlbum = false,
    this.showDuration = true,
  });

  factory ModernSongCard.compact({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      isPlaying: isPlaying,
      isSelected: isSelected,
      height: AppDesignSystem.albumCoverSize56,
      showAlbum: false,
      showDuration: false,
    );
  }

  factory ModernSongCard.list({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onMore,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      onMore: onMore,
      isPlaying: isPlaying,
      isSelected: isSelected,
      height: AppDesignSystem.albumCoverSize64,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
        vertical: AppDesignSystem.spacing4,
      ),
    );
  }

  factory ModernSongCard.grid({
    Key? key,
    required Song song,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onMore,
    bool isPlaying = false,
    bool isSelected = false,
  }) {
    return ModernSongCard(
      key: key,
      song: song,
      onTap: onTap,
      onPlay: onPlay,
      onMore: onMore,
      isPlaying: isPlaying,
      isSelected: isSelected,
      width: double.infinity,
      margin: const EdgeInsets.all(AppDesignSystem.spacing4),
      showAlbum: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height ?? AppDesignSystem.albumCoverSize64,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDesignSystem.borderRadius12,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignSystem.borderRadius12,
          splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
          highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: AppDesignSystem.duration200,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppDesignSystem.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: AppDesignSystem.borderRadius12,
              border: isSelected
                  ? Border.all(color: AppDesignSystem.primary, width: 2)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              child: Row(
                children: [
                  if (showAlbumArt) ...[
                    ModernSongCardUtils.buildAlbumArt(song, isDark, isPlaying, height),
                    const SizedBox(width: AppDesignSystem.spacing12),
                  ],
                  Expanded(
                    child: ModernSongCardUtils.buildMusicInfo(
                      song,
                      theme,
                      isPlaying,
                      showArtist,
                      showAlbum,
                      showDuration,
                    ),
                  ),
                  ModernSongCardUtils.buildControlButtons(theme, onPlay, onMore, isPlaying),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}