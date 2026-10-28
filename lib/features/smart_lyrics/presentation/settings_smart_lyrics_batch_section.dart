import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';

/// The gap the batch fills (docs/smart-lyrics.md §7.2, M5): the reader
/// presses「补齐曲库」once, the queue runs one track at a time, and the
/// card says where the run stands — what is left, what is done, and what
/// a cloud budget stopped it at.
class SmartLyricsBatchSection extends ConsumerWidget {
  const SmartLyricsBatchSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(smartLyricsBatchControllerProvider);
    final counts = ref.watch(smartLyricsBatchCountsProvider);
    final fresh = ref.watch(smartLyricsNewMissingProvider);
    final strings = context.loc;
    final failed = progress.running
        ? 0
        : counts.valueOrNull?[SmartLyricsTaskStatus.failed] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(
              key: const ValueKey('smart-lyrics-batch-start'),
              onPressed: progress.running
                  ? null
                  : () => ref
                        .read(smartLyricsBatchControllerProvider.notifier)
                        .start(),
              child: Text(strings.settingsSmartLyricsBatchStart),
            ),
            if (progress.running) ...[
              const SizedBox(width: CompactTokens.space12),
              TextButton(
                key: const ValueKey('smart-lyrics-batch-stop'),
                onPressed: () =>
                    ref.read(smartLyricsBatchControllerProvider.notifier).stop(),
                child: Text(strings.settingsSmartLyricsBatchStop),
              ),
            ] else if (failed > 0) ...[
              const SizedBox(width: CompactTokens.space12),
              TextButton(
                key: const ValueKey('smart-lyrics-batch-retry'),
                onPressed: () => ref
                    .read(smartLyricsBatchControllerProvider.notifier)
                    .retryFailed(),
                child: Text(strings.settingsSmartLyricsBatchRetry),
              ),
            ],
          ],
        ),
        Text(
          _lineOf(context, progress, counts),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // What a scan brought in since the last press: the queue only
        // moves when the reader says so.
        fresh.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (count) => count == 0
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: CompactTokens.space6),
                  child: Text(
                    strings.settingsSmartLyricsBatchFresh(count),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.settingsSmartLyricsLeakCheck,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Switch(
              key: const ValueKey('smart-lyrics-gap-check'),
              value: ref.watch(
                settingsControllerProvider.select(
                  (state) => state.smartLyrics.gapCheckEnabled,
                ),
              ),
              onChanged: (value) {
                final config = ref
                    .read(settingsControllerProvider)
                    .smartLyrics;
                ref
                    .read(settingsControllerProvider.notifier)
                    .setSmartLyrics(config.copyWith(gapCheckEnabled: value));
              },
            ),
          ],
        ),
      ],
    );
  }

  /// The words the figures stand for: a run that is on, a run the budget
  /// stopped, or the account as the rows hold it.
  String _lineOf(
    BuildContext context,
    SmartLyricsBatchProgress progress,
    AsyncValue<Map<SmartLyricsTaskStatus, int>> counts,
  ) {
    final strings = context.loc;
    if (progress.running) {
      return strings.settingsSmartLyricsBatchRunning(
        progress.pending,
        progress.countOf(SmartLyricsTaskStatus.done),
      );
    }
    if (progress.pausedForBudget) {
      return strings.settingsSmartLyricsBudgetPaused(progress.cloudBudget ?? 0);
    }
    final account = counts.valueOrNull ?? const {};
    return strings.settingsSmartLyricsBatchIdle(
      account[SmartLyricsTaskStatus.pending] ?? 0,
      account[SmartLyricsTaskStatus.done] ?? 0,
      account[SmartLyricsTaskStatus.failed] ?? 0,
    );
  }
}
