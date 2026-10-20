import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/playback_state.dart';
import 'package:tune/features/player/presentation/audio_source_badge.dart';
import 'package:tune/features/player/presentation/lyrics_panel.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/source_chip.dart';
import 'package:tune/shared/ui/source_label.dart';
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
    final sourceNames = sourceNamesOf(
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
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.72, -0.85),
                radius: 1.1,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                child: Column(
                  children: [
                    _TopBar(
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
                              sourceName:
                                  sourceLabel(
                                    state.currentSong!,
                                    sourceNames,
                                  ) ??
                                  context.loc.sourceLocalName,
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
  const _TopBar({required this.showLyrics, required this.onToggleLyrics});

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
            const SizedBox(height: 2),
            Text(
              context.loc.playerNowPlaying,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                letterSpacing: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
}

/// Artwork and track information side by side.
class _TrackLayout extends StatelessWidget {
  const _TrackLayout({
    required this.state,
    required this.song,
    required this.showLyrics,
    required this.sourceName,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlay,
    required this.onSeek,
  });

  final PlaybackState state;
  final Song song;
  final bool showLyrics;
  final String sourceName;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artworkSize = math
            .min(constraints.maxHeight * 0.98, constraints.maxWidth * 0.44)
            .clamp(150.0, 360.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Artwork(song: song, size: artworkSize),
            const SizedBox(width: 36),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: showLyrics
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (showLyrics) ...[
                    Expanded(child: LyricsPanel(song: song)),
                    const SizedBox(height: 12),
                  ] else ...[
                    SourceChip(label: sourceName),
                    const SizedBox(height: 16),
                    _Title(song: song),
                    const SizedBox(height: 8),
                    _Artist(song: song),
                    const SizedBox(height: 14),
                    _TrackDetails(song: song, sourceName: sourceName),
                    const SizedBox(height: 18),
                  ],
                  _ProgressRow(state: state, onSeek: onSeek),
                  const SizedBox(height: 18),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 16),
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
      style: theme.textTheme.displayMedium?.copyWith(
        fontFamily: 'Fraunces',
        fontSize: 36,
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
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9.5,
              letterSpacing: 0.4,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
class _TrackDetails extends StatelessWidget {
  const _TrackDetails({required this.song, required this.sourceName});

  final Song song;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final entries = _entries(context);
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.nowPlayingDetails,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 8.5,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final entry in entries)
              _DetailItem(label: entry.$1, value: entry.$2),
          ],
        ),
      ],
    );
  }

  /// The facts that are known about the track.
  List<(String, String)> _entries(BuildContext context) {
    final entries = <(String, String)>[];

    void add(String label, String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      entries.add((label, text));
    }

    add(context.loc.nowPlayingDetailAlbum, song.album);
    add(context.loc.nowPlayingDetailYear, song.year?.toString());
    add(context.loc.nowPlayingDetailGenre, _genre());
    add(context.loc.nowPlayingDetailBitrate, _bitrate());
    add(context.loc.nowPlayingDetailSampleRate, _sampleRate());
    add(context.loc.nowPlayingDetailTrack, _track());
    add(context.loc.nowPlayingDetailDisc, _disc());
    add(context.loc.language, song.language);
    add(context.loc.nowPlayingDetailLicense, song.license);
    add(context.loc.nowPlayingDetailNowPlaying, _onAir());
    add(context.loc.nowPlayingDetailSource, sourceName);

    return entries;
  }

  String? _genre() {
    final genres = song.genres;
    if (genres != null && genres.isNotEmpty) return genres.join(' / ');
    return song.genre;
  }

  String? _bitrate() {
    final bitrate = song.bitrate;
    if (bitrate == null || bitrate <= 0) return null;
    return '$bitrate kbps';
  }

  String? _sampleRate() {
    final rate = song.sampleRate;
    if (rate == null || rate <= 0) return null;
    final kilohertz = rate / 1000;
    return kilohertz == kilohertz.roundToDouble()
        ? '${kilohertz.toInt()} kHz'
        : '${kilohertz.toStringAsFixed(1)} kHz';
  }

  String? _track() {
    final number = song.trackNumber;
    if (number == null || number <= 0) return null;
    final total = song.trackTotal;
    return total != null && total > 0 ? '$number / $total' : '$number';
  }

  String? _disc() {
    final number = song.discNumber;
    if (number == null || number <= 0) return null;
    final total = song.totalDisc;
    return total != null && total > 0 ? '$number / $total' : '$number';
  }

  /// The track a station is playing right now.
  String? _onAir() {
    final nowPlaying = song.sourceData?['nowPlaying']?.toString() ?? '';
    return nowPlaying.isEmpty ? null : nowPlaying;
  }
}

/// One fact of the track, written as `label value`.
class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9.5,
              letterSpacing: 0.3,
              color: muted.withValues(alpha: 0.75),
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9.5,
              letterSpacing: 0.3,
              color: muted,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 10),
          const _LiveBadge(),
          const Spacer(),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: AudioSourceBadge(
                status: state.audioSourceStatus,
                progress: state.downloadProgress,
              ),
            ),
          ),
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
        const SizedBox(width: 4),
        SizedBox(
          width: 92,
          child: Align(
            alignment: Alignment.centerRight,
            child: AudioSourceBadge(
              status: state.audioSourceStatus,
              progress: state.downloadProgress,
            ),
          ),
        ),
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

    return Tooltip(
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
            Icon(Icons.podcasts_rounded, size: 11, color: color),
            const SizedBox(width: 5),
            Text(
              context.loc.playerLiveBadge,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: color,
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
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      children: [
        _RoundButton(
          icon: Icons.skip_previous_rounded,
          tooltip: context.loc.playerPrevious,
          size: 24,
          onPressed: state.hasTrack ? onPrevious : null,
        ),
        const SizedBox(width: 10),
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
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          icon: Icons.skip_next_rounded,
          tooltip: context.loc.playerNext,
          size: 24,
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
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Row(
      children: [
        Text(
          'TUNE',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: muted,
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
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            letterSpacing: 0.8,
            color: muted,
          ),
        ),
        const Spacer(),
        if (state.hasError && state.errorMessage != null)
          Flexible(
            child: Text(
              state.errorMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9.5,
                color: theme.colorScheme.error,
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
            size: 44,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.loc.nowPlayingEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Fraunces',
              fontSize: 22,
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
    return Tooltip(
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
