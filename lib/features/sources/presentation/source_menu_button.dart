import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The menu of a source the reader added.
///
/// A built-in source has no menu: it came with the app, so it can be
/// switched off but not deleted.
class SourceMenuButton extends ConsumerWidget {
  final MusicSourceConfig source;

  /// Whether the menu answers while a scan is running.
  final bool enabled;

  const SourceMenuButton({
    super.key,
    required this.source,
    this.enabled = true,
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
      case _SourceAction.delete:
        await _delete(context, ref);
    }
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
enum _SourceAction { delete }
