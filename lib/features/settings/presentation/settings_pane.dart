import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';

class SettingsPane extends ConsumerStatefulWidget {
  const SettingsPane({super.key});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space16,
          CompactTokens.space16,
          CompactTokens.space16,
          CompactTokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.settings,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '外观、语言、本地目录和在线音源',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: CompactTokens.space20),
            _Section(
              title: context.loc.theme,
              child: Wrap(
                spacing: CompactTokens.space8,
                runSpacing: CompactTokens.space8,
                children: [
                  _ThemeChip(
                    label: context.loc.system_mode,
                    mode: ThemeMode.system,
                    current: settings.themeMode,
                    onSelected: settingsController.setThemeMode,
                  ),
                  _ThemeChip(
                    label: context.loc.light_mode,
                    mode: ThemeMode.light,
                    current: settings.themeMode,
                    onSelected: settingsController.setThemeMode,
                  ),
                  _ThemeChip(
                    label: context.loc.dark_mode,
                    mode: ThemeMode.dark,
                    current: settings.themeMode,
                    onSelected: settingsController.setThemeMode,
                  ),
                ],
              ),
            ),
            _Section(
              title: context.loc.language,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '界面语言',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: _LanguageDropdown(
                      locale: settings.locale,
                      onChanged: settingsController.setLocale,
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: context.loc.music_library,
              child: _LibrarySettings(
                settings: settings,
                scanning: scanning,
                canScan: libraryReady && !busy,
                onAddFolder: _pickDirectory,
                onRemoveFolder: settingsController.removeScanPath,
                onScan: _scan,
                onClear: libraryReady && !busy ? _clearLibrary : null,
              ),
            ),
            const MusicSourcesSection(),
            _Section(
              title: context.loc.about,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tune',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: CompactTokens.space8),
                      Text(
                        'v${AppVersion.version}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '本地优先的紧凑音乐播放器',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    _showMessage(
      state?.errorMessage ?? state?.statusMessage ?? context.loc.scan_completed,
    );
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CompactTokens.space8),
          child,
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final ThemeMode current;
  final ValueChanged<ThemeMode> onSelected;

  const _ThemeChip({
    required this.label,
    required this.mode,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = mode == current;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(mode),
      showCheckmark: false,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      backgroundColor: theme.colorScheme.surfaceContainer,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: CompactTokens.borderRadius6,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onChanged;

  const _LanguageDropdown({required this.locale, required this.onChanged});

  static const _locales = <Locale>[
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('ru'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: CompactTokens.borderRadius6,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: locale,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 16),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surfaceContainer,
          items: _locales
              .map(
                (item) => DropdownMenuItem<Locale>(
                  value: item,
                  child: Text(_label(item)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  String _label(Locale item) {
    return switch (item.languageCode) {
      'zh' => item.countryCode == 'TW' ? '繁體中文' : '简体中文',
      'en' => 'English',
      'ja' => '日本語',
      'ko' => '한국어',
      'de' => 'Deutsch',
      'fr' => 'Français',
      'es' => 'Español',
      'ru' => 'Русский',
      _ => item.toLanguageTag(),
    };
  }
}

class _LibrarySettings extends StatelessWidget {
  final SettingsState settings;
  final bool scanning;
  final bool canScan;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onRemoveFolder;
  final VoidCallback onScan;
  final VoidCallback? onClear;

  const _LibrarySettings({
    required this.settings,
    required this.scanning,
    required this.canScan,
    required this.onAddFolder,
    required this.onRemoveFolder,
    required this.onScan,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '默认目录',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: muted,
          ),
        ),
        const SizedBox(height: CompactTokens.space4),
        for (final path in settings.defaultScanPaths)
          _PathTile(path: path, onRemove: null),
        if (settings.defaultScanPaths.isEmpty)
          Text(
            '未找到默认音乐目录',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: muted,
            ),
          ),
        if (settings.customScanPaths.isNotEmpty) ...[
          const SizedBox(height: CompactTokens.space8),
          Text(
            '自定义目录',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: muted,
            ),
          ),
          const SizedBox(height: CompactTokens.space4),
          for (final path in settings.customScanPaths)
            _PathTile(path: path, onRemove: () => onRemoveFolder(path)),
        ],
        const SizedBox(height: CompactTokens.space8),
        Wrap(
          spacing: CompactTokens.space8,
          runSpacing: CompactTokens.space8,
          children: [
            OutlinedButton.icon(
              onPressed: onAddFolder,
              style: _compactButtonStyle(context),
              icon: const Icon(Icons.create_new_folder_outlined, size: 15),
              label: const Text('添加文件夹'),
            ),
            OutlinedButton.icon(
              onPressed: canScan ? onScan : null,
              style: _compactButtonStyle(context),
              icon: scanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 15),
              label: Text(scanning ? context.loc.scanning : '立即扫描'),
            ),
            TextButton.icon(
              onPressed: onClear,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(
                  horizontal: CompactTokens.space8,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: theme.colorScheme.error,
                textStyle: const TextStyle(fontSize: 11),
              ),
              icon: const Icon(Icons.delete_sweep_outlined, size: 15),
              label: const Text('清空音乐库'),
            ),
          ],
        ),
        const SizedBox(height: CompactTokens.space8),
        Text(
          '扫描只读取音频文件，不会修改或删除磁盘内容。',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: muted,
          ),
        ),
      ],
    );
  }

  ButtonStyle _compactButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: CompactTokens.space8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 11),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class _PathTile extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;

  const _PathTile({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: CompactTokens.space4),
      padding: const EdgeInsets.only(
        left: CompactTokens.space8,
        right: CompactTokens.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: CompactTokens.borderRadius6,
      ),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 14, color: muted),
          const SizedBox(width: CompactTokens.space6),
          Expanded(
            child: Text(
              path,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null)
            SizedBox(
              width: 26,
              height: 26,
              child: IconButton(
                tooltip: context.loc.remove,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: muted,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
