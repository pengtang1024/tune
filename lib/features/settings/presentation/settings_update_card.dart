import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/application/update_controller.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';

/// The card that checks the project page and installs a newer release.
class SettingsUpdateCard extends ConsumerWidget {
  const SettingsUpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final strings = context.loc;
    final theme = Theme.of(context);

    return SettingsCard(
      index: '09',
      eyebrow: strings.updateEyebrow,
      title: strings.updateTitle,
      description: strings.updateDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.updateCurrentVersion(AppVersion.version),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          _StatusLine(state: state),
          const SizedBox(height: 12),
          _Actions(state: state, controller: controller),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final UpdateState state;

  const _StatusLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    final theme = Theme.of(context);
    final text = switch (state.status) {
      UpdateStatus.idle => strings.updateIdle,
      UpdateStatus.checking => strings.updateChecking,
      UpdateStatus.upToDate => strings.updateUpToDate,
      UpdateStatus.available => strings.updateAvailable(
        state.release?.version ?? '',
      ),
      UpdateStatus.downloading =>
        '${strings.updateDownloading} ${(state.progress * 100).round()}%',
      UpdateStatus.installing => strings.updateInstalling,
      UpdateStatus.ready => strings.updateReady,
      UpdateStatus.failed => strings.updateFailed(state.error ?? ''),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: theme.textTheme.bodyMedium),
        if (state.status == UpdateStatus.downloading) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(CompactTokens.radius4),
            child: LinearProgressIndicator(value: state.progress, minHeight: 4),
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final UpdateState state;
  final UpdateController controller;

  const _Actions({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    final release = state.release;

    return switch (state.status) {
      UpdateStatus.checking ||
      UpdateStatus.downloading ||
      UpdateStatus.installing => const SizedBox.shrink(),
      UpdateStatus.ready => FilledButton(
        onPressed: controller.restart,
        child: Text(strings.updateRestart),
      ),
      UpdateStatus.available => Row(
        children: [
          FilledButton(
            onPressed: release?.asset == null ? null : controller.install,
            child: Text(strings.updateInstall),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: controller.check,
            child: Text(strings.updateCheck),
          ),
          const SizedBox(width: 10),
          if (release?.asset == null)
            Flexible(
              child: Text(
                strings.updateNoArchive,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      UpdateStatus.failed => FilledButton(
        onPressed: controller.check,
        child: Text(strings.updateRetry),
      ),
      _ => OutlinedButton(
        onPressed: controller.check,
        child: Text(strings.updateCheck),
      ),
    };
  }
}
