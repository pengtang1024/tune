import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';

/// 语言切换按钮组件
/// 负责切换应用语言
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.g_translate),
      tooltip: context.loc.settings,
      onPressed: () {
        _showLanguageSelectionDialog(context, ref);
      },
    );
  }

  /// 显示语言选择对话框
  void _showLanguageSelectionDialog(BuildContext context, WidgetRef ref) {
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
    final currentLocale = ref.read(appBarStateNotifierProvider).locale;
    final supportedLocales = ref.read(appBarStateNotifierProvider).supportedLocales;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.select_language),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = supportedLocales[index];
                return ListTile(
                  title: Text(_getLocaleDisplayName(locale, context)),
                  selected: locale == currentLocale,
                  onTap: () {
                    appBarNotifier.switchLanguage(locale);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.cancel), // 使用本地化字符串
            ),
          ],
        );
      },
    );
  }

  /// 获取语言显示名称（基于flutter_localizations）
  String _getLocaleDisplayName(Locale locale, BuildContext context) {
    // 使用flutter_localizations提供的方法获取本地化名称
    try {
      // 尝试获取本地化的语言名称
      switch (locale.languageCode) {
        case 'en':
          return 'English';
        case 'zh':
          if (locale.countryCode == 'CN') {
            return '简体中文';
          }
          return '中文';
        case 'ja':
          return '日本語';
        case 'ko':
          return '한국어';
        case 'ru':
          return 'Русский';
        case 'de':
          return 'Deutsch';
        case 'fr':
          return 'Français';
        case 'es':
          return 'Español';
        default:
          return locale.languageCode;
      }
    } catch (e) {
      // 如果出现异常，返回语言代码
      return locale.languageCode;
    }
  }
}
