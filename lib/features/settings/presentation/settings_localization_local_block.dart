import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/features/localization/application/local_model_controller.dart';

/// The download, size and removal of the optional local model.
class SettingsLocalizationLocalBlock extends StatelessWidget {
  final LocalModelState state;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const SettingsLocalizationLocalBlock({
    super.key,
    required this.state,
    required this.onDownload,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (state.phase) {
          LocalModelPhase.checking => _Busy(
            text: strings.settingsLocalizationLocalDownloadHint,
          ),
          LocalModelPhase.notInstalled => _NotInstalled(
            hint: strings.settingsLocalizationLocalDownloadHint,
            onDownload: onDownload,
          ),
          LocalModelPhase.downloading => _Downloading(
            state: state,
            onCancel: onCancel,
          ),
          LocalModelPhase.verifying => _Busy(
            text: strings.settingsLocalizationLocalVerifying,
          ),
          LocalModelPhase.ready => _Ready(
            state: state,
            onRemove: () => _confirmRemove(context, onRemove),
          ),
          LocalModelPhase.failed => _Failed(
            state: state,
            onDownload: onDownload,
          ),
        },
        const SizedBox(height: CompactTokens.space8),
        Text(strings.settingsLocalizationLocalLicense, style: muted),
      ],
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    VoidCallback onRemove,
  ) async {
    final strings = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.settingsLocalizationLocalDelete),
        content: Text(strings.settingsLocalizationLocalDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onRemove();
  }
}

class _NotInstalled extends StatelessWidget {
  final String hint;
  final VoidCallback onDownload;

  const _NotInstalled({required this.hint, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          icon: Icons.download_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          text: strings.settingsLocalizationLocalMissing,
        ),
        const SizedBox(height: CompactTokens.space4),
        Text(
          hint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: CompactTokens.space8),
        FilledButton(
          onPressed: onDownload,
          child: Text(strings.settingsLocalizationLocalDownload),
        ),
      ],
    );
  }
}

class _Downloading extends StatelessWidget {
  final LocalModelState state;
  final VoidCallback onCancel;

  const _Downloading({required this.state, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final progress = state.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              strings.settingsLocalizationLocalDownloading,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: CompactTokens.space8),
            Text(
              progress == null
                  ? _formatBytes(state.received)
                  : '${(progress * 100).round()}% · '
                        '${_formatBytes(state.received)}'
                        ' / ${_formatBytes(state.total)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: CompactTokens.space4),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: CompactTokens.space4),
        TextButton(onPressed: onCancel, child: Text(strings.cancel)),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  final LocalModelState state;
  final VoidCallback onRemove;

  const _Ready({required this.state, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          icon: Icons.check_circle_outline,
          color: theme.colorScheme.primary,
          text: strings.settingsLocalizationLocalReady,
        ),
        const SizedBox(height: CompactTokens.space4),
        Text(
          strings.settingsLocalizationLocalSize(
            _formatBytes(state.installedBytes),
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.canDelete) ...[
          const SizedBox(height: CompactTokens.space4),
          TextButton(
            onPressed: onRemove,
            child: Text(strings.settingsLocalizationLocalDelete),
          ),
        ],
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  final LocalModelState state;
  final VoidCallback onDownload;

  const _Failed({required this.state, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final text = state.problem == TranslationAssetProblem.modelCorrupt
        ? strings.settingsLocalizationLocalCorrupt
        : state.message ?? strings.settingsLocalizationLocalMissing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
          text: text,
        ),
        const SizedBox(height: CompactTokens.space8),
        FilledButton(
          onPressed: onDownload,
          child: Text(strings.settingsLocalizationLocalDownload),
        ),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  final String text;

  const _Busy({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: CompactTokens.space8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Line({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: CompactTokens.space8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const unit = 1024 * 1024;
  if (bytes < 1024 * unit) return '${(bytes / unit).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * unit)).toStringAsFixed(2)} GB';
}
