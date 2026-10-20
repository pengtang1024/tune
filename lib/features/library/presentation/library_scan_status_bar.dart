import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/features/library/domain/library_state.dart';

/// Progress and message line of a running or failed library scan.
class LibraryScanStatusBar extends StatelessWidget {
  final LibraryState state;

  const LibraryScanStatusBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = state.errorMessage != null;
    final message = isError ? state.errorMessage! : (state.statusMessage ?? '');

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
          if (state.isScanning) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: state.scanProgress,
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
