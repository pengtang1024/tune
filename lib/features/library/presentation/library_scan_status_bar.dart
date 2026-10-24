import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/library/application/library_controller.dart';

/// Progress and message line of a running or failed library scan.
///
/// The bar watches the scan on its own: a running scan reports its progress
/// every percent, and the list of the library must not be rebuilt by it.
class LibraryScanStatusBar extends ConsumerWidget {
  /// Whether one of the sources did not come back with a clean scan.
  final bool sourceIssues;

  const LibraryScanStatusBar({super.key, required this.sourceIssues});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scan = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.scanProgress ?? 0,
          value.valueOrNull?.statusMessage,
          value.valueOrNull?.errorMessage,
        ),
      ),
    );

    final isError = scan.$4 != null;
    final message = isError ? scan.$4! : (scan.$3 ?? '');
    final shows = scan.$1 || isError || sourceIssues;
    if (!shows) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        0,
        CompactTokens.pageGutter,
        CompactTokens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scan.$1) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: scan.$2,
                minHeight: 2,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: CompactTokens.space4),
          ],
          if (message.isNotEmpty)
            Text(
              message,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
