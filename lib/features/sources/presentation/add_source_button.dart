import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/features/sources/presentation/source_form_dialog.dart';
import 'package:tune/features/sources/presentation/source_type_dialog.dart';

/// The button that adds a source.
///
/// It opens the list of the types the reader can add and then the form of the
/// type that was picked.
class AddSourceButton extends ConsumerWidget {
  const AddSourceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      key: const ValueKey('sources-add'),
      onPressed: () => _addSource(context, ref),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, CompactTokens.controlDefault),
        padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      icon: const Icon(Icons.add_rounded, size: CompactTokens.icon16),
      label: Text(context.loc.sourcesAdd),
    );
  }

  Future<void> _addSource(BuildContext context, WidgetRef ref) async {
    final service = ref.read(musicSourceServiceProvider);
    final types = service.addableTypes;
    if (types.isEmpty) return;

    final chosen = await SourceTypeDialog.show(context, types);
    if (chosen == null || !context.mounted) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => SourceFormDialog.add(
        type: chosen,
        fields: service.fieldsForType(chosen.type),
      ),
    );
  }
}
