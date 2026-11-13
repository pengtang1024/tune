import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/localization/domain/text_language.dart';
import 'package:tune/features/player/domain/audio_source_status.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/shared/ui/bilingual_text.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/source_badge.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// The words of the track that is playing.
///
/// The block names the source of the sound, the track, the artist and the
/// facts the source published, and it scrolls when the room is too short
/// for all of it.
///
/// The scroll is the point of the block. The desktop has a text scale of
/// its own, and a user who raises it gets words that are a third taller
/// than the window was built for. The page keeps its progress bar and its
/// buttons in sight and lets the words give way, instead of running them
/// over the edge of the window.
class NowPlayingTrackInfo extends ConsumerWidget {
  const NowPlayingTrackInfo({
    super.key,
    required this.song,
    required this.source,
    required this.status,
  });

  final Song song;
  final SourceLabel source;
  final AudioSourceStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The facts read the mark of this track alone; a mark put on another
    // track does not touch them.
    final isFavorite = ref.watch(
      favoritesControllerProvider.select(
        (state) => state.contains(song.uri),
      ),
    );

    void toggleFavorite() {
      ref.read(favoritesControllerProvider.notifier).toggle(song.uri);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SourceBadge(
                label: source,
                dense: false,
                onTap: () => showTrackDetailSheet(
                  context,
                  song,
                  source: source,
                  isFavorite: isFavorite,
                  onToggleFavorite: toggleFavorite,
                ),
              ),
              const SizedBox(width: CompactTokens.space8),
              // The badge tells where the sound comes from, so it belongs
              // next to the name of the source instead of floating at the
              // far end of the seek bar.
              AudioSourceBadge(status: status),
            ],
          ),
          const SizedBox(height: CompactTokens.space16),
          _Title(song: song),
          const SizedBox(height: CompactTokens.space8),
          _Artist(song: song),
          const SizedBox(height: CompactTokens.space14),
          _TrackDetails(
            song: song,
            source: source,
            isFavorite: isFavorite,
            onToggleFavorite: toggleFavorite,
          ),
        ],
      ),
    );
  }
}

/// The track title, translated when the reader asked for it.
class _Title extends ConsumerWidget {
  const _Title({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final original = song.title.isEmpty
        ? context.loc.nowPlayingUnnamedTrack
        : song.title;
    final target = targetLanguageOf(Localizations.localeOf(context));
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    final translation = ref
        .watch(
          translatedTextProvider((
            text: original,
            targetLanguage: target,
          )),
        )
        .value;
    final style = CompactTypography.asDisplay(
      theme.textTheme.displayMedium,
      size: CompactTypeScale.displayLarge,
      height: 1.06,
    );
    if (translation == null || translation == original) {
      return Text(
        original,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return BilingualText(
      primary: translation,
      secondary: config.showOriginal ? original : null,
      maxLines: 2,
      primaryStyle: style,
    );
  }
}

/// The artist line with the album and the year.
class _Artist extends ConsumerWidget {
  const _Artist({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // A station publishes what it is airing, not who made the stream: the
    // line says so instead of passing the on-air song off as the artist.
    if (song.isLiveStream) {
      final onAir = onAirLineOf(context, song);
      if (onAir == null) return const SizedBox.shrink();
      return Text(
        onAir,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final artist = song.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final target = targetLanguageOf(Localizations.localeOf(context));
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    final translatedAlbum = song.album.isEmpty
        ? null
        : ref
              .watch(
                translatedTextProvider((
                  text: song.album,
                  targetLanguage: target,
                )),
              )
              .value;
    final album = translatedAlbum ?? song.album;
    final details = <String>[
      if (album.isNotEmpty) album,
      if (song.year != null) song.year.toString(),
    ];
    final originalDetails =
        translatedAlbum != null && config.showOriginal && song.album.isNotEmpty
        ? <String>[
            song.album,
            if (song.year != null) song.year.toString(),
          ].join('  ·  ')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            details.join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CompactTypography.mono(
              theme.colorScheme.onSurfaceVariant,
              size: CompactTypeScale.mark,
              letterSpacing: 0.4,
            ),
          ),
          if (originalDetails != null) ...[
            const SizedBox(height: 2),
            Text(
              originalDetails,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// The facts the source published about the track.
///
/// Every source knows different things about a track, so the panel shows
/// whatever is known: the album, the year, the style, the quality of the
/// file, the licence and the station that plays it.
///
/// The facts are icons, not words: a row of facts keeps the same shape
/// whatever the values are. The mouse names a fact and the details panel
/// writes all of them down.
class _TrackDetails extends StatelessWidget {
  const _TrackDetails({
    required this.song,
    required this.source,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Song song;
  final SourceLabel? source;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final facts = trackFactsOf(context, song);
    if (facts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.nowPlayingDetails,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
            weight: FontWeight.w500,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in facts)
              MetaBadge(
                icon: fact.icon,
                tooltip: fact.sentence,
                tone: fact.tone,
                size: 15,
                onTap: () => showTrackDetailSheet(
                  context,
                  song,
                  source: source,
                  isFavorite: isFavorite,
                  onToggleFavorite: onToggleFavorite,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
