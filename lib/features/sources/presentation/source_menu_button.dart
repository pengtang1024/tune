import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The menu of a source.
///
/// Every source except the local music can be moved; a built-in source has no
/// delete action because it came with the app.
class SourceMenuButton extends ConsumerWidget {
  final MusicSourceConfig source;

  /// Whether the menu answers while a scan is running.
  final bool enabled;

  /// Whether the source waits in the folded group.
  final bool inMore;

  /// Whether the source is healthy enough to come back to the main list.
  final bool canMoveToMain;

  /// Whether there is a previous non-local source to trade places with.
  final bool canMoveUp;

  /// Whether there is a next non-local source to trade places with.
  final bool canMoveDown;

  const SourceMenuButton({
    super.key,
    required this.source,
    this.enabled = true,
    this.inMore = false,
    this.canMoveToMain = true,
    this.canMoveUp = true,
    this.canMoveDown = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TuneTooltip(
      message: context.loc.sourcesMenu,
      child: PopupMenuButton<_SourceAction>(
        key: ValueKey('source-menu-${source.id}'),
        icon: const Icon(Icons.more_horiz_rounded),
        iconSize: CompactTokens.icon16,
        padding: EdgeInsets.zero,
        onSelected: enabled ? (action) => _run(context, ref, action) : null,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SourceAction.moveUp,
            enabled: canMoveUp,
            child: Text(context.loc.sourcesMoveUp),
          ),
          PopupMenuItem(
            value: _SourceAction.moveDown,
            enabled: canMoveDown,
            child: Text(context.loc.sourcesMoveDown),
          ),
          PopupMenuItem(
            value: inMore ? _SourceAction.moveToMain : _SourceAction.moveToMore,
            child: Text(
              inMore
                  ? context.loc.sourcesMoveToMain
                  : context.loc.sourcesMoveToMore,
            ),
          ),
          if (!source.builtIn)
            PopupMenuItem(
              value: _SourceAction.delete,
              child: Text(context.loc.sourcesDelete),
            ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _SourceAction action,
  ) async {
    switch (action) {
      case _SourceAction.moveUp:
        await ref
            .read(musicSourcesControllerProvider.notifier)
            .moveSourceUp(source.id);
        break;
      case _SourceAction.moveDown:
        await ref
            .read(musicSourcesControllerProvider.notifier)
            .moveSourceDown(source.id);
        break;
      case _SourceAction.moveToMore:
        await ref
            .read(musicSourcesControllerProvider.notifier)
            .setSourceInMore(source.id, true);
        if (context.mounted) _say(context, context.loc.sourcesMovedToMore);
        break;
      case _SourceAction.moveToMain:
        await ref
            .read(musicSourcesControllerProvider.notifier)
            .setSourceInMore(source.id, false);
        if (context.mounted) _say(context, context.loc.sourcesMovedToMain);
        break;
      case _SourceAction.delete:
        await _delete(context, ref);
        break;
    }
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  /// Removes the instance and the tracks it brought in.
  ///
  /// The songs of a removed source have no source to belong to, so they go
  /// with it.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.sourcesDeleteTitle(source.name)),
        content: Text(context.loc.sourcesDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            key: const ValueKey('source-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.sourcesDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(musicSourcesControllerProvider.notifier)
        .removeInstance(source.id);
    await ref.read(libraryControllerProvider.notifier).dropSource(source.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.sourcesDeleted(source.name)),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

/// The actions the menu of a source offers.
enum _SourceAction { moveUp, moveDown, moveToMore, moveToMain, delete }
