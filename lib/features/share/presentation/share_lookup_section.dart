import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/providers/local_components_provider.dart';
import 'package:tune/features/share/application/share_session_controller.dart';
import 'package:tune/features/share/domain/share_lookup_status.dart';
import 'package:tune/features/share/presentation/share_pane.dart';

/// 查重的配置段：填 AcoustID 的 client key，并说清查重现在能不能跑。
///
/// 状态不是装饰：没 key 时查重什么都不查，闸门里那一格是「没查」，所以这段的
/// 文案必须能让用户看出自己现在处于哪一步。
class ShareLookupSection extends ConsumerStatefulWidget {
  const ShareLookupSection({super.key});

  @override
  ConsumerState<ShareLookupSection> createState() => _ShareLookupSectionState();
}

class _ShareLookupSectionState extends ConsumerState<ShareLookupSection> {
  final _controller = TextEditingController();
  bool _installing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(shareLookupStatusProvider);
    return ShareCard(
      title: context.loc.shareLookupTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.shareLookupSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.loc.shareLookupHint,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _save(context),
                child: Text(context.loc.shareLookupSave),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusText(context, status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (status.valueOrNull == ShareLookupStatus.missingFpcalc)
                TextButton(
                  onPressed: _installing ? null : () => _install(context),
                  child: Text(
                    _installing
                        ? context.loc.shareLookupDownloading
                        : context.loc.shareLookupDownload,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(
    BuildContext context,
    AsyncValue<ShareLookupStatus> status,
  ) {
    final loc = context.loc;
    return switch (status.valueOrNull) {
      ShareLookupStatus.ready => loc.shareLookupReady,
      ShareLookupStatus.missingKey => loc.shareLookupMissingKey,
      ShareLookupStatus.missingFpcalc => loc.shareLookupMissingFpcalc,
      null => loc.shareLookupMissingKey,
    };
  }

  /// 装 `fpcalc`：组件登记在注册表里，这里直接走安装器，顺手把状态刷掉。
  Future<void> _install(BuildContext context) async {
    setState(() => _installing = true);
    try {
      final components = await ref.read(localComponentsProvider.future);
      await components.installer.install(
        LocalComponentRegistry.fingerprintRuntime,
      );
      ref.invalidate(shareLookupStatusProvider);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.shareLookupDownloadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _installing = false);
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    final notifier = ref.read(shareSessionProvider.notifier);
    await notifier.saveAcoustIdKey(_controller.text);
    ref.invalidate(shareLookupStatusProvider);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.loc.shareLookupSaved)),
    );
  }
}
