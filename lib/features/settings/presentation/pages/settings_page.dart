import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/localization/localization_event.dart';
import 'package:tune/core/bloc/localization/localization_state.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';
import 'package:tune/core/bloc/theme/theme_event.dart';
import 'package:tune/core/bloc/theme/theme_state.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/core/config/font_constants.dart';
import 'package:tune/core/services/app_config_service.dart';
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
  late FontFamily _selectedFontFamily;

  @override
  void initState() {
    super.initState();

    // 初始化语言和主题设置
    _selectedLanguage = AppConfigService.locale;
    _selectedTheme = _getValidThemeName(AppConfigService.theme);
    _selectedThemeMode = AppConfigService.themeMode; // 从配置中读取主题模式
    _selectedFontFamily = AppConfigService.fontFamily; // 从配置中读取字体
  }

  /// 获取有效的主题名称
  String _getValidThemeName(String themeName) {
    // 如果主题名称有效，直接返回
    if (AppConfig.validThemes.contains(themeName)) {
      return themeName;
    }

    // 否则返回默认主题
    return AppConfig.defaultTheme;
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
              _selectedLanguage = AppConfigService.locale;
            }

            // 更新主题设置
            if (themeState is ThemeChangedState) {
              _selectedTheme = _getValidThemeName(themeState.themeName);
              _selectedThemeMode = themeState.themeMode;
              _selectedFontFamily = FontFamily.fromValue(themeState.fontFamily);
            } else {
              _selectedTheme = _getValidThemeName(AppConfigService.theme);
              _selectedThemeMode = AppConfigService.themeMode;
              _selectedFontFamily = AppConfigService.fontFamily;
            }

            final localizations = AppLocalizations.of(context)!;

            return Scaffold(
              appBar: AppBar(title: Text(localizations.settings_title)),
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
        localizations.language,
        style: Theme.of(context).textTheme.titleMedium, // 统一使用titleMedium样式
      ),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text('English', style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: Text('中文', style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLanguage = newValue;
            });

            // 更新语言设置
            context.read<LocalizationBloc>().add(LanguageChangedEvent(newValue));
          }
        },
      ),
    );
  }

  /// 构建字体选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户从支持的字体列表中选择一种字体。
  /// 当用户选择新字体时，会更新应用程序的字体设置并保存到本地存储。
  Widget _buildFontSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(localizations.font_family, style: Theme.of(context).textTheme.titleMedium),
      trailing: DropdownButton<FontFamily>(
        value: _selectedFontFamily,
        items: FontFamily.values
            .map(
              (font) => DropdownMenuItem(
                value: font,
                child: Text(font.value, style: const TextStyle(fontWeight: FontWeight.normal)),
              ),
            )
            .toList(),
        onChanged: (FontFamily? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedFontFamily = newValue;
            });

            // 更新字体设置
            context.read<ThemeBloc>().add(FontFamilyChangedEvent(newValue.value));
          }
        },
      ),
    );
  }

  /// 构建主题选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户从支持的主题列表中选择一种主题。
  /// 当用户选择新主题时，会更新应用程序的主题设置并保存到本地存储。
  Widget _buildThemeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(localizations.theme, style: Theme.of(context).textTheme.titleMedium),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        items: AppConfig.validThemes
            .map(
              (theme) => DropdownMenuItem(
                value: theme,
                child: Text(theme, style: const TextStyle(fontWeight: FontWeight.normal)),
              ),
            )
            .toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTheme = newValue;
            });

            // 更新主题设置
            context.read<ThemeBloc>().add(ThemeChangedEvent(_selectedThemeMode, newValue));
          }
        },
      ),
    );
  }

  /// 构建主题模式选择下拉菜单
  ///
  /// 该方法创建一个下拉按钮，允许用户选择主题模式（浅色、深色或跟随系统）。
  /// 当用户选择新主题模式时，会更新应用程序的主题模式设置并保存到本地存储。
  Widget _buildThemeModeSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(localizations.theme_mode, style: Theme.of(context).textTheme.titleMedium),
      trailing: DropdownButton<ThemeMode>(
        value: _selectedThemeMode,
        items: [
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(localizations.light_mode, style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(localizations.dark_mode, style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(localizations.system_mode, style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
        ],
        onChanged: (ThemeMode? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedThemeMode = newValue;
            });

            // 更新主题模式设置
            context.read<ThemeBloc>().add(ThemeChangedEvent(newValue, _selectedTheme));
          }
        },
      ),
    );
  }
}
