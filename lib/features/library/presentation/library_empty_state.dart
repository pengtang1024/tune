import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/shared/ui/empty_state_view.dart';

/// Empty state of the library page.
///
/// The state names the reason the list is empty and offers the action that
/// resolves it.
class LibraryEmptyState extends StatelessWidget {
  final LibraryState state;
  final VoidCallback onClearQuery;
  final VoidCallback onClearSourceFilter;
  final VoidCallback onScan;

  const LibraryEmptyState({
    super.key,
    required this.state,
    required this.onClearQuery,
    required this.onClearSourceFilter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isNotEmpty && state.hasSongs) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: context.loc.libraryNoMatchTitle,
        subtitle: context.loc.libraryNoMatchSubtitle,
        action: TextButton(
          onPressed: onClearQuery,
          child: Text(context.loc.libraryClearSearch),
        ),
      );
    }

    if (state.sourceFilter != null && state.hasSongs) {
      return EmptyStateView(
        icon: Icons.filter_alt_off_rounded,
        title: context.loc.librarySourceEmptyTitle,
        subtitle: context.loc.librarySourceEmptySubtitle,
        action: TextButton(
          onPressed: onClearSourceFilter,
          child: Text(context.loc.libraryViewAllSources),
        ),
      );
    }

    return EmptyStateView(
      icon: Icons.library_music_outlined,
      title: state.isScanning
          ? context.loc.libraryScanningTitle
          : context.loc.libraryEmptyTitle,
      subtitle: state.isScanning
          ? state.statusMessage
          : context.loc.libraryEmptySubtitle,
      action: state.isScanning
          ? null
          : FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(
                Icons.search_rounded,
                size: CompactTokens.icon16,
              ),
              label: Text(context.loc.libraryScanAllSources),
            ),
    );
  }
}
