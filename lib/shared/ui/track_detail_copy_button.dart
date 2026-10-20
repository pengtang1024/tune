import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The button that takes the value of a line away.
///
/// The addresses of a track are worth keeping, so the reader can take one
/// with a click instead of writing it down.
class TrackDetailCopyButton extends StatelessWidget {
  /// The name of the button, shown in its tooltip.
  final String hint;

  /// The value that is taken away.
  final String value;

  const TrackDetailCopyButton({
    super.key,
    required this.hint,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TuneTooltip(
      message: hint,
      child: IconButton(
        onPressed: () => _copy(context),
        icon: const Icon(Icons.copy_rounded, size: CompactTokens.icon16),
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
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
