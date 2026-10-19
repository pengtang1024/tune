import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime_factory.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';

/// Settings section that owns the visible source list.
///
/// It composes three controllers without duplicating their state: source
/// configuration comes from [musicSourcesControllerProvider], scan results
/// come from the library controller, and the startup switch lives in settings.
class MusicSourcesSection extends ConsumerWidget {
  const MusicSourcesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sourcesAsync = ref.watch(musicSourcesControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select((value) {
        final state = value.valueOrNull;
        return (
          scanning: state?.isScanning ?? false,
          loading: state?.isLoading ?? false,
          progress: state?.scanProgress ?? 0.0,
          summaries:
              state?.sourceSummaries ?? const <String, SourceScanSummary>{},
        );
      }),
    );
    final settings = ref.watch(settingsControllerProvider);
    final scanning = library.scanning;
    final busy = scanning || library.loading;

    final sources = sourcesAsync.valueOrNull?.sources ?? const [];
    final lastScanAt =
        sourcesAsync.valueOrNull?.lastScanAt ?? const <String, DateTime>{};
    final sourceService = ref.watch(musicSourceServiceProvider);
    final canScan =
        !busy &&
        sources.any(
          (source) => source.enabled && sourceService.supportsConfig(source),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '音源',
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CompactTokens.space12,
              vertical: CompactTokens.space8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: CompactTokens.borderRadius8,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '启动时自动扫描',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '所有已启用音源都会在启动后自动刷新，失败不会影响本地库。',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.autoScanOnStartup,
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .setAutoScanOnStartup(value),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                if (scanning) ...[
                  const SizedBox(height: CompactTokens.space6),
                  LinearProgressIndicator(
                    value: library.progress,
                    minHeight: 2,
                    backgroundColor: theme.colorScheme.outlineVariant,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          if (sourcesAsync.isLoading && !sourcesAsync.hasValue)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CompactTokens.space8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            for (final source in sources)
              _SourceTile(
                source: source,
                summary: library.summaries[source.id],
                lastScanAt: lastScanAt[source.id],
                busy: busy,
              ),
          const SizedBox(height: CompactTokens.space8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: canScan ? () => _scanAll(context, ref) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CompactTokens.space8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: scanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 15),
                label: const Text('扫描全部音源'),
              ),
              if (isMusicPluginRuntimeSupported) ...[
                const SizedBox(width: CompactTokens.space8),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _importPlugin(context, ref),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CompactTokens.space8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  icon: const Icon(Icons.extension_outlined, size: 15),
                  label: const Text('导入插件'),
                ),
              ],
              const SizedBox(width: CompactTokens.space8),
              Flexible(
                child: Text(
                  '含远程音源时可能需要数秒',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanAll(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!context.mounted) return;

    final state = ref.read(libraryControllerProvider).valueOrNull;
    final message = state?.errorMessage ?? state?.statusMessage ?? '扫描已完成';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _importPlugin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入音乐插件'),
        content: const Text(
          '插件是第三方 JavaScript 代码，会在应用内执行并可访问网络。'
          '请只导入你信任的来源。导入后需要填写搜索关键词才会启用。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['js'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    final file = result.files.first;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage(context, '无法读取插件文件');
      return;
    }
    if (bytes.length > 2 * 1024 * 1024) {
      _showMessage(context, '插件文件不能超过 2 MB');
      return;
    }

    final script = utf8.decode(bytes, allowMalformed: true);
    if (!context.mounted) return;

    try {
      final controller = ref.read(musicSourcesControllerProvider.notifier);
      final config = await controller.installPlugin(
        originalName: file.name,
        script: script,
      );
      if (!context.mounted) return;

      final fields = ref.read(musicSourceServiceProvider).fieldsFor(config);
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _SourceSettingsDialog(source: config, fields: fields),
      );
      if (saved == true) {
        await controller.setEnabled(config.id, true);
      }
      if (!context.mounted) return;
      _showMessage(
        context,
        saved == true
            ? '已导入并启用 ${config.name}'
            : '已导入 ${config.name}，填写关键词并开启后会参与扫描',
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, '导入插件失败：$error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }
}

class _SourceTile extends ConsumerWidget {
  final MusicSourceConfig source;
  final SourceScanSummary? summary;
  final DateTime? lastScanAt;
  final bool busy;

  const _SourceTile({
    required this.source,
    required this.summary,
    required this.lastScanAt,
    required this.busy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sourceService = ref.watch(musicSourceServiceProvider);
    final supported = sourceService.supportsConfig(source);
    final fields = sourceService.fieldsFor(source);
    final configured = sourceService.isConfigured(source);
    final status = _statusText(configured, fields, supported: supported);
    final statusColor = _statusColor(
      context,
      configured: configured,
      supported: supported,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: CompactTokens.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: CompactTokens.space8,
        vertical: CompactTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Row(
        children: [
          Icon(_icon(source.kind), size: 16, color: muted),
          const SizedBox(width: CompactTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: source.description,
                        child: Text(
                          source.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (source.kind != MusicSourceKind.localDirectory) ...[
                      const SizedBox(width: CompactTokens.space4),
                      _KindBadge(kind: source.kind),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: status,
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: statusColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (fields.isNotEmpty && supported)
            if (source.isPlugin)
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  tooltip: '插件操作',
                  enabled: !busy,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded, size: 15, color: muted),
                  onSelected: (value) {
                    if (value == 'config') {
                      _openSettings(context, source, fields);
                    } else if (value == 'delete') {
                      _confirmRemove(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'config',
                      height: 36,
                      child: Text('配置'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 36,
                      child: Text('删除插件'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  tooltip: '配置',
                  onPressed: busy
                      ? null
                      : () => _openSettings(context, source, fields),
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: muted,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          Switch(
            key: ValueKey('source-switch-${source.id}'),
            value: source.enabled,
            onChanged: busy || !supported
                ? null
                : (value) async {
                    final controller = ref.read(
                      musicSourcesControllerProvider.notifier,
                    );
                    if (!value || configured || fields.isEmpty) {
                      await controller.setEnabled(source.id, value);
                      return;
                    }

                    final saved = await _openSettings(context, source, fields);
                    if (!saved || !context.mounted) return;
                    await controller.setEnabled(source.id, true);
                  },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _statusText(
    bool configured,
    List<MusicSourceField> fields, {
    required bool supported,
  }) {
    if (!supported) return '当前版本不支持该音源';
    if (!source.enabled) return '已关闭';
    if (!configured) {
      final required = fields.where((field) => field.required);
      final hint = required.isEmpty ? '' : required.first.hint;
      return hint.isEmpty ? '需要配置' : '需要配置：$hint';
    }

    final result = summary;
    if (result == null) {
      if (lastScanAt != null) return '上次扫描 ${_formatTime(lastScanAt!)}';
      return source.kind == MusicSourceKind.localDirectory
          ? '启动后自动扫描本地目录'
          : '等待首次扫描';
    }

    switch (result.status) {
      case SourceScanStatus.success:
        return '已扫描 ${result.songCount} 首 · ${_formatTime(result.scannedAt)}';
      case SourceScanStatus.needsConfiguration:
        return result.message ?? '需要配置';
      case SourceScanStatus.skipped:
        return result.message ?? '已跳过';
      case SourceScanStatus.failed:
        return result.message ?? '扫描失败';
    }
  }

  Color _statusColor(
    BuildContext context, {
    required bool configured,
    required bool supported,
  }) {
    final theme = Theme.of(context);
    if (!supported) return theme.colorScheme.error;
    if (!source.enabled) return theme.colorScheme.onSurfaceVariant;
    if (!configured) return theme.colorScheme.tertiary;
    if (summary?.status == SourceScanStatus.failed) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurfaceVariant;
  }

  Future<bool> _openSettings(
    BuildContext context,
    MusicSourceConfig source,
    List<MusicSourceField> fields,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _SourceSettingsDialog(source: source, fields: fields),
    );
    return saved == true;
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除插件？'),
        content: Text('将删除 ${source.name} 的脚本、配置以及已扫描的歌曲。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(musicSourcesControllerProvider.notifier)
        .removePlugin(source.id);
    if (!context.mounted) return;
    await ref.read(libraryControllerProvider.notifier).dropSource(source.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已删除 ${source.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _KindBadge extends StatelessWidget {
  final MusicSourceKind kind;

  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (kind) {
      MusicSourceKind.localDirectory => '本地',
      MusicSourceKind.openCatalog => '开放曲库',
      MusicSourceKind.openApi => 'API',
      MusicSourceKind.plugin => '插件',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SourceSettingsDialog extends ConsumerStatefulWidget {
  final MusicSourceConfig source;
  final List<MusicSourceField> fields;

  const _SourceSettingsDialog({required this.source, required this.fields});

  @override
  ConsumerState<_SourceSettingsDialog> createState() =>
      _SourceSettingsDialogState();
}

class _SourceSettingsDialogState extends ConsumerState<_SourceSettingsDialog> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(
          text: widget.source.setting(field.key) ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('配置 ${widget.source.name}'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in widget.fields) ...[
                TextField(
                  controller: _controllers[field.key],
                  decoration: InputDecoration(
                    labelText: field.label,
                    hintText: field.hint,
                    errorText: _errors[field.key],
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: field.numeric
                      ? const TextInputType.numberWithOptions(decimal: false)
                      : TextInputType.text,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Future<void> _save() async {
    _errors.clear();
    final settings = <String, String>{};

    for (final field in widget.fields) {
      final value = _controllers[field.key]?.text.trim() ?? '';
      if (field.required && value.isEmpty) {
        _errors[field.key] = '请填写${field.label}';
      }
      if (field.numeric && value.isNotEmpty && int.tryParse(value) == null) {
        _errors[field.key] = '请输入数字';
      }
      settings[field.key] = value;
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }

    await ref
        .read(musicSourcesControllerProvider.notifier)
        .updateSettings(widget.source.id, settings);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

IconData _icon(MusicSourceKind kind) {
  return switch (kind) {
    MusicSourceKind.localDirectory => Icons.folder_outlined,
    MusicSourceKind.openCatalog => Icons.public_rounded,
    MusicSourceKind.openApi => Icons.api_rounded,
    MusicSourceKind.plugin => Icons.extension_rounded,
  };
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return sameDay ? '$hour:$minute' : '${time.month}-${time.day} $hour:$minute';
}
