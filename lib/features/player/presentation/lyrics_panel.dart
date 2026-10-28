import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';
import 'package:tune/utils/logger.dart';

/// Height of one lyric line.
const _lineExtent = 30.0;

/// Shows the lyrics of the track that plays and follows the playback.
///
/// The lyrics are only fetched when the panel is opened, so a scan never pays
/// for them.
class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({super.key});

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricsControllerProvider);
    final song = ref.watch(
      playbackControllerProvider.select((state) => state.currentSong),
    );
    final active = ref.watch(activeLyricLineProvider);

    // The line that is sung changed: the panel follows it.
    ref.listen<int>(activeLyricLineProvider, (previous, next) {
      if (next != previous) _scrollTo(next);
    });

    if (song == null) {
      return _Message(
        text: context.loc.lyricsNothingPlaying,
        icon: Icons.music_note_rounded,
      );
    }

    if (lyrics.hasError) {
      return _Message(
        text: context.loc.lyricsFailed,
        icon: Icons.error_outline_rounded,
        actions: [
          _Action(label: context.loc.lyricsRetry, onPressed: () => _reload(song)),
          _Action(
            label: context.loc.lyricsChooseFile,
            onPressed: () => _chooseFile(song),
          ),
        ],
      );
    }

    final answer = lyrics.valueOrNull;
    // The answer of the track that plays, not the one of the track before it.
    final current = answer != null && answer.songId == song.id ? answer : null;

    if (current != null && current.hasLyrics) {
      final document = current.document!;
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: CompactTokens.space8),
        itemExtent: _lineExtent,
        itemCount: document.lines.length,
        itemBuilder: (context, index) {
          final line = document.lines[index];
          return _LyricLine(line: line.text, active: index == active);
        },
      );
    }

    if (current != null && current.invalid) {
      return _Message(
        text: context.loc.lyricsInvalidFile,
        icon: Icons.description_outlined,
        actions: [
          _Action(
            label: context.loc.lyricsChooseFile,
            onPressed: () => _chooseFile(song),
          ),
        ],
      );
    }

    if (current == null && lyrics.isLoading) {
      return _Message(
        text: context.loc.lyricsLoading,
        icon: Icons.hourglass_empty_rounded,
      );
    }

    return _Message(
      text: context.loc.lyricsMissing,
      icon: Icons.lyrics_outlined,
      actions: [
        _Action(label: context.loc.lyricsSearchAgain, onPressed: () => _reload(song)),
        _Action(
          label: context.loc.lyricsChooseFile,
          onPressed: () => _chooseFile(song),
        ),
        _generateAction(context),
      ],
    );
  }

  /// The door of the smart pipeline: greyed until a key sits in the
  /// settings, and then the single-song loop of M2 answers the press.
  _Action _generateAction(BuildContext context) {
    final configured = ref.watch(
      settingsControllerProvider.select((state) => state.smartLyrics.isConfigured),
    );
    return _Action(
      label: context.loc.lyricsSmartGenerate,
      // The press is wired with the single-song loop of M2; until then a
      // reachable press says so in the log.
      onPressed: () => Log.info('智能生成的单曲闭环在 M2 接线'),
      enabled: configured,
      tooltip: configured ? null : context.loc.lyricsSmartGenerateNeedsKey,
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

  /// Asks for the lyrics of the track again.
  void _reload(Song song) {
    unawaited(ref.read(lyricsControllerProvider.notifier).reload(song));
  }

  /// Lets the reader bring the lyrics of the track from a file.
  Future<void> _chooseFile(Song song) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['lrc', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    final attached = await ref
        .read(lyricsControllerProvider.notifier)
        .attach(song, bytes);
    if (!attached || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.loc.lyricsAttached)),
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
    // The sung line takes the step above the others, so the eye finds it
    // without reading the words first.
    final style = active
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;

    return Text(
      line,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(
        height: 1.2,
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// One thing the reader can do when there are no lyrics to show.
class _Action {
  const _Action({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.tooltip,
  });

  final String label;
  final VoidCallback onPressed;

  /// Whether the action can answer a press; a greyed one explains itself
  /// in [tooltip] instead.
  final bool enabled;
  final String? tooltip;
}

/// Placeholder shown while there is nothing to read.
class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon, this.actions = const []});

  final String text;
  final IconData icon;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: CompactTokens.icon20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: CompactTokens.space6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(height: CompactTokens.space8),
            _actionButton(context, action),
          ],
        ],
      ),
    );
  }

  /// The button of one action: a greyed press is null, and the reason it
  /// waits travels as a hint over it.
  Widget _actionButton(BuildContext context, _Action action) {
    final button = TextButton(
      onPressed: action.enabled ? action.onPressed : null,
      child: Text(action.label),
    );
    if (action.tooltip == null) return button;
    return TuneTooltip(message: action.tooltip!, child: button);
  }
}
