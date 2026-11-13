import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// Today's tokens, the cached text count and the clear button.
class SettingsLocalizationLedger extends StatelessWidget {
  final int? tokens;
  final int? cached;
  final Future<void> Function() onClear;

  const SettingsLocalizationLedger({
    super.key,
    required this.tokens,
    required this.cached,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    return Row(
      children: [
        _LedgerFigure(
          label: strings.settingsLocalizationUsage,
          value: tokens?.toString() ?? '-',
        ),
        const SizedBox(width: CompactTokens.space16),
        _LedgerFigure(
          label: strings.settingsLocalizationCache,
          value: cached?.toString() ?? '-',
        ),
        const Spacer(),
        TextButton(onPressed: onClear, child: Text(strings.clear)),
      ],
    );
  }
}

class _LedgerFigure extends StatelessWidget {
  final String label;
  final String value;

  const _LedgerFigure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
        const SizedBox(width: CompactTokens.space4),
        Text(value, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
