import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';

class SettingsPane extends ConsumerStatefulWidget {
  const SettingsPane({super.key});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.isLoading ?? false,
        ),
      ),
    );
    final libraryReady = library.$1;
    final scanning = library.$2;
    final clearing = library.$3;
    final busy = scanning || clearing;
    final settingsController = ref.read(settingsControllerProvider.notifier);

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsPageHeader(version: AppVersion.version),
                const SizedBox(height: 20),
                SettingsInterfaceCard(
                  themeMode: settings.themeMode,
                  locale: settings.locale,
                  onThemeChanged: settingsController.setThemeMode,
                  onLocaleChanged: settingsController.setLocale,
                ),
                const SizedBox(height: 14),
                SettingsLibraryCard(
                  settings: settings,
                  scanning: scanning,
                  canScan: libraryReady && !busy,
                  onAddFolder: _pickDirectory,
                  onRemoveFolder: settingsController.removeScanPath,
                  onScan: _scan,
                  onClear: libraryReady && !busy ? _clearLibrary : null,
                ),
                const SizedBox(height: 14),
                SettingsAboutCard(version: AppVersion.version),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择音乐文件夹',
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).addScanPath(path);
    if (!mounted) return;
    _showMessage('已添加扫描目录');
  }

  Future<void> _scan() async {
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    _showMessage(state?.errorMessage ?? state?.statusMessage ?? '扫描完成');
  }

  Future<void> _clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空音乐库？'),
        content: const Text('只会清除 Tune 的扫描记录，不会删除磁盘上的音乐文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(libraryControllerProvider.notifier).clearLibrary();
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    _showMessage(state?.errorMessage ?? '音乐库已清空');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
