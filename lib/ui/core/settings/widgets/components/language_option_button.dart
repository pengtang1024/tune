import 'package:flutter/material.dart';

/// 语言选项按钮组件
/// 提供紧凑的语言选择按钮，仅显示图标和简写文本
class LanguageOptionButton extends StatelessWidget {
  final Locale locale;
  final Locale currentLocale;
  final Function(Locale) onSelected;
  final String displayName;
  final String label;

  const LanguageOptionButton({
    super.key,
    required this.locale,
    required this.currentLocale,
    required this.onSelected,
    required this.displayName,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale.languageCode == currentLocale.languageCode &&
        locale.countryCode == currentLocale.countryCode;
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelected(locale),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(8),
          width: 40,
          height: 40,
          transform: isSelected ? Matrix4.translationValues(0, -2, 0) : null,
          child: Center(
            child: Text(
              _getLocaleCode(locale),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取语言代码的简写形式
  String _getLocaleCode(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'EN';
      case 'zh':
        if (locale.countryCode == 'CN') {
          return '简';
        } else if (locale.countryCode == 'TW') {
          return '繁';
        }
        return '中';
      case 'ja':
        return '日';
      case 'ko':
        return '韩';
      case 'ru':
        return '俄';
      case 'de':
        return '德';
      case 'fr':
        return '法';
      case 'es':
        return '西';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}