import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The search box of the library.
///
/// It only asks; the page decides what a query means. The focus node is
/// handed in from above, because the app-wide shortcut focuses this field.
class LibrarySearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const LibrarySearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CompactTokens.searchFieldMaxWidth,
        ),
        child: SizedBox(
          width: double.infinity,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainer,
              hintText: context.loc.search,
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: CompactTokens.icon16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : TuneTooltip(
                      message: context.loc.libraryClearSearch,
                      child: IconButton(
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: CompactTokens.icon14,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space8,
                vertical: CompactTokens.space8,
              ),
              border: OutlineInputBorder(
                borderRadius: CompactTokens.borderRadius8,
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: CompactTokens.borderRadius8,
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: CompactTokens.borderRadius8,
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
