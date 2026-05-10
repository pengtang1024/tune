import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class SongInfoWidget extends ConsumerWidget {
  final Song song;
  final int? index;

  const SongInfoWidget({super.key, required this.song, this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playCount = ref.watch(playStatsServiceProvider).getPlayCount(song.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (index != null) ...[
              Text('${index! + 1}.', style: AppDesignSystem.textTheme.bodySmall?.copyWith(color: AppDesignSystem.neutral400)),
              const SizedBox(width: AppDesignSystem.spacing6),
            ],
            Expanded(
              child: Text(
                song.title,
                style: AppDesignSystem.textTheme.bodyMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            if (playCount > 0) ...[
              const SizedBox(width: AppDesignSystem.spacing6),
              Icon(Icons.play_circle_outline, size: 12, color: AppDesignSystem.neutral400),
              const SizedBox(width: 2),
              Text('$playCount', style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: AppDesignSystem.neutral400, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
            const SizedBox(width: AppDesignSystem.spacing6),
            Text(
              _formatDuration(song.duration),
              style: AppDesignSystem.textTheme.bodySmall?.copyWith(color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral500, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${song.artist} · ${song.album}',
          style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral500),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final d = Duration(milliseconds: milliseconds);
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
