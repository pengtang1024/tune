import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/application/discovery_controller.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

Future<void> showDiscoveryInfoSheet(BuildContext context) {
  return showCompactSheet<void>(
    context,
    (context) => const DiscoveryInfoSheet(),
  );
}

class DiscoveryInfoSheet extends ConsumerWidget {
  const DiscoveryInfoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CompactTokens.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space24,
          CompactTokens.space16,
          CompactTokens.space24,
          CompactTokens.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.loc.discoverWhyTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TuneTooltip(
                  message: context.loc.close,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: CompactTokens.icon18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CompactTokens.space12),
            Text(
              context.loc.discoverWhyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: CompactTokens.space16),
            _InfoLine(
              icon: Icons.library_music_rounded,
              text: context.loc.discoverWhyLibrary,
            ),
            const SizedBox(height: CompactTokens.space8),
            _InfoLine(
              icon: Icons.favorite_rounded,
              text: context.loc.discoverWhyHearts,
            ),
            const SizedBox(height: CompactTokens.space8),
            const SizedBox(height: CompactTokens.space8),
            _InfoLine(
              icon: Icons.history_rounded,
              text: context.loc.discoverWhyHistory,
            ),
            const SizedBox(height: CompactTokens.space8),
            _InfoLine(
              icon: Icons.lock_outline_rounded,
              text: context.loc.discoverWhyPrivacy,
            ),
            const SizedBox(height: CompactTokens.space20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('discovery-clear-feedback'),
                    onPressed: () => _clear(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, CompactTokens.controlDefault),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: CompactTokens.icon16,
                    ),
                    label: Text(context.loc.discoverClearAll),
                  ),
                ),
                const SizedBox(width: CompactTokens.space12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, CompactTokens.controlDefault),
                  ),
                  child: Text(context.loc.discoverWhyClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.discoverClearTitle),
        content: Text(context.loc.discoverClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(discoveryControllerProvider.notifier).clearFeedback();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = context.loc.discoverCleared;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: CompactTokens.icon16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: CompactTokens.space8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
