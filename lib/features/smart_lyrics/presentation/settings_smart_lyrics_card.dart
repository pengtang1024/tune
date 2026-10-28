import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_key_section.dart';

/// The account of the lyrics the library carries, and the key hole the
/// pipeline waits behind (docs/smart-lyrics.md, M0+M1).
///
/// The figures say what the library holds and what it misses; the section
/// below takes the key and the endpoint preset. The card states plainly
/// what generating uploads — before a key is pasted, not after.
class SettingsSmartLyricsCard extends ConsumerWidget {
  const SettingsSmartLyricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = ref.watch(smartLyricsLedgerProvider);
    final strings = context.loc;

    return SettingsCard(
      index: '06',
      eyebrow: strings.settingsSectionSmartLyrics,
      title: strings.settingsSmartLyricsTitle,
      description: strings.settingsSmartLyricsDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ledger.when(
            // A count is one query over the rows and answers in milliseconds;
            // a ring that flashes for it is noise. While it runs, and when it
            // failed, the figures stand as dashes — a zero would lie.
            loading: LedgerRow.placeholder,
            error: (error, stackTrace) => LedgerRow.placeholder(
              trailing: TextButton(
                onPressed: () => ref.invalidate(smartLyricsLedgerProvider),
                child: Text(strings.lyricsRetry),
              ),
            ),
            data: (value) => LedgerRow(
              total: '${value.total}',
              resolved: '${value.resolved}',
              missing: '${value.missing}',
            ),
          ),
          const SizedBox(height: CompactTokens.space12),
          Text(
            strings.settingsSmartLyricsPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space12),
          const SmartLyricsKeySection(),
        ],
      ),
    );
  }
}

/// The three figures of the ledger in one row.
class LedgerRow extends StatelessWidget {
  final String total;
  final String resolved;
  final String missing;
  final Widget? trailing;

  const LedgerRow({
    super.key,
    required this.total,
    required this.resolved,
    required this.missing,
    this.trailing,
  });

  /// The row as it stands before the count arrives or after it failed.
  static LedgerRow placeholder({Widget? trailing}) => LedgerRow(
    total: '-',
    resolved: '-',
    missing: '-',
    trailing: trailing,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LedgerFigure(label: context.loc.settingsSmartLyricsTotal, value: total),
        const SizedBox(width: CompactTokens.space24),
        LedgerFigure(
          label: context.loc.settingsSmartLyricsResolved,
          value: resolved,
        ),
        const SizedBox(width: CompactTokens.space24),
        LedgerFigure(
          label: context.loc.settingsSmartLyricsMissing,
          value: missing,
        ),
        if (trailing != null) ...[
          const SizedBox(width: CompactTokens.space12),
          trailing!,
        ],
      ],
    );
  }
}

/// One number of the ledger: the machine-written figure over its name.
class LedgerFigure extends StatelessWidget {
  final String label;
  final String value;

  const LedgerFigure({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}
