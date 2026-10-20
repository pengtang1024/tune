import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// The address of the file, with a way to take it away.
///
/// The path is the one fact no icon can stand for, so it is written out and
/// can be copied to the clipboard.
class TrackPathRow extends StatelessWidget {
  final String uri;

  const TrackPathRow({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.trackFactPath,
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: CompactTypeScale.mark,
                  weight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                uri,
                maxLines: 3,
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.micro,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: context.loc.trackDetailsCopyPath,
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: CompactTokens.icon16),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: uri));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.loc.trackDetailsCopied),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }
}
