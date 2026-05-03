import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class ModernSongCardUtils {
  static Widget buildAlbumArt(
    Song song,
    bool isDark,
    bool isPlaying,
    double? height,
  ) {
    return Container(
      width: height ?? AppDesignSystem.albumCoverSize48,
      height: height ?? AppDesignSystem.albumCoverSize48,
      decoration: BoxDecoration(
        borderRadius: AppDesignSystem.borderRadius8,
        gradient: AppDesignSystem.primaryGradient,
        boxShadow: isPlaying ? AppDesignSystem.shadowColored : AppDesignSystem.shadowLight,
      ),
      child: Stack(
        children: [
          Center(
            child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppDesignSystem.borderRadius8,
                    child: Image.file(
                      File(song.albumArtPath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAlbumArt();
                      },
                      cacheWidth: 200,
                      cacheHeight: 200,
                    ),
                  )
                : _buildDefaultAlbumArt(),
          ),
          if (isPlaying)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: AppDesignSystem.borderRadius8,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppDesignSystem.iconSize32,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildDefaultAlbumArt() {
    return Icon(
      Icons.album_rounded,
      color: Colors.white.withValues(alpha: 0.8),
      size: AppDesignSystem.iconSize32,
    );
  }

  static Widget buildMusicInfo(
    Song song,
    ThemeData theme,
    bool isPlaying,
    bool showArtist,
    bool showAlbum,
    bool showDuration,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          song.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightMedium,
            color: isPlaying
                ? AppDesignSystem.primary
                : (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDesignSystem.spacing2),
        if (showArtist)
          Text(
            song.artist,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (showAlbum || showDuration) ...[
          const SizedBox(height: AppDesignSystem.spacing2),
          Row(
            children: [
              if (showAlbum) ...[
                Expanded(
                  child: Text(
                    song.album,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral500,
                      fontSize: AppDesignSystem.fontSize11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (showDuration) ...[
                if (showAlbum) const SizedBox(width: AppDesignSystem.spacing8),
                Text(
                  formatDuration(Duration(milliseconds: song.duration)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral500,
                    fontSize: AppDesignSystem.fontSize11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  static Widget buildControlButtons(
    ThemeData theme,
    VoidCallback? onPlay,
    VoidCallback? onMore,
    bool isPlaying,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPlay != null)
          Container(
            margin: const EdgeInsets.only(right: AppDesignSystem.spacing4),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppDesignSystem.borderRadius20,
              child: InkWell(
                onTap: onPlay,
                borderRadius: AppDesignSystem.borderRadius20,
                child: Container(
                  width: AppDesignSystem.iconSize32,
                  height: AppDesignSystem.iconSize32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: AppDesignSystem.iconSize20,
                    color: AppDesignSystem.primary,
                  ),
                ),
              ),
            ),
          ),
        if (onMore != null)
          Material(
            color: Colors.transparent,
            borderRadius: AppDesignSystem.borderRadius20,
            child: InkWell(
              onTap: onMore,
              borderRadius: AppDesignSystem.borderRadius20,
              child: SizedBox(
                width: AppDesignSystem.iconSize32,
                height: AppDesignSystem.iconSize32,
                child: Icon(
                  Icons.more_vert_rounded,
                  size: AppDesignSystem.iconSize20,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}