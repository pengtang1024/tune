import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';

/// Height of one lyric line.
const _lineExtent = 30.0;

/// Shows the lyrics of a track and follows the playback.
///
/// The lyrics are only fetched when the panel is opened, so a scan never pays
/// for them.
class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({required this.song, super.key});

  final Song song;

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final ScrollController _scroll = ScrollController();
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _activeIndex = -1;
      _load();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(lyricsControllerProvider.notifier).load(widget.song);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricsControllerProvider);
    final position = ref.watch(
      playbackControllerProvider.select((state) => state.position),
    );

    if (lyrics.loading) {
      return _Message(
        text: context.loc.lyricsLoading,
        icon: Icons.hourglass_empty_rounded,
      );
    }
    if (lyrics.failed) {
      return _Message(
        text: context.loc.lyricsFailed,
        icon: Icons.error_outline_rounded,
      );
    }
    if (!lyrics.hasLyrics) {
      return _Message(
        text: context.loc.lyricsMissing,
        icon: Icons.lyrics_outlined,
      );
    }

    final document = lyrics.document!;
    final active = document.indexAt(position);
    if (active != _activeIndex) {
      _activeIndex = active;
      _scrollTo(active);
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: CompactTokens.space8),
      itemExtent: _lineExtent,
      itemCount: document.lines.length,
      itemBuilder: (context, index) {
        final line = document.lines[index];
        final isActive = index == active;
        return _LyricLine(line: line.text, active: isActive);
      },
    );
  }

  /// Keeps the sung line in the middle of the panel.
  void _scrollTo(int index) {
    if (index < 0 || !_scroll.hasClients) return;
    final target =
        (index * _lineExtent - _scroll.position.viewportDimension / 2).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }
}

/// One line of the lyric sheet.
class _LyricLine extends StatelessWidget {
  const _LyricLine({required this.line, required this.active});

  final String line;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      line,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: active ? CompactTypeScale.heading : CompactTypeScale.strong,
        height: 1.2,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Placeholder shown while there is nothing to read.
class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: CompactTokens.icon20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: CompactTokens.space6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
