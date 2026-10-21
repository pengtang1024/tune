import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// What a trial of a source brought.
///
/// The reader sees the tracks the answer holds before the source is kept, so
/// a wrong path shows up here as a wrong title and not as an empty library.
class SourcePreviewPanel extends StatelessWidget {
  const SourcePreviewPanel({
    super.key,
    required this.running,
    this.preview,
  });

  /// Whether a trial is running.
  final bool running;

  /// What the last trial brought.
  final SourcePreview? preview;

  @override
  Widget build(BuildContext context) {
    if (running) {
      return _Note(text: context.loc.sourcePreviewRunning);
    }

    final preview = this.preview;
    if (preview == null) return const SizedBox.shrink();

    if (preview.message != null) {
      return _Note(text: preview.message!);
    }

    return _Tracks(songs: preview.songs);
  }
}

/// A line of text that says how the trial went.
class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CompactTokens.space8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Text(
        text,
        style: CompactTypography.sans(
          theme.colorScheme.onSurfaceVariant,
          size: CompactTypeScale.body,
        ),
      ),
    );
  }
}

/// The tracks a trial found.
class _Tracks extends StatelessWidget {
  const _Tracks({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CompactTokens.space8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.sourcePreviewTracks(songs.length),
            style: CompactTypography.sans(
              theme.colorScheme.onSurfaceVariant,
              size: CompactTypeScale.label,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CompactTokens.space6),
          for (final song in songs.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: CompactTokens.space4),
              child: Text(
                _lineOf(song),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CompactTypography.sans(
                  theme.colorScheme.onSurface,
                  size: CompactTypeScale.body,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The title of a track and the one who made it.
  String _lineOf(Song song) {
    final artist = song.artist;
    if (artist.isEmpty) return song.title;
    return '${song.title} — $artist';
  }
}
