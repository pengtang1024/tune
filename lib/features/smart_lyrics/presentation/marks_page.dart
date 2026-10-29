import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_marks_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The one place every mark of the library is seen (docs/smart-lyrics.md
/// §7.4, M6): grouped by track, the tracks with something open first, and
/// every mark with the way out it is waiting for — the re-solve on its
/// own, an explicit reword, or the reader's own take-back.
class SmartLyricsMarksPage extends ConsumerWidget {
  const SmartLyricsMarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final marks = ref.watch(smartLyricsMarksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.lyricsMarksTitle)),
      body: marks.when(
        // A count over the rows answers in milliseconds; a ring that
        // flashes for it is noise — dashes until the rows are read.
        loading: () => Center(
          child: Text(
            '-',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(smartLyricsMarksProvider),
            child: Text(context.loc.lyricsRetry),
          ),
        ),
        data: (groups) => groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: CompactTokens.icon20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: CompactTokens.space6),
                    Text(
                      context.loc.lyricsMarksEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: CompactTokens.space8,
                ),
                children: [
                  for (final group in groups) _TrackGroup(group: group),
                ],
              ),
      ),
    );
  }
}

/// One track and the marks it carries.
class _TrackGroup extends StatelessWidget {
  const _TrackGroup({required this.group});

  final SmartLyricsMarkGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space12,
        vertical: CompactTokens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.song.artist.isEmpty
                ? group.song.title
                : '${group.song.title} — ${group.song.artist}',
            style: theme.textTheme.titleSmall,
          ),
          for (final mark in group.marks) _MarkTile(mark: mark, song: group.song),
        ],
      ),
    );
  }
}

/// One mark: what it is about, who made it, where it stands — and the
/// ways out that are open while it is uncleared.
class _MarkTile extends ConsumerWidget {
  const _MarkTile({required this.mark, required this.song});

  final SmartLyricsMark mark;
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final controller = ref.read(smartLyricsMarksControllerProvider);
    final open = mark.state == SmartLyricsMarkState.uncleared;

    return Row(
      children: [
        Expanded(child: Text(_labelOf(strings), style: theme.textTheme.bodyMedium)),
        Text(
          mark.source == 'system'
              ? strings.lyricsMarkSourceSystem
              : strings.lyricsMarkSourceReader,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: CompactTokens.space12),
        Text(_stateOf(strings), style: theme.textTheme.labelSmall),
        if (open && mark.kind == SmartLyricsMarkKind.line) ...[
          const SizedBox(width: CompactTokens.space8),
          TextButton(
            key: const ValueKey('smart-lyrics-reword'),
            onPressed: () => _openReword(context, controller),
            child: Text(strings.lyricsMarkReword),
          ),
        ],
        if (open) ...[
          const SizedBox(width: CompactTokens.space8),
          TextButton(
            key: const ValueKey('smart-lyrics-revoke'),
            onPressed: () => controller.revokeMark(mark),
            child: Text(strings.lyricsMarkRevoke),
          ),
        ],
      ],
    );
  }

  String _labelOf(AppLocalizations strings) => switch (mark.kind) {
    SmartLyricsMarkKind.line =>
      strings.lyricsMarkLineNumber((mark.line ?? 0) + 1),
    SmartLyricsMarkKind.song => strings.lyricsMarkSong,
    SmartLyricsMarkKind.instrumental => strings.lyricsMarkNotSung,
  };

  String _stateOf(AppLocalizations strings) => switch (mark.state) {
    SmartLyricsMarkState.uncleared => strings.lyricsMarkWaiting,
    SmartLyricsMarkState.resolved => strings.lyricsMarkResolved,
    SmartLyricsMarkState.reworded => strings.lyricsMarkReworded,
    SmartLyricsMarkState.revoked => strings.lyricsMarkRevoked,
  };

  Future<void> _openReword(
    BuildContext context,
    SmartLyricsMarksController controller,
  ) => showDialog<void>(
    context: context,
    builder: (context) => _RewordDialog(song: song, line: mark.line ?? 0),
  );
}

/// The words the reader sits down to write (docs/smart-lyrics.md §7.4):
/// one line, the current words as they stand, a save — and the words go
/// to the file the reading chain tops, never anywhere near the panel.
class _RewordDialog extends ConsumerStatefulWidget {
  const _RewordDialog({required this.song, required this.line});

  final Song song;
  final int line;

  @override
  ConsumerState<_RewordDialog> createState() => _RewordDialogState();
}

class _RewordDialogState extends ConsumerState<_RewordDialog> {
  final TextEditingController _text = TextEditingController();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final current = await ref
        .read(smartLyricsMarksControllerProvider)
        .currentLineText(widget.song, widget.line);
    if (!mounted) return;
    _text.text = current;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    return AlertDialog(
      title: Text(strings.lyricsMarkRewordTitle),
      content: TextField(
        key: const ValueKey('smart-lyrics-reword-field'),
        controller: _text,
        autofocus: true,
        minLines: 1,
        maxLines: 3,
        enabled: _loaded,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        TextButton(
          key: const ValueKey('smart-lyrics-reword-save'),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await ref
                .read(smartLyricsMarksControllerProvider)
                .rewordLine(widget.song, widget.line, _text.text);
            navigator.pop();
          },
          child: Text(strings.lyricsMarkRewordSave),
        ),
      ],
    );
  }
}
