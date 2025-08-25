import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';

/// 语言切换按钮组件
/// 负责切换应用语言，提供直观的语言选择界面
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.language, size: 20),
      tooltip: context.loc.select_language,
      onPressed: () {
        _showLanguageSelectionDialog(context, ref);
      },
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        // 添加悬停效果
        hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  /// 显示语言选择对话框，提供现代化的语言选择界面
  void _showLanguageSelectionDialog(BuildContext context, WidgetRef ref) {
    final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
    final currentLocale = ref.read(appBarStateNotifierProvider).locale;
    final supportedLocales = ref.read(appBarStateNotifierProvider).supportedLocales;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题区域
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    context.loc.select_language,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                
                // 语言列表
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: supportedLocales.map((locale) {
                            final isSelected = locale == currentLocale;
                            return Material(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  appBarNotifier.switchLanguage(locale);
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      // 国旗图标
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: _getLanguageFlagColor(locale),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.flag_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _getLocaleDisplayName(locale, context),
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 底部按钮
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:
                    [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(context.loc.cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 获取语言显示名称（基于本地化资源）
  String _getLocaleDisplayName(Locale locale, BuildContext context) {
    try {
      // 使用应用本地化资源获取语言名称
      switch (locale.languageCode) {
        case 'en':
          return 'English';
        case 'zh':
          if (locale.countryCode == 'CN') {
            return '简体中文';
          } else if (locale.countryCode == 'TW') {
            return '繁體中文';
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

  /// 获取语言对应的国旗颜色
  Color _getLanguageFlagColor(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return Colors.red;
      case 'zh':
        return Colors.red;
      case 'ja':
        return Colors.grey;
      case 'ko':
        return Colors.blue;
      case 'ru':
        return Colors.blue;
      case 'de':
        return Colors.red;
      case 'fr':
        return Colors.blue;
      case 'es':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
