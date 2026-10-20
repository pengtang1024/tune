import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/shared/ui/meta_chip.dart';
import 'package:tune/shared/ui/source_mark.dart';

/// The dialog that lets the reader pick a type of source to add.
///
/// The list shows the types the app serves; the reader picks one and the form
/// of that type comes next.
class SourceTypeDialog extends StatelessWidget {
  final List<SourceTypeDescriptor> types;

  const SourceTypeDialog({super.key, required this.types});

  /// Shows the dialog and answers with the type the reader picked.
  static Future<SourceTypeDescriptor?> show(
    BuildContext context,
    List<SourceTypeDescriptor> types,
  ) {
    return showDialog<SourceTypeDescriptor>(
      context: context,
      builder: (context) => SourceTypeDialog(types: types),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(context.loc.sourcesAddChooseType),
      content: SizedBox(
        width: 380,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              key: ValueKey('source-type-${type.type}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                sourceIconOf(type.type, type.kind),
                size: CompactTokens.icon20,
                color: factToneColor(
                  sourceToneOf(type.kind),
                  theme.colorScheme,
                ),
              ),
              title: Text(type.name),
              subtitle: Text(
                type.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(type),
            );
          },
        ),
      ),
    );
  }
}
