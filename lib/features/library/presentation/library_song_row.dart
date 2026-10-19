import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/utils/duration_format.dart';

class LibrarySongRow extends StatelessWidget {
  final Song song;
  final int index;
  final bool selected;
  final bool playing;
  final String? sourceName;
  final VoidCallback onTap;
  final VoidCallback onAddToQueue;

  const LibrarySongRow({
    super.key,
    required this.song,
    required this.index,
    required this.selected,
    required this.playing,
    this.sourceName,
    required this.onTap,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Container(
        height: CompactTokens.rowHeight,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 2,
              height: double.infinity,
              color: selected ? theme.colorScheme.primary : Colors.transparent,
            ),
            const SizedBox(width: CompactTokens.space8),
            SizedBox(
              width: 22,
              child: Center(
                child: selected
                    ? Icon(
                        playing
                            ? Icons.equalizer_rounded
                            : Icons.play_arrow_rounded,
                        size: CompactTokens.icon16,
                        color: theme.colorScheme.primary,
                      )
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: CompactTokens.space8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title.isEmpty ? '未知歌曲' : song.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist.isEmpty ? '未知艺术家' : song.artist,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (sourceName != null) ...[
              const SizedBox(width: CompactTokens.space6),
              Tooltip(
                message: sourceName!,
                child: Icon(
                  Icons.public_rounded,
                  size: 12,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(width: CompactTokens.space8),
            Text(
              formatDuration(Duration(milliseconds: song.durationInMillis)),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: PopupMenuButton<String>(
                tooltip: '更多操作',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: CompactTokens.icon18,
                  color: muted,
                ),
                onSelected: (_) => onAddToQueue(),
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'queue',
                    height: 36,
                    child: Text('加入播放队列'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CompactTokens.space4),
          ],
        ),
      ),
    );
  }
}
