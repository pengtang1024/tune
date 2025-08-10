import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/core/config/theme_config.dart';
import 'package:tune/features/home/presentation/bloc/localization/localization_bloc.dart';
import 'package:tune/features/home/presentation/bloc/localization/localization_event.dart';
import 'package:tune/features/home/presentation/bloc/localization/localization_state.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_event.dart';
import 'package:tune/features/home/presentation/bloc/theme/theme_state.dart';
import 'package:tune/l10n/app_localizations.dart'; // 使用生成的本地化文件

/// 设置页面
///
/// 该页面允许用户配置应用程序的各种设置，包括语言和主题。
/// 用户可以在此页面切换应用程序的语言和主题样式。
@RoutePage()
class SettingsPage extends StatefulWidget {
  /// 创建设置页面实例
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 保存当前选中的语言代码
  late String _selectedLanguage;

  // 保存当前选中的主题名称
  late String _selectedTheme;

  // 保存当前选中的主题模式
  late ThemeMode _selectedThemeMode;

  // 保存当前选中的字体
  late String _selectedFontFamily;

  @override
  void initState() {
    super.initState();

    // 初始化语言和主题设置
    _selectedLanguage = AppConfig.locale;
    _selectedTheme = _getValidThemeName(AppConfig.theme);
    _selectedThemeMode = AppConfig.themeMode; // 从配置中读取主题模式
    _selectedFontFamily = AppConfig.fontFamily.value; // 从配置中读取字体
  }

  /// 获取有效的主题名称
  ///
  /// 验证并返回有效的主题名称，如果提供的主题名称无效则返回默认主题
  String _getValidThemeName(String? themeName) {
    // 有效的主题列表
    const validThemes = [
      'trendyElectro',
      'minimalGray',
      'natureForest',
      'cyberNeon',
      'warmHealing'
    ];

    // 如果主题名称有效，直接返回
    if (themeName != null && validThemes.contains(themeName)) {
      return themeName;
    }

    // 否则返回默认主题
    return 'trendyElectro';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            // 更新语言设置
            if (localizationState is LocalizationChangedState) {
              _selectedLanguage = localizationState.locale;
            } else {
              _selectedLanguage = AppConfig.locale;
            }

            // 更新主题设置
            if (themeState is ThemeChangedState) {
              _selectedTheme = _getValidThemeName(themeState.themeName);
              _selectedThemeMode = themeState.themeMode;
              _selectedFontFamily = (themeState).fontFamily?.value ?? AppConfig.fontFamily.value;
            } else {
              _selectedTheme = _getValidThemeName(AppConfig.theme);
              _selectedThemeMode = AppConfig.themeMode;
              _selectedFontFamily = AppConfig.fontFamily.value; // 从配置中读取字体
            }

            final localizations = AppLocalizations.of(context)!;

            return Scaffold(
              appBar: AppBar(
                title: Text(localizations.settings_title),
              ),
              body: ListView(
                children: [
                  // 语言设置部分
                  _buildLanguageSelector(context),

                  // 字体设置部分
                  _buildFontSelector(context),

                  // 主题设置部分
                  _buildThemeSelector(context),

                  // 主题模式设置部分
                  _buildThemeModeSelector(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 构建语言选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户从支持的语言列表中选择一种语言。
  /// 当用户选择新语言时，会更新应用程序的语言设置并保存到本地存储。
  Widget _buildLanguageSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(
        localizations.settings_page_language,
        style: Theme.of(context).textTheme.titleMedium, // 统一使用titleMedium样式
      ),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text(
              'English',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: Text(
              '中文',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLanguage = newValue;
            });

            // 更新语言设置
            context.read<LocalizationBloc>().add(
                  LanguageChangedEvent(newValue),
                );

            // 保存语言设置到本地存储
            AppConfig.setLocale(newValue);
          }
        },
      ),
    );
  }

  /// 构建主题选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户从可用的主题列表中选择一个主题。
  /// 当用户选择新主题时，会更新应用程序的主题设置并保存到本地存储。
  Widget _buildThemeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(
        localizations.settings_page_theme,
        style: Theme.of(context).textTheme.titleMedium, // 统一使用titleMedium样式
      ),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        items: [
          DropdownMenuItem(
            value: 'trendyElectro',
            child: Text(
              localizations.theme_name_trendy_electro,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: 'minimalGray',
            child: Text(
              localizations.theme_name_minimal_gray,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: 'natureForest',
            child: Text(
              localizations.theme_name_nature_forest,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: 'cyberNeon',
            child: Text(
              localizations.theme_name_cyber_neon,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: 'warmHealing',
            child: Text(
              localizations.theme_name_warm_healing,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTheme = newValue;
            });

            // 更新主题设置
            context.read<ThemeBloc>().add(
                  ThemeChangedEvent(_selectedThemeMode, themeName: newValue),
                );

            // 注意：不再直接调用AppConfig.setTheme，让ThemeBloc处理
          }
        },
      ),
    );
  }

  /// 构建主题模式选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户选择主题模式（浅色、深色或系统默认）。
  /// 当用户选择新模式时，会更新应用程序的主题模式设置并保存到本地存储。
  Widget _buildThemeModeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(
        localizations.theme_name_system_theme,
        style: Theme.of(context).textTheme.titleMedium, // 统一使用titleMedium样式
      ),
      trailing: DropdownButton<ThemeMode>(
        value: _selectedThemeMode,
        items: [
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(
              localizations.theme_name_light_mode,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(
              localizations.theme_name_dark_mode,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(
              localizations.theme_name_system_theme,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
        onChanged: (ThemeMode? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedThemeMode = newValue;
            });

            // 更新主题模式设置
            context.read<ThemeBloc>().add(
                  ThemeChangedEvent(newValue, themeName: _selectedTheme),
                );

            // 保存主题模式设置到本地存储
            AppConfig.setThemeMode(newValue);
          }
        },
      ),
    );
  }

  /// 构建字体选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户从可用的字体列表中选择一个字体。
  /// 当用户选择新字体时，会更新应用程序的字体设置并保存到本地存储。
  Widget _buildFontSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // 定义可用的字体列表
    const fontOptions = [
      'Default',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
    ];

    // 定义字体显示名称映射
    final Map<String, String> fontFamilyNames = {
      'Default': 'Default',
      'Roboto': 'Roboto',
      'Open Sans': 'Open Sans',
      'Lato': 'Lato',
      'Montserrat': 'Montserrat',
    };

    return ListTile(
      title: Text(
        localizations.settings_page_font,
        style: Theme.of(context).textTheme.titleMedium, // 统一使用titleMedium样式
      ),
      trailing: DropdownButton<String>(
        value: _selectedFontFamily,
        items: fontOptions.map((font) {
          return DropdownMenuItem(
            value: font,
            child: Text(
              fontFamilyNames[font]!,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedFontFamily = newValue;
            });

            // 更新字体设置
            context.read<ThemeBloc>().add(
              FontFamilyChangedEvent(AppFontFamily.fromValue(newValue)),
            );
          }
        },
      ),
    );
  }
}
