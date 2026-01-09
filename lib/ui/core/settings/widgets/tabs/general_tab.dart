import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../components/window_size_option_button.dart';

class GeneralTab extends ConsumerStatefulWidget {
  const GeneralTab({super.key});

  @override
  ConsumerState<GeneralTab> createState() => _GeneralTabState();
}


// 主题预览卡片组件
class ThemePreviewCard extends StatelessWidget {
  final ThemeMode themeMode;

  const ThemePreviewCard({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    // 创建主题预览卡片
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: Row(
        children: [
          // 系统主题预览
          Expanded(
            child: _buildThemePreviewSection(
              context: context,
              label: context.loc.system_mode_preview,
              themeData: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
              ),
              isActive: themeMode == ThemeMode.system,
            ),
          ),
          const SizedBox(width: 8),
          // 浅色主题预览
          Expanded(
            child: _buildThemePreviewSection(
              context: context,
              label: context.loc.light_mode_preview,
              themeData: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
              ),
              isActive: themeMode == ThemeMode.light,
            ),
          ),
          const SizedBox(width: 8),
          // 深色主题预览
          Expanded(
            child: _buildThemePreviewSection(
              context: context,
              label: context.loc.dark_mode_preview,
              themeData: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
              ),
              isActive: themeMode == ThemeMode.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreviewSection({
    required BuildContext context,
    required String label,
    required ThemeData themeData,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? themeData.colorScheme.primary.withValues(alpha: 0.2)
            : themeData.scaffoldBackgroundColor,
        border: Border.all(
          color: isActive
              ? themeData.colorScheme.primary
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: themeData.textTheme.bodySmall?.color,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: themeData.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: themeData.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: themeData.colorScheme.surface,
                  border: Border.all(color: themeData.dividerColor),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneralTabState extends ConsumerState<GeneralTab> {
  bool _autoStart = false;
  String _windowSize = 'medium'; // small, medium, large
  bool _defaultPlayer = false;
  bool _desktopLyrics = false;
  bool _enableNotifications = true;
  double _fontSize = 16.0; // 默认字体大小
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    // 使用全局的sharedPreferencesServiceProvider
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

  // 获取语言显示名称
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

  Future<void> _saveSetting(String key, dynamic value) async {
    // 使用全局的sharedPreferencesServiceProvider
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
    // 监听持久化服务的变化，当设置改变时刷新UI
    ref.watch(sharedPreferencesServiceProvider);
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.general_settings,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 窗口大小
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.window_size,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      WindowSizeOptionButton(
                        size: 'small',
                        currentSize: _windowSize,
                        label: context.loc.small,
                        description: '',
                        onSelected: (value) {
                          setState(() {
                            _windowSize = value;
                          });
                          _saveSetting('window_size', value);
                        },
                      ),
                      const SizedBox(width: 8),
                      WindowSizeOptionButton(
                        size: 'medium',
                        currentSize: _windowSize,
                        label: context.loc.medium,
                        description: '',
                        onSelected: (value) {
                          setState(() {
                            _windowSize = value;
                          });
                          _saveSetting('window_size', value);
                        },
                      ),
                      const SizedBox(width: 8),
                      WindowSizeOptionButton(
                        size: 'large',
                        currentSize: _windowSize,
                        label: context.loc.large,
                        description: '',
                        onSelected: (value) {
                          setState(() {
                            _windowSize = value;
                          });
                          _saveSetting('window_size', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 语言设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text(
                        context.loc.language,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  DropdownButton<Locale>(
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 主题设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          appBarState.themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : appBarState.themeMode == ThemeMode.dark
                                  ? Icons.dark_mode
                                  : Icons.auto_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.loc.theme,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  DropdownButton<ThemeMode>(
                    value: appBarState.themeMode,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                    ],
                    onChanged: (themeMode) {
                      if (themeMode != null) {
                        appBarNotifier.updateThemeMode(themeMode);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 开机运行
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.auto_start,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _autoStart,
                        onChanged: (value) {
                          setState(() {
                            _autoStart = value;
                          });
                          _saveSetting('auto_start', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.auto_start_description,
                    style: const TextStyle(color: Colors.grey),
                  ),

                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 默认播放器
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.default_player,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _defaultPlayer,
                        onChanged: (value) {
                          setState(() {
                            _defaultPlayer = value;
                          });
                          _saveSetting('default_player', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.default_player_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 桌面歌词
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.desktop_lyrics,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _desktopLyrics,
                        onChanged: (value) {
                          setState(() {
                            _desktopLyrics = value;
                          });
                          _saveSetting('desktop_lyrics', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.desktop_lyrics_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 通知设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.enable_notifications,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _enableNotifications,
                        onChanged: (value) {
                          setState(() {
                            _enableNotifications = value;
                          });
                          _saveSetting('enable_notifications', value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.enable_notifications_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 字体大小设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.font_size,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(context.loc.small, style: const TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12.0,
                          max: 24.0,
                          divisions: 12,
                          label: _fontSize.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                            });
                            _saveSetting('font_size', value);
                          },
                        ),
                      ),
                      Text(context.loc.large, style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.font_size_description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}