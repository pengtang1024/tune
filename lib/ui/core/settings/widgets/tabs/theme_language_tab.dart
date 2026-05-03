import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/settings_item.dart';

class ThemeLanguageTab extends ConsumerWidget {
  const ThemeLanguageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.loc.settings_page_theme} ${context.loc.settings_page_language}',
            style: AppDesignSystem.textTheme.titleLarge?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
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
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    appBarNotifier.updateLocale(newLocale);
                  }
                },
                items: appBarState.supportedLocales.map((Locale locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(_getLocaleDisplayName(locale, context)),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppDesignSystem.spacing16),

          // 主题设置
          SettingsItem(
            icon: Icons.palette,
            title: context.loc.theme,
            iconColor: AppDesignSystem.secondary,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: appBarState.themeMode,
                onChanged: (ThemeMode? newThemeMode) {
                  if (newThemeMode != null) {
                    appBarNotifier.updateThemeMode(newThemeMode);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(context.loc.system_mode),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(context.loc.light_mode),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(context.loc.dark_mode),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}