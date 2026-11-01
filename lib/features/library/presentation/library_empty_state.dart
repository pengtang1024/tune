import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/shared/ui/empty_state_view.dart';

/// Empty state of the library page.
///
/// The state names the reason the list is empty and offers the action that
/// resolves it.
class LibraryEmptyState extends ConsumerWidget {
  /// What the reader is searching for.
  final String query;

  /// Whether the library holds tracks at all.
  final bool hasSongs;

  /// The source the reader picked, if any.
  final String? sourceFilter;

  /// Whether a filter narrows the page.
  final bool filterActive;

  final VoidCallback onClearQuery;
  final VoidCallback onClearSourceFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onScan;

  const LibraryEmptyState({
    super.key,
    required this.query,
    required this.hasSongs,
    required this.sourceFilter,
    required this.filterActive,
    required this.onClearQuery,
    required this.onClearSourceFilter,
    required this.onClearFilters,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The scan is watched here: it reports its progress every percent, and
    // the list of the library must not be rebuilt by it.
    final scan = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.statusMessage,
        ),
      ),
    );
    final isScanning = scan.$1;

    if (query.trim().isNotEmpty && hasSongs) {
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

    if (filterActive && hasSongs) {
      return EmptyStateView(
        icon: Icons.filter_alt_off_rounded,
        title: context.loc.libraryNoMatchTitle,
        subtitle: context.loc.libraryNoMatchSubtitle,
        action: TextButton(
          onPressed: onClearFilters,
          child: Text(context.loc.libraryFilterClearAll),
        ),
      );
    }

    if (sourceFilter != null && hasSongs) {
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
      title: isScanning
          ? context.loc.libraryScanningTitle
          : context.loc.libraryEmptyTitle,
      subtitle: isScanning
          ? scan.$2
          : context.loc.libraryEmptySubtitle,
      action: isScanning
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
