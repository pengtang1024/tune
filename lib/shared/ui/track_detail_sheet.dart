import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/track_address_row.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// Shows everything that is known about a track.
///
/// The sheet is the one place where all the facts of a track stand together,
/// so a reader can look a track up instead of guessing what it is.
Future<void> showTrackDetailSheet(
  BuildContext context,
  Song song, {
  SourceLabel? source,
}) {
  return showCompactSheet<void>(
    context,
    (context) => _TrackDetailSheet(song: song, source: source),
  );
}

class _TrackDetailSheet extends StatelessWidget {
  final Song song;
  final SourceLabel? source;

  const _TrackDetailSheet({required this.song, this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = trackFactsOf(context, song, source: source);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CompactTokens.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space20,
          CompactTokens.space16,
          CompactTokens.space20,
          CompactTokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(song: song),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final fact in facts)
                  MetaChip(
                    icon: fact.icon,
                    label: fact.label,
                    value: fact.value,
                    tone: fact.tone,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _Addresses(song: song),
          ],
        ),
      ),
    );
  }
}

/// The addresses of the track: the file it lives in and the address it is
/// played from.
///
/// A track that was fetched has both: the copy on this machine and the
/// address of the source it came from.
class _Addresses extends StatelessWidget {
  final Song song;

  const _Addresses({required this.song});

  @override
  Widget build(BuildContext context) {
    final file = song.localFile;
    final online = song.onlineAddress;
    if (file == null && online == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (file != null) ...[
          TrackAddressRow(
            address: file,
            label: context.loc.trackFactPath,
            copyHint: context.loc.trackDetailsCopyPath,
          ),
          if (online != null) const SizedBox(height: 14),
        ],
        if (online != null)
          TrackAddressRow(
            address: online,
            label: context.loc.trackFactAddress,
            copyHint: context.loc.trackDetailsCopyAddress,
          ),
      ],
    );
  }
}

/// The track the sheet belongs to.
class _Header extends StatelessWidget {
  final Song song;

  const _Header({required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtworkThumb(
          path: song.albumArtPath,
          imageUrl: song.artworkUrl,
          size: CompactTokens.artworkHero,
          radius: 12,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title.isEmpty ? context.loc.trackUnknownTitle : song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CompactTypography.asDisplay(
                  theme.textTheme.titleMedium,
                  size: CompactTypeScale.displaySmall,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist.isEmpty
                    ? context.loc.playerUnknownArtist
                    : song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
