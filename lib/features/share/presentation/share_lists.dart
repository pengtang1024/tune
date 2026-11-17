import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/share/application/share_session_controller.dart';
import 'package:tune/features/share/domain/share_provenance.dart';
import 'package:tune/features/share/domain/share_session_state.dart';
import 'package:tune/features/share/presentation/share_pane.dart';

/// 「我要分享的」：本机文件 + 一句缘起声明。
class ShareLocalItemsSection extends ConsumerWidget {
  const ShareLocalItemsSection({super.key, required this.state});

  final ShareSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shareSessionProvider.notifier);
    return ShareCard(
      title: context.loc.shareYourItems,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _add(context, controller),
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.loc.shareAddFile),
          ),
          if (state.localItems.isEmpty) ...[
            const SizedBox(height: 10),
            _Empty(text: context.loc.shareEmpty),
          ] else
            for (final item in state.localItems)
              _Row(
                title: item.name,
                subtitle: _provenanceLabel(context, item.provenance),
                action: TextButton(
                  onPressed: () {
                    controller.revokeLocal(item.contentId);
                    _toast(context, context.loc.shareRevoked);
                  },
                  child: Text(context.loc.shareRevoke),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    ShareSessionController controller,
  ) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final path = picked?.files.singleOrNull?.path;
    if (path == null || !context.mounted) {
      return;
    }
    final provenance = await _askProvenance(context);
    if (provenance == null || !context.mounted) {
      return;
    }
    final failure = await controller.addLocalFile(path, provenance);
    if (!context.mounted) {
      return;
    }
    _toast(context, switch (failure) {
      null => context.loc.shareDeclared,
      'missing' => context.loc.shareFileMissing,
      'closed' => context.loc.shareRoomClosed,
      _ => context.loc.shareRejected,
    });
  }

  Future<ShareProvenance?> _askProvenance(BuildContext context) {
    return showDialog<ShareProvenance>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.loc.shareDeclareTitle),
        children: [
          for (final provenance in ShareProvenance.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(provenance),
              child: Text(_provenanceLabel(context, provenance)),
            ),
        ],
      ),
    );
  }

  static String _provenanceLabel(BuildContext context, ShareProvenance value) {
    return switch (value) {
      ShareProvenance.generated => context.loc.shareDeclareGenerated,
      ShareProvenance.ownRecording => context.loc.shareDeclareOwnRecording,
      ShareProvenance.ownComposition => context.loc.shareDeclareOwnComposition,
      ShareProvenance.licensed => context.loc.shareDeclareLicensed,
    };
  }
}

/// 「房间里的」：别人分享的条目，收之前先看到是谁的。
class ShareRoomItemsSection extends ConsumerWidget {
  const ShareRoomItemsSection({super.key, required this.state});

  final ShareSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shareSessionProvider.notifier);
    return ShareCard(
      title: context.loc.shareRoomItems,
      child: state.remoteItems.isEmpty
          ? _Empty(text: context.loc.shareEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final remote in state.remoteItems)
                  _Row(
                    title: remote.item.name,
                    subtitle: remote.ownerName,
                    trailing: _progressOf(remote.item.contentId),
                    action: TextButton(
                      onPressed: () => controller.receive(remote.item),
                      child: Text(context.loc.shareReceive),
                    ),
                  ),
              ],
            ),
    );
  }

  /// 正在收的那条给一条进度，其余留空。
  Widget? _progressOf(String contentId) {
    final progress = state.inboundProgress[contentId];
    if (progress == null) {
      return null;
    }
    return SizedBox(
      width: 80,
      child: LinearProgressIndicator(value: progress.clamp(0, 1)),
    );
  }
}

/// 收件箱：已经落在本机的条目，点一下才进音乐库。
class ShareInboxSection extends ConsumerWidget {
  const ShareInboxSection({super.key, required this.state});

  final ShareSessionState state;

  /// 举报要二次确认：这条会被删掉，删了拿不回来。
  Future<void> _report(
    BuildContext context,
    ShareSessionController controller,
    ShareInboxEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(context.loc.shareReportConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.loc.shareCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.loc.shareReport),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await controller.reportEntry(entry);
    if (!context.mounted) {
      return;
    }
    _toast(context, context.loc.shareReported);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(shareSessionProvider.notifier);
    return ShareCard(
      title: context.loc.shareInbox,
      child: state.inbox.isEmpty
          ? _Empty(text: context.loc.shareEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in state.inbox)
                  _Row(
                    title: entry.item.name,
                    subtitle: entry.fromName,
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _report(context, controller, entry),
                          child: Text(context.loc.shareReport),
                        ),
                        TextButton(
                          onPressed: () async {
                            final failure = await controller.importToLibrary(
                              entry,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            _toast(context, switch (failure) {
                              null => context.loc.shareImported,
                              'missing' => context.loc.shareFileMissing,
                              _ => context.loc.shareRejected,
                            });
                          },
                          child: Text(context.loc.shareImportToLibrary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ?trailing,
          ?action,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
