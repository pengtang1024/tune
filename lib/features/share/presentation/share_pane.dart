import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/share/application/share_session_controller.dart';
import 'package:tune/features/share/domain/share_session_state.dart';
import 'package:tune/features/share/presentation/share_lists.dart';
import 'package:tune/features/share/presentation/share_lookup_section.dart';
import 'package:tune/shared/ui/page_heading.dart';

/// 局域网分享页。
///
/// 它不是一级导航：入口在音源页底部的一张卡片上。整页只做房间的四个格子
/// （房间、我要分享的、房间里的、收件箱），状态全部来自会话推上来的东西。
class SharePane extends ConsumerWidget {
  const SharePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shareSessionProvider);
    final session = ref.read(shareSessionProvider.notifier);
    final state = async.value ?? ShareSessionState.idle;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          CompactTokens.pageTopPadding,
          CompactTokens.pageGutter,
          CompactTokens.pageGutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              eyebrow: context.loc.sourcesEyebrow,
              title: context.loc.shareTitle,
              subtitle: context.loc.shareSubtitle,
            ),
            const SizedBox(height: 24),
            _RoomSection(
              state: state,
              onHost: session.hostRoom,
              onJoin: () => _askInvite(context, session),
              onClose: session.closeRoom,
            ),
            const SizedBox(height: 16),
            if (state.isActive) ...[
              ShareLocalItemsSection(state: state),
              const SizedBox(height: 16),
              ShareRoomItemsSection(state: state),
              const SizedBox(height: 16),
            ],
            ShareInboxSection(state: state),
            const SizedBox(height: 16),
            const ShareLookupSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _askInvite(
    BuildContext context,
    ShareSessionController session,
  ) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.loc.shareJoinRoom),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.loc.shareInviteHint),
          maxLines: 2,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.loc.shareJoinRoom),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) {
      return;
    }
    try {
      await session.joinRoom(text);
    } on FormatException {
      if (context.mounted) {
        _toast(context, context.loc.shareInviteInvalid);
      }
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoomSection extends StatelessWidget {
  const _RoomSection({
    required this.state,
    required this.onHost,
    required this.onJoin,
    required this.onClose,
  });

  final ShareSessionState state;
  final Future<void> Function() onHost;
  final Future<void> Function() onJoin;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final idle = !state.isActive;
    return ShareCard(
      title: context.loc.shareHostRoom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (idle)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onHost,
                  icon: const Icon(Icons.wifi_tethering, size: 18),
                  label: Text(context.loc.shareHostRoom),
                ),
                OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.login, size: 18),
                  label: Text(context.loc.shareJoinRoom),
                ),
              ],
            )
          else ...[
            SelectableText(
              '${context.loc.shareInviteCode} · ${state.inviteCode ?? ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              '${context.loc.shareLocalPort} · ${state.port}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              state.isPubliclyReachable
                  ? context.loc.shareNetworkReachable
                  : context.loc.shareNetworkLanOnly,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: state.inviteCode ?? ''),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(context.loc.shareCopyInvite),
                ),
                TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(context.loc.shareCloseRoom),
                ),
              ],
            ),
          ],
          if (state.peers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${context.loc.shareMembers} · ${state.peers.length}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final peer in state.peers)
                  Chip(
                    label: Text(peer.displayName),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 每块内容的统一外壳，避免各段自己长成另一种样子。
class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CompactTokens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 每块内容的统一外壳，列表段也用它。
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _CardShell(title: title, child: child);
}
