import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/utils/localization_delegate.dart';
import 'package:tune/core/utils/localization_service.dart';
import 'package:tune/presentation/bloc/theme/theme_bloc.dart';
import 'package:tune/presentation/bloc/theme/theme_event.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedLocale;
  String? _selectedThemeName;
  ThemeMode? _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _selectedLocale = LocalizationService().getCurrentLocale();
    _selectedThemeMode = ThemeMode.system; // 默认系统主题模式
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final supportedLocales = LocalizationService().getSupportedLocales();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '语言', // 暂时使用硬编码文本
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedLocale,
              items: supportedLocales.map((locale) {
                String localeName;
                switch (locale) {
                  case 'en':
                    localeName = 'English';
                    break;
                  case 'zh':
                    localeName = '中文';
                    break;
                  default:
                    localeName = locale;
                }
                
                return DropdownMenuItem(
                  value: locale,
                  child: Text(localeName),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLocale = newValue;
                  });
                  
                  // 保存语言选择
                  LocalizationService().setLocale(newValue);
                  
                  // 重启应用以应用语言更改
                  // 在实际应用中，你可能需要使用状态管理来更新整个应用的语言
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              '主题', // 暂时使用硬编码文本
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // 主题模式选择
            ListTile(
              title: Text('浅色'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    setState(() {
                      _selectedThemeMode = value;
                    });
                    context.read<ThemeBloc>().add(ThemeChangedEvent(value, themeName: _selectedThemeName));
                  }
                },
              ),
              onTap: () {
                setState(() {
                  _selectedThemeMode = ThemeMode.light;
                });
                context.read<ThemeBloc>().add(ThemeChangedEvent(ThemeMode.light, themeName: _selectedThemeName));
              },
            ),
            ListTile(
              title: Text('深色'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    setState(() {
                      _selectedThemeMode = value;
                    });
                    context.read<ThemeBloc>().add(ThemeChangedEvent(value, themeName: _selectedThemeName));
                  }
                },
              ),
              onTap: () {
                setState(() {
                  _selectedThemeMode = ThemeMode.dark;
                });
                context.read<ThemeBloc>().add(ThemeChangedEvent(ThemeMode.dark, themeName: _selectedThemeName));
              },
            ),
            ListTile(
              title: Text('系统'),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    setState(() {
                      _selectedThemeMode = value;
                    });
                    context.read<ThemeBloc>().add(ThemeChangedEvent(value, themeName: _selectedThemeName));
                  }
                },
              ),
              onTap: () {
                setState(() {
                  _selectedThemeMode = ThemeMode.system;
                });
                context.read<ThemeBloc>().add(ThemeChangedEvent(ThemeMode.system, themeName: _selectedThemeName));
              },
            ),
            const SizedBox(height: 16),
            // 主题样式选择
            Text(
              '主题样式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildThemeChip('默认', null),
                _buildThemeChip('活力律动', 'vibrant'),
                _buildThemeChip('沉浸黑胶', 'vinyl'),
                _buildThemeChip('科技流光', 'tech'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeChip(String label, String? themeName) {
    final isSelected = _selectedThemeName == themeName;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedThemeName = selected ? themeName : null;
        });
        // 应用主题更改
        context.read<ThemeBloc>().add(ThemeChangedEvent(_selectedThemeMode ?? ThemeMode.system, themeName: _selectedThemeName));
      },
    );
  }
}