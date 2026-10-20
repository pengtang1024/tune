import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/features/player/presentation/lyrics_panel.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/compact_spinner.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/source_chip.dart';
import 'package:tune/shared/ui/source_label.dart';
import 'package:tune/shared/ui/track_facts.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/shared/utils/duration_format.dart';

/// Full window view of the track that is playing right now.
///
/// The page is a route of its own instead of an overlay so it can be reached
/// from the dock, kept by the navigator and closed with the escape key.
class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  /// Whether the lyrics of the track are shown instead of its information.
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final sourceLabels = sourceLabelsOf(
      context.loc,
      ref.watch(
        musicSourcesControllerProvider.select(
          (value) => value.valueOrNull?.sources ?? const [],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            context.canPop() ? context.pop() : null,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                // The glow sits behind the middle of the page, where the
                // cover and the text are, instead of washing over one
                // corner of it. It fades to nothing, so the title keeps a
                // calm background to read on.
                center: const Alignment(0, -0.25),
                radius: 0.9,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CompactTokens.pageGutter,
                  CompactTokens.space16,
                  CompactTokens.pageGutter,
                  CompactTokens.space20,
                ),
                child: Column(
                  children: [
                    _TopBar(
                      state: state,
                      showLyrics: _showLyrics,
                      onToggleLyrics: () =>
                          setState(() => _showLyrics = !_showLyrics),
                    ),
                    const SizedBox(height: CompactTokens.space12),
                    Expanded(
                      child: state.currentSong == null
                          ? const _EmptyState()
                          : _TrackLayout(
                              state: state,
                              song: state.currentSong!,
                              showLyrics: _showLyrics,
                              source:
                                  sourceLabel(
                                    state.currentSong!,
                                    sourceLabels,
                                  ) ??
                                  SourceLabel(name: context.loc.sourceLocalName),
                              onPrevious: controller.previous,
                              onNext: controller.next,
                              onTogglePlay: controller.togglePlayPause,
                              onSeek: (value) => controller.seekTo(
                                Duration(
                                  milliseconds:
                                      (state.duration.inMilliseconds * value)
                                          .round(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: CompactTokens.space12),
                    _Footer(state: state),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header with the back action and the page title.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.showLyrics,
    required this.onToggleLyrics,
  });

  final PlaybackState state;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _RoundButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: context.loc.playerCollapse,
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc.playerNowPlaying,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_position > 0) ...[
              const SizedBox(height: 2),
              Text(
                context.loc.playerQueuePosition(_position),
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        _RoundButton(
          icon: showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined,
          tooltip: context.loc.playerLyrics,
          onPressed: onToggleLyrics,
        ),
        const SizedBox(width: 8),
        _RoundButton(
          icon: Icons.queue_music_rounded,
          tooltip: context.loc.queueTitle,
          onPressed: () => context.go('/queue'),
        ),
      ],
    );
  }

  /// Where the track sits in the queue, or zero when the queue holds nothing
  /// to point at.
  int get _position {
    final total = state.queue.length;
    if (!state.hasTrack || total < 2) return 0;
    final position = state.currentIndex + 1;
    return position > 0 && position <= total ? position : 0;
  }
}

/// Artwork and track information side by side.
class _TrackLayout extends StatelessWidget {
  const _TrackLayout({
    required this.state,
    required this.song,
    required this.showLyrics,
    required this.source,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
    required this.onSeek,
  });

  final PlaybackState state;
  final Song song;
  final bool showLyrics;
  final SourceLabel source;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The cover and the text are one block that sits in the middle of the
        // page. The empty room falls on both sides of it instead of piling
        // up on the right, and the text keeps the width it needs to read.
        final infoWidth = math.min(
          CompactTokens.nowPlayingInfoWidth,
          constraints.maxWidth * 0.46,
        );
        final artworkSize = math
            .min(
              constraints.maxHeight * 0.94,
              constraints.maxWidth * 0.40,
            )
            .clamp(120.0, CompactTokens.artworkNowPlaying);
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Artwork(song: song, size: artworkSize),
              const SizedBox(width: CompactTokens.nowPlayingGap),
              SizedBox(
                width: infoWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: showLyrics
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    if (showLyrics) ...[
                      Expanded(child: LyricsPanel(song: song)),
                      const SizedBox(height: CompactTokens.space12),
                    ] else ...[
                      Row(
                        children: [
                          SourceChip(label: source),
                          const SizedBox(width: CompactTokens.space8),
                          // The badge tells where the sound comes from, so it
                          // belongs next to the name of the source instead of
                          // floating at the far end of the seek bar.
                          AudioSourceBadge(
                            status: state.audioSourceStatus,
                            progress: state.downloadProgress,
                          ),
                        ],
                      ),
                      const SizedBox(height: CompactTokens.space16),
                      _Title(song: song),
                      const SizedBox(height: CompactTokens.space8),
                      _Artist(song: song),
                      const SizedBox(height: CompactTokens.space14),
                      _TrackDetails(song: song),
                      const SizedBox(height: CompactTokens.space18),
                    ],
                    _ProgressRow(state: state, onSeek: onSeek),
                    const SizedBox(height: CompactTokens.space18),
                    _Transport(
                      state: state,
                      onPrevious: onPrevious,
                      onNext: onNext,
                      onTogglePlay: onTogglePlay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The album cover with a soft shadow below it.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.song, required this.size});

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // The shadow stays wide and pale: a small dark one reads as a
          // second sheet of paper under the cover instead of as depth.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 44,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ArtworkThumb(
        path: song.albumArtPath,
        imageUrl: song.artworkUrl,
        size: size,
        radius: 20,
      ),
    );
  }
}

/// The track title.
class _Title extends StatelessWidget {
  const _Title({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      song.title.isEmpty ? context.loc.nowPlayingUnnamedTrack : song.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CompactTypography.asDisplay(
        theme.textTheme.displayMedium,
        size: CompactTypeScale.displayLarge,
        height: 1.06,
      ),
    );
  }
}

/// The artist line with the album and the year.
class _Artist extends StatelessWidget {
  const _Artist({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = song.artist.isEmpty
        ? context.loc.playerUnknownArtist
        : song.artist;
    final details = <String>[
      if (song.album.isNotEmpty) song.album,
      if (song.year != null) song.year.toString(),
    ];

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
/// The panel shows the value of a fact and keeps its name for the tooltip, so
/// the eye reads the values and the mouse names them.
class _TrackDetails extends StatelessWidget {
  const _TrackDetails({required this.song});

  final Song song;

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
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final fact in facts)
              MetaChip(
                icon: fact.icon,
                value: fact.value,
                tooltip: fact.sentence,
                tone: fact.tone,
              ),
          ],
        ),
      ],
    );
  }
}

/// The seek bar with the elapsed and the total time.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.state, required this.onSeek});

  final PlaybackState state;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final value = state.duration.inMilliseconds <= 0
        ? 0.0
        : (state.position.inMilliseconds / state.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    final isLive = state.currentSong?.isLiveStream ?? false;

    if (isLive) {
      return Row(
        children: [
          _TimeLabel(value: state.position),
          const SizedBox(width: CompactTokens.space12),
          const _LiveBadge(),
          const Spacer(),
        ],
      );
    }

    return Row(
      children: [
        _TimeLabel(value: state.position),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              onChanged: state.hasTrack ? onSeek : null,
            ),
          ),
        ),
        _TimeLabel(value: state.duration),
      ],
    );
  }
}

/// The mark that tells the user the track never ends.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;

    return TuneTooltip(
      message: context.loc.nowPlayingLiveStream,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.podcasts_rounded, size: CompactTokens.icon12, color: color),
            const SizedBox(width: 5),
            Text(
              context.loc.playerLiveBadge,
              style: CompactTypography.mono(
                color,
                size: CompactTypeScale.mark,
                weight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The elapsed or total time.
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.value});

  final Duration value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: Text(
        formatDuration(value),
        style: CompactTypography.mono(
          Theme.of(context).colorScheme.onSurfaceVariant,
          size: CompactTypeScale.mark,
        ),
      ),
    );
  }
}

/// The play, previous and next actions.
class _Transport extends StatelessWidget {
  const _Transport({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
  });

  final PlaybackState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      // The buttons sit in the middle of the column, under the middle of
      // the seek bar, so the eye finds the play button right away.
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: Icons.skip_previous_rounded,
          tooltip: context.loc.playerPrevious,
          size: CompactTokens.icon24,
          onPressed: state.hasTrack ? onPrevious : null,
        ),
        const SizedBox(width: CompactTokens.space10),
        SizedBox(
          width: 56,
          height: 56,
          child: IconButton.filled(
            tooltip: state.isPlaying
                ? context.loc.playerPause
                : context.loc.playerPlay,
            onPressed: state.hasTrack && !state.isLoading ? onTogglePlay : null,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.3,
              ),
              shape: const CircleBorder(),
            ),
            icon: state.isLoading
                ? CompactSpinner.medium(color: theme.colorScheme.onPrimary)
                : Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: CompactTokens.icon28,
                  ),
          ),
        ),
        const SizedBox(width: CompactTokens.space10),
        _RoundButton(
          icon: Icons.skip_next_rounded,
          tooltip: context.loc.playerNext,
          size: CompactTokens.icon24,
          onPressed: state.hasTrack ? onNext : null,
        ),
      ],
    );
  }
}

/// Bottom line with the queue summary.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final PlaybackState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text(
          'TUNE',
          style: CompactTypography.mono(
            muted,
            size: CompactTypeScale.mark,
            weight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.loc.playerQueueSummary(state.queue.length),
          style: CompactTypography.mono(
            muted,
            size: CompactTypeScale.mark,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (state.hasError && state.errorMessage != null)
          Flexible(
            child: Text(
              state.errorMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CompactTypography.mono(
                theme.colorScheme.error,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
      ],
    );
  }
}

/// Shown when nothing is playing yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: CompactTokens.illustrationLarge,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.loc.nowPlayingEmptyTitle,
            style: CompactTypography.asDisplay(
              theme.textTheme.titleMedium,
              size: CompactTypeScale.displayMedium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.loc.nowPlayingEmptySubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A round icon button used by the header and the transport.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TuneTooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: size,
            color: onPressed == null
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
