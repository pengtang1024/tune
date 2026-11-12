import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The title, the search field and the menu above the settings cards.
class SettingsPaneHeader extends StatelessWidget {
  final TextEditingController searchController;

  /// The trimmed, lower-cased query the page filters the sections by.
  final String query;

  /// The section the page is showing; the menu cannot reset the overview.
  final SettingsSection section;

  final ValueChanged<String> onQueryChanged;
  final VoidCallback onResetSection;
  final VoidCallback onResetAll;

  const SettingsPaneHeader({
    super.key,
    required this.searchController,
    required this.query,
    required this.section,
    required this.onQueryChanged,
    required this.onResetSection,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        CompactTokens.space12,
        CompactTokens.pageGutter,
        CompactTokens.space4,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A phone cannot hold the title, the version, the search and the
          // menu in one row, so the search drops to a row of its own.
          final narrow = constraints.maxWidth < 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    context.loc.settingsTitle,
                    style: CompactTypography.asDisplay(
                      theme.textTheme.displayMedium,
                      size: CompactTypeScale.displayMedium,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(width: CompactTokens.space8),
                  if (!narrow)
                    Text(
                      'v${AppVersion.version}',
                      style: CompactTypography.mono(
                        theme.colorScheme.onSurfaceVariant,
                        size: CompactTypeScale.mark,
                      ),
                    ),
                  const Spacer(),
                  if (!narrow) ...[
                    SizedBox(
                      width: wide ? 220 : 150,
                      child: _searchField(context),
                    ),
                    const SizedBox(width: CompactTokens.space8),
                  ],
                  _moreButton(context),
                ],
              ),
              if (narrow) ...[
                const SizedBox(height: CompactTokens.space8),
                _searchField(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: searchController,
      onChanged: onQueryChanged,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
        hintText: context.loc.settingsSearchHint,
        hintStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: CompactTokens.icon16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  onQueryChanged('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: CompactTokens.icon14,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CompactTokens.space8,
          vertical: CompactTokens.space8,
        ),
        border: OutlineInputBorder(
          borderRadius: CompactTokens.borderRadius8,
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CompactTokens.borderRadius8,
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CompactTokens.borderRadius8,
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    return TuneTooltip(
      message: context.loc.libraryMoreActions,
      child: PopupMenuButton<String>(
        key: const ValueKey('settings-more'),
        icon: const Icon(Icons.more_horiz),
        onSelected: (value) {
          if (value == 'resetSection') onResetSection();
          if (value == 'resetAll') onResetAll();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'resetSection',
            enabled: section != SettingsSection.overview,
            child: Text(context.loc.settingsResetSection),
          ),
          PopupMenuItem(
            value: 'resetAll',
            child: Text(context.loc.settingsResetAll),
          ),
        ],
      ),
    );
  }
}
