import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

/// The grid of settings cards under the page header.
///
/// The health table and the about block read across the page; the other
/// sections sit in an even grid of up to three columns.
class SettingsSectionsBody extends StatelessWidget {
  /// The sections the search left visible, in page order.
  final List<SettingsSection> sections;

  /// The anchors the scroll spy and the nav rail follow.
  final Map<SettingsSection, GlobalKey> sectionKeys;

  /// Draws the card of one section.
  final Widget Function(SettingsSection) cardBuilder;

  /// The about block, drawn full width where it appears.
  final Widget about;

  const SettingsSectionsBody({
    super.key,
    required this.sections,
    required this.sectionKeys,
    required this.cardBuilder,
    required this.about,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(CompactTokens.space16),
        child: Text(
          context.loc.settingsSearchNoMatch,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final gap = CompactTokens.space8;
        final fullWidth = {
          SettingsSection.components,
          SettingsSection.sourceHealth,
          SettingsSection.about,
        };
        final rows = <Widget>[];
        var row = <SettingsSection>[];

        void flushRow() {
          if (row.isEmpty) return;
          final rowSections = List.of(row);
          row = [];
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: CompactTokens.space8),
                    Expanded(
                      child: i < rowSections.length
                          ? SizedBox(
                              key: sectionKeys[rowSections[i]],
                              child: cardBuilder(rowSections[i]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        for (final section in sections) {
          if (fullWidth.contains(section)) {
            flushRow();
            rows.add(
              SizedBox(
                key: sectionKeys[section],
                width: constraints.maxWidth,
                child: section == SettingsSection.about
                    ? about
                    : cardBuilder(section),
              ),
            );
            continue;
          }
          row.add(section);
          if (row.length == columns) flushRow();
        }
        flushRow();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
