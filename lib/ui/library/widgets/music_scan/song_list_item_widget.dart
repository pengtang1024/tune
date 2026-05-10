import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class SongListItemWidget extends StatelessWidget {
  final Song song;
  final String durationText;
  final VoidCallback? onPlay;

  const SongListItemWidget({
    super.key,
    required this.song,
    this.durationText = '',
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing4),
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12, vertical: AppDesignSystem.spacing10),
      onTap: onPlay,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppDesignSystem.primaryGradient,
              borderRadius: AppDesignSystem.borderRadius8,
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: AppDesignSystem.iconSize24),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: AppDesignSystem.textTheme.bodyMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${song.artist} · ${song.album}',
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Text(
            durationText,
            style: AppDesignSystem.textTheme.bodySmall?.copyWith(
              color: AppDesignSystem.neutral400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
