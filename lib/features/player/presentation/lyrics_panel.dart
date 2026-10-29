import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_marks_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

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
    final theme = Theme.of(context);
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
    final run = ref.watch(smartLyricsControllerProvider);

    if (current != null && current.hasLyrics) {
      final document = current.document!;
      final flags =
          ref.watch(songMarksProvider(song.id)).valueOrNull ??
          SmartLyricsSongFlags.empty;
      final marks = ref.read(smartLyricsMarksControllerProvider);
      final list = ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: CompactTokens.space8),
        itemExtent: _lineExtent,
        itemCount: document.lines.length,
        itemBuilder: (context, index) {
          final line = document.lines[index];
          return _LyricLine(
            line: line.text,
            active: index == active,
            flagged: flags.lines.contains(index),
            onToggleFlag: () => marks.toggleLine(song.id, index),
          );
        },
      );
      final markRow = _MarkRow(songId: song.id, flags: flags);
      // The machine sheet says what it is: a better sheet found later tops
      // it, and the search again is the way.
      if (current.smart) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.loc.lyricsSmartNote,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _reload(song),
                    child: Text(context.loc.lyricsSearchAgain),
                  ),
                ],
              ),
            ),
            Expanded(child: list),
            markRow,
          ],
        );
      }
      return Column(children: [Expanded(child: list), markRow]);
    }

    // A run for this track is on its way; its progress is the message.
    if (run.isRunningFor(song.id)) {
      return _Message(
        text: context.loc.lyricsSmartGenerating,
        icon: Icons.lyrics_outlined,
        actions: [
          _Action(
            label: context.loc.cancel,
            onPressed: () =>
                ref.read(smartLyricsControllerProvider.notifier).cancel(),
          ),
        ],
      );
    }

    if (run.phase == SmartLyricsPhase.failed && run.songId == song.id) {
      return _Message(
        text: _failureOf(context, run.failure),
        icon: Icons.error_outline_rounded,
        actions: [
          _Action(
            label: context.loc.lyricsSmartGenerate,
            onPressed: () =>
                ref.read(smartLyricsControllerProvider.notifier).generate(song),
          ),
          _Action(label: context.loc.lyricsSearchAgain, onPressed: () => _reload(song)),
          _Action(
            label: context.loc.lyricsChooseFile,
            onPressed: () => _chooseFile(song),
          ),
        ],
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
        _generateAction(context, song),
      ],
    );
  }

  /// The door of the smart pipeline: greyed until a key sits in the
  /// settings, and the press of an open door runs the loop of M2.
  _Action _generateAction(BuildContext context, Song song) {
    final configured = ref.watch(
      settingsControllerProvider.select(
        (state) => state.smartLyrics.isConfigured,
      ),
    );
    return _Action(
      label: context.loc.lyricsSmartGenerate,
      onPressed: () =>
          ref.read(smartLyricsControllerProvider.notifier).generate(song),
      enabled: configured,
      tooltip: configured ? null : context.loc.lyricsSmartGenerateNeedsKey,
    );
  }

  /// The words a failed run gets: every failure its own, so the reader
  /// knows whether it is the network, the endpoint, or the song itself.
  String _failureOf(BuildContext context, SmartLyricsFailure? failure) =>
      switch (failure) {
        SmartLyricsFailure.noAudio => context.loc.lyricsSmartFailedAudio,
        SmartLyricsFailure.uploadFailed => context.loc.lyricsSmartFailedUpload,
        SmartLyricsFailure.emptyResult => context.loc.lyricsSmartFailedEmpty,
        null => context.loc.lyricsFailed,
      };

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
  const _LyricLine({
    required this.line,
    required this.active,
    this.flagged = false,
    this.onToggleFlag,
  });

  final String line;
  final bool active;

  /// Whether the reader (or the pool) marked this line wrong.
  final bool flagged;

  /// The press that marks the line, or takes the mark back.
  final VoidCallback? onToggleFlag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The sung line takes the step above the others, so the eye finds it
    // without reading the words first.
    final style = active
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              height: 1.2,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // One press marks the line wrong, another takes it back; the flag
        // of a marked line flies in the accent, the others wait, faint.
        if (onToggleFlag != null)
          TuneTooltip(
            message: flagged
                ? context.loc.lyricsUnmarkLine
                : context.loc.lyricsMarkLine,
            child: IconButton(
              onPressed: onToggleFlag,
              icon: Icon(
                flagged ? Icons.flag : Icons.flag_outlined,
                size: CompactTokens.icon16,
                color: flagged
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
              ),
              constraints: const BoxConstraints(
                minWidth: CompactTokens.icon20,
                minHeight: CompactTokens.icon20,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

/// The two whole-track marks the reader hears their way to (docs/
/// smart-lyrics.md §7.4): the track is wrong, or the track is not sung.
class _MarkRow extends ConsumerWidget {
  const _MarkRow({required this.songId, required this.flags});

  final int songId;
  final SmartLyricsSongFlags flags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.read(smartLyricsMarksControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space12,
        vertical: CompactTokens.space6,
      ),
      child: Row(
        children: [
          _toggle(
            context,
            label: context.loc.lyricsMarkSong,
            active: flags.song,
            onPressed: () => marks.toggleSong(songId),
          ),
          const SizedBox(width: CompactTokens.space8),
          _toggle(
            context,
            label: context.loc.lyricsMarkNotSung,
            active: flags.instrumental,
            onPressed: () => marks.toggleNotSung(songId),
          ),
          const Spacer(),
          // The other door into the marks of the library
          // (docs/smart-lyrics.md §7.4).
          TextButton(
            key: const ValueKey('panel-marks'),
            onPressed: () => context.push('/marks'),
            child: Text(context.loc.lyricsMarksTitle),
          ),
        ],
      ),
    );
  }

  /// One of the two marks: a plain button until it is pressed, an accent
  /// one after — the reader sees what their signal said.
  Widget _toggle(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.flag,
        size: CompactTokens.icon16,
        color: active ? theme.colorScheme.primary : null,
      ),
      label: Text(
        label,
        style: active
            ? TextStyle(color: theme.colorScheme.primary)
            : null,
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
