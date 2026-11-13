import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component.dart';

/// The state of the two translation components, without a second installer.
///
/// The runtime and the model are downloaded one by one on the components
/// page; here the card only reports the pair and offers the missing halves
/// (docs/local-components.md §5).
class SettingsLocalizationLocalBlock extends StatelessWidget {
  final LocalComponentState runtime;
  final LocalComponentState model;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const SettingsLocalizationLocalBlock({
    super.key,
    required this.runtime,
    required this.model,
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
    final downloading = runtime.phase == LocalComponentPhase.downloading
        ? runtime
        : model.phase == LocalComponentPhase.downloading
        ? model
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (downloading != null)
          _Downloading(state: downloading, onCancel: onCancel)
        else if (runtime.usable && model.usable)
          _Ready(
            state: LocalComponentState(
              LocalComponentPhase.ready,
              installedBytes: runtime.installedBytes + model.installedBytes,
              systemAvailable: runtime.systemAvailable || model.systemAvailable,
              canDelete: runtime.canDelete || model.canDelete,
            ),
            onRemove: () => _confirmRemove(context, onRemove),
          )
        else if (runtime.phase == LocalComponentPhase.failed ||
            model.phase == LocalComponentPhase.failed)
          _Failed(onDownload: onDownload)
        else if (runtime.phase == LocalComponentPhase.checking ||
            model.phase == LocalComponentPhase.checking)
          _Busy(text: strings.settingsLocalizationLocalDownloadHint)
        else
          _NotInstalled(
            hint: strings.settingsLocalizationLocalDownloadHint,
            onDownload: onDownload,
          ),
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
  final LocalComponentState state;
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
                  ? formatComponentBytes(state.received)
                  : '${(progress * 100).round()}% · '
                        '${formatComponentBytes(state.received)}'
                        ' / ${formatComponentBytes(state.total)}',
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
  final LocalComponentState state;
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
        if (state.systemAvailable) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(
            strings.settingsLocalComponentsSystemHint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (state.installedBytes > 0) ...[
          const SizedBox(height: CompactTokens.space4),
          Text(
            strings.settingsLocalizationLocalSize(
              formatComponentBytes(state.installedBytes),
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
  final VoidCallback onDownload;

  const _Failed({required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
          text: strings.settingsLocalizationLocalCorrupt,
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
    return Row(
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: CompactTokens.space8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
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

/// Human bytes, shared by the translation block and the components card.
String formatComponentBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const unit = 1024 * 1024;
  if (bytes < 1024 * unit) return '${(bytes / unit).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * unit)).toStringAsFixed(2)} GB';
}
