import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/config/app_config.dart';
import 'package:tune/l10n/app_localizations.dart'; // 使用生成的本地化文件
import 'package:tune/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/presentation/bloc/theme/theme_event.dart';
import 'package:tune/presentation/bloc/localization/localization_bloc.dart';
import 'package:tune/presentation/bloc/localization/localization_event.dart';

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

  @override
  void initState() {
    super.initState();
    
    // 初始化语言和主题设置
    _selectedLanguage = AppConfig.locale;
    _selectedTheme = AppConfig.theme;
  }

  /// 构建语言选择下拉菜单
  /// 
  /// 该方法创建一个下拉按钮，允许用户从支持的语言列表中选择一种语言。
  /// 当用户选择新语言时，会更新应用程序的语言设置并保存到本地存储。
  Widget _buildLanguageSelector(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return ListTile(
      title: Text(localizations.settings_page_language),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: const Text('English'),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: const Text('中文'),
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
      title: Text(localizations.settings_page_theme),
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        items: [
          DropdownMenuItem(
            value: 'trendyElectro',
            child: Text(localizations.theme_name_trendy_electro),
          ),
          DropdownMenuItem(
            value: 'midnightPurple',
            child: Text(localizations.theme_name_midnight_purple),
          ),
          DropdownMenuItem(
            value: 'sunriseOrange',
            child: Text(localizations.theme_name_sunrise_orange),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTheme = newValue;
            });
            
            // 更新主题设置
            context.read<ThemeBloc>().add(
                  ThemeChangedEvent(ThemeMode.system, themeName: newValue),
                );
            
            // 保存主题设置到本地存储
            AppConfig.setTheme(newValue);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings_title),
      ),
      body: ListView(
        children: [
          // 语言设置部分
          _buildLanguageSelector(context),
          
          // 主题设置部分
          _buildThemeSelector(context),
        ],
      ),
    );
  }
}