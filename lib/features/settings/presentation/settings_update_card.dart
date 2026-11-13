import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/application/update_controller.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';

/// The card that checks the project page and installs a newer release.
///
/// One line of state and one action: the dashboard already says what the
/// page is for, so the card does not repeat the version story.
class SettingsUpdateCard extends ConsumerWidget {
  const SettingsUpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final strings = context.loc;
    final theme = Theme.of(context);

    return SettingsPanel(
      key: const ValueKey('settings-card-update'),
      icon: Icons.system_update_alt_rounded,
      title: strings.updateEyebrow,
      trailing: _Actions(state: state, controller: controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${AppVersion.version}',
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusText(context, state),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (state.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(CompactTokens.radius4),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 4,
              ),
            ),
          ],
          if (state.status == UpdateStatus.available &&
              state.release?.asset == null) ...[
            const SizedBox(height: 4),
            Text(
              strings.updateNoArchive,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const _TokenField(),
        ],
      ),
    );
  }

  static String _statusText(BuildContext context, UpdateState state) {
    final strings = context.loc;
    return switch (state.status) {
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
      UpdateStatus.failed => switch (state.failure) {
        UpdateCheckFailure.rateLimited => strings.updateFailedRateLimited,
        UpdateCheckFailure.unauthorized => strings.updateFailedUnauthorized,
        UpdateCheckFailure.network => strings.updateFailedNetwork,
        UpdateCheckFailure.server => strings.updateFailedServer,
        null => strings.updateFailed(state.error ?? ''),
      },
    };
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
        style: _filled(context),
        child: Text(strings.updateRestart),
      ),
      UpdateStatus.available => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: release?.asset == null ? null : controller.install,
            style: _filled(context),
            child: Text(strings.updateInstall),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: controller.check,
            style: _outlined(context),
            child: Text(strings.updateCheck),
          ),
        ],
      ),
      UpdateStatus.failed => FilledButton(
        onPressed: controller.check,
        style: _filled(context),
        child: Text(strings.updateRetry),
      ),
      _ => OutlinedButton(
        onPressed: controller.check,
        style: _outlined(context),
        child: Text(strings.updateCheck),
      ),
    };
  }

  static ButtonStyle _filled(BuildContext context) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space12),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle _outlined(BuildContext context) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space12),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

/// The optional token the check sends: typed here wins over the environment.
class _TokenField extends ConsumerStatefulWidget {
  const _TokenField();

  @override
  ConsumerState<_TokenField> createState() => _TokenFieldState();
}

class _TokenFieldState extends ConsumerState<_TokenField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsControllerProvider).githubToken,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.loc;
    final theme = Theme.of(context);

    return TextField(
      key: const ValueKey('settings-update-token'),
      controller: _controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: strings.updateTokenLabel,
        hintText: strings.updateTokenHint,
        helperText: strings.updateTokenHelp,
        helperStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onChanged: (value) =>
          ref.read(settingsControllerProvider.notifier).setGithubToken(value),
    );
  }
}
