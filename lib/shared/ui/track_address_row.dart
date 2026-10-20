import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// An address of the track, with a way to take it away.
///
/// The file on this machine and the address of the source are the two facts
/// no icon can stand for, so they are written out and can be copied to the
/// clipboard.
class TrackAddressRow extends StatelessWidget {
  /// The address itself: a path on this machine or an address of a source.
  final String address;

  /// The name of the address, written above it.
  final String label;

  /// The name of the button that copies the address.
  final String copyHint;

  const TrackAddressRow({
    super.key,
    required this.address,
    required this.label,
    required this.copyHint,
  });

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
                label,
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: CompactTypeScale.mark,
                  weight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                address,
                maxLines: 3,
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TuneTooltip(
          message: copyHint,
          child: IconButton(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded, size: CompactTokens.icon16),
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
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
