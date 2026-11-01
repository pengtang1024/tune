import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_ledger_provider.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_sample_provider.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_batch_section.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_key_section.dart';
import 'package:tune/utils/logger.dart';

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
    final sample = ref.watch(smartLyricsSampleProvider);
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
          sample.when(
            // The same honesty as the ledger: a number that is not there
            // yet stands as a dash, never as a zero.
            loading: () => AccuracyRow.placeholder(),
            error: (error, stackTrace) => AccuracyRow.placeholder(
              trailing: TextButton(
                onPressed: () => ref.invalidate(smartLyricsSampleProvider),
                child: Text(strings.lyricsRetry),
              ),
            ),
            data: (account) => AccuracyRow(
              drawn: '${account.drawn}',
              checked: '${account.checked}',
              rate: account.rate,
              trailing: TextButton(
                onPressed: () => unawaited(_drawSample(ref)),
                child: Text(strings.settingsSmartLyricsDrawSample),
              ),
            ),
          ),
          const SizedBox(height: CompactTokens.space12),
          Text(
            strings.settingsSmartLyricsAccuracyNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space12),
          const SmartLyricsBatchSection(),
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

  /// Draws the stratified sample over the resolved rows; the figures below
  /// follow when the account is read again. A draw that fails is a log —
  /// the figures keep standing, and the press can be tried again.
  Future<void> _drawSample(WidgetRef ref) async {
    try {
      await ref.read(smartLyricsSampleStoreProvider).draw();
    } catch (error, stackTrace) {
      Log.error('抽样失败: $error', stackTrace);
    } finally {
      ref.invalidate(smartLyricsSampleProvider);
    }
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

/// The three figures of the accuracy sample in one row: what was drawn,
/// what was checked, and the share of the checked rows that passed.
class AccuracyRow extends StatelessWidget {
  final String drawn;
  final String checked;

  /// The share of the checked rows a human judged right, `null` while
  /// nothing is checked — the row shows a dash, never a zero.
  final double? rate;
  final Widget? trailing;

  const AccuracyRow({
    super.key,
    required this.drawn,
    required this.checked,
    required this.rate,
    this.trailing,
  });

  /// The row as it stands before the count arrives or after it failed.
  static AccuracyRow placeholder({Widget? trailing}) => AccuracyRow(
    drawn: '-',
    checked: '-',
    rate: null,
    trailing: trailing,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LedgerFigure(
          label: context.loc.settingsSmartLyricsSampled,
          value: drawn,
        ),
        const SizedBox(width: CompactTokens.space24),
        LedgerFigure(
          label: context.loc.settingsSmartLyricsChecked,
          value: checked,
        ),
        const SizedBox(width: CompactTokens.space24),
        LedgerFigure(
          label: context.loc.settingsSmartLyricsAccuracy,
          value: rate == null ? '-' : '${(rate! * 100).toStringAsFixed(1)}%',
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
