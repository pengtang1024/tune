import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';

/// The account of the lyrics the library carries (docs/smart-lyrics.md, M0).
///
/// The card shows the baseline the smart pipeline starts from: how many
/// tracks the library holds, how many already carry lyrics, and the gap
/// between them. It is a read of the ledger, nothing else — the pipeline's
/// own controls arrive with its milestones.
class SettingsSmartLyricsCard extends ConsumerWidget {
  const SettingsSmartLyricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(smartLyricsLedgerProvider);

    return SettingsCard(
      index: '06',
      eyebrow: context.loc.settingsSectionSmartLyrics,
      title: context.loc.settingsSmartLyricsTitle,
      description: context.loc.settingsSmartLyricsDescription,
      child: ledger.when(
        // A count is one query over the rows and answers in milliseconds;
        // a ring that flashes for it is noise. While it runs, and when it
        // failed, the figures stand as dashes — a zero would lie.
        loading: _LedgerRow.placeholder,
        error: (error, stackTrace) => _LedgerRow.placeholder(
          trailing: TextButton(
            onPressed: () => ref.invalidate(smartLyricsLedgerProvider),
            child: Text(context.loc.lyricsRetry),
          ),
        ),
        data: (value) => _LedgerRow(
          total: '${value.total}',
          resolved: '${value.resolved}',
          missing: '${value.missing}',
        ),
      ),
    );
  }
}

/// The three figures of the ledger in one row.
class _LedgerRow extends StatelessWidget {
  final String total;
  final String resolved;
  final String missing;
  final Widget? trailing;

  const _LedgerRow({
    required this.total,
    required this.resolved,
    required this.missing,
    this.trailing,
  });

  /// The row as it stands before the count arrives or after it failed.
  static _LedgerRow placeholder({Widget? trailing}) => _LedgerRow(
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
        _Figure(label: context.loc.settingsSmartLyricsTotal, value: total),
        const SizedBox(width: CompactTokens.space24),
        _Figure(label: context.loc.settingsSmartLyricsResolved, value: resolved),
        const SizedBox(width: CompactTokens.space24),
        _Figure(label: context.loc.settingsSmartLyricsMissing, value: missing),
        if (trailing != null) ...[
          const SizedBox(width: CompactTokens.space12),
          trailing!,
        ],
      ],
    );
  }
}

/// One number of the ledger: the machine-written figure over its name.
class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure({required this.label, required this.value});

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
