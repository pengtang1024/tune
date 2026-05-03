import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/settings_item.dart';

class GeneralTab extends ConsumerStatefulWidget {
  const GeneralTab({super.key});

  @override
  ConsumerState<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<GeneralTab> {
  bool _autoStart = false;
  String _windowSize = 'medium';
  bool _defaultPlayer = false;
  bool _desktopLyrics = false;
  bool _enableNotifications = true;
  double _fontSize = 16.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    setState(() {
      _autoStart = persistenceService.getBool('auto_start') ?? false;
      _windowSize = persistenceService.getString('window_size') ?? 'medium';
      _defaultPlayer = persistenceService.getBool('default_player') ?? false;
      _desktopLyrics = persistenceService.getBool('desktop_lyrics') ?? false;
      _enableNotifications = persistenceService.getBool('enable_notifications') ?? true;
      _fontSize = persistenceService.getDouble('font_size') ?? 16.0;
      _isLoading = false;
    });
  }

  String _getLocaleDisplayName(Locale locale, BuildContext context) {
    switch (locale.languageCode) {
      case 'en':
        return context.loc.english;
      case 'zh':
        if (locale.countryCode == 'CN') {
          return context.loc.chinese_simplified;
        } else if (locale.countryCode == 'TW') {
          return context.loc.chinese_traditional;
        }
        return context.loc.chinese;
      case 'ja':
        return context.loc.japanese;
      case 'ko':
        return context.loc.korean;
      case 'ru':
        return context.loc.russian;
      case 'de':
        return context.loc.german;
      case 'fr':
        return context.loc.french;
      case 'es':
        return context.loc.spanish;
      default:
        return locale.languageCode;
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    if (value is bool) {
      await persistenceService.setBool(key, value);
    } else if (value is String) {
      await persistenceService.setString(key, value);
    } else if (value is double) {
      await persistenceService.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sharedPreferencesServiceProvider);
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.general_settings,
            style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing24),

          // 窗口大小
          _WindowSizeSelector(
            currentSize: _windowSize,
            onSelected: (value) {
              setState(() => _windowSize = value);
              _saveSetting('window_size', value);
            },
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 语言设置
          SettingsItem(
            icon: Icons.language,
            title: context.loc.language,
            iconColor: AppDesignSystem.primary,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: appBarState.locale,
                items: appBarState.supportedLocales.map((locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(_getLocaleDisplayName(locale, context)),
                  );
                }).toList(),
                onChanged: (locale) {
                  if (locale != null) {
                    appBarNotifier.updateLocale(locale);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 主题设置
          SettingsItem(
            icon: appBarState.themeMode == ThemeMode.light
                ? Icons.light_mode
                : appBarState.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.auto_mode,
            title: context.loc.theme,
            iconColor: AppDesignSystem.primary,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: appBarState.themeMode,
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(_getThemeModeName(ThemeMode.light)),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(_getThemeModeName(ThemeMode.dark)),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(_getThemeModeName(ThemeMode.system)),
                  ),
                ],
                onChanged: (themeMode) {
                  if (themeMode != null) {
                    appBarNotifier.updateThemeMode(themeMode);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 开机运行
          SettingsItem(
            icon: Icons.power_settings_new,
            title: context.loc.auto_start,
            subtitle: context.loc.auto_start_description,
            iconColor: AppDesignSystem.success,
            trailing: Switch(
              value: _autoStart,
              onChanged: (value) {
                setState(() => _autoStart = value);
                _saveSetting('auto_start', value);
              },
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 默认播放器
          SettingsItem(
            icon: Icons.play_circle_filled,
            title: context.loc.default_player,
            subtitle: context.loc.default_player_description,
            iconColor: AppDesignSystem.secondary,
            trailing: Switch(
              value: _defaultPlayer,
              onChanged: (value) {
                setState(() => _defaultPlayer = value);
                _saveSetting('default_player', value);
              },
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 桌面歌词
          SettingsItem(
            icon: Icons.lyrics,
            title: context.loc.desktop_lyrics,
            subtitle: context.loc.desktop_lyrics_description,
            iconColor: AppDesignSystem.accent,
            trailing: Switch(
              value: _desktopLyrics,
              onChanged: (value) {
                setState(() => _desktopLyrics = value);
                _saveSetting('desktop_lyrics', value);
              },
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 通知设置
          SettingsItem(
            icon: Icons.notifications,
            title: context.loc.enable_notifications,
            subtitle: context.loc.enable_notifications_description,
            iconColor: AppDesignSystem.warning,
            trailing: Switch(
              value: _enableNotifications,
              onChanged: (value) {
                setState(() => _enableNotifications = value);
                _saveSetting('enable_notifications', value);
              },
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 字体大小设置
          _FontSizeSelector(
            fontSize: _fontSize,
            onChanged: (value) {
              setState(() => _fontSize = value);
              _saveSetting('font_size', value);
            },
          ),
        ],
      ),
    );
  }
}

class _WindowSizeSelector extends StatelessWidget {
  final String currentSize;
  final ValueChanged<String> onSelected;

  const _WindowSizeSelector({
    required this.currentSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      icon: Icons.dock,
      title: context.loc.window_size,
      iconColor: AppDesignSystem.primary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SizeButton(
            size: 'small',
            currentSize: currentSize,
            label: context.loc.small,
            onTap: () => onSelected('small'),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          _SizeButton(
            size: 'medium',
            currentSize: currentSize,
            label: context.loc.medium,
            onTap: () => onSelected('medium'),
          ),
          const SizedBox(width: AppDesignSystem.spacing8),
          _SizeButton(
            size: 'large',
            currentSize: currentSize,
            label: context.loc.large,
            onTap: () => onSelected('large'),
          ),
        ],
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String size;
  final String currentSize;
  final String label;
  final VoidCallback onTap;

  const _SizeButton({
    required this.size,
    required this.currentSize,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = size == currentSize;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppDesignSystem.primary
              : (isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral100),
          borderRadius: AppDesignSystem.borderRadius12,
        ),
        child: Text(
          label,
          style: AppDesignSystem.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral700),
            fontWeight: isSelected
                ? AppDesignSystem.fontWeightBold
                : AppDesignSystem.fontWeightMedium,
          ),
        ),
      ),
    );
  }
}

class _FontSizeSelector extends ConsumerWidget {
  final double fontSize;
  final ValueChanged<double> onChanged;

  const _FontSizeSelector({
    required this.fontSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          icon: Icons.format_size,
          title: context.loc.font_size,
          iconColor: AppDesignSystem.accent,
          trailing: null,
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing56,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    context.loc.small,
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      color: AppDesignSystem.neutral500,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: fontSize.toStringAsFixed(1),
                      onChanged: onChanged,
                    ),
                  ),
                  Text(
                    context.loc.large,
                    style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                      color: AppDesignSystem.neutral500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                context.loc.font_size_description,
                style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                  color: AppDesignSystem.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
