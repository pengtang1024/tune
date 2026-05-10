import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

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

    return AppInteractions.pressableScale(
      scaleValue: 0.93,
      onTap: () => onSelected(locale),
      child: AnimatedContainer(
        duration: AppDesignSystem.duration300,
        decoration: BoxDecoration(
          color: isSelected ? AppDesignSystem.primary.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppDesignSystem.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: AppDesignSystem.borderRadius16,
          boxShadow: isSelected
              ? [BoxShadow(color: AppDesignSystem.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
        width: 44, height: 44,
        transform: isSelected ? Matrix4.translationValues(0, -2, 0) : null,
        child: Center(
          child: Text(
            _getLocaleCode(locale),
            style: AppDesignSystem.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? AppDesignSystem.fontWeightBold : AppDesignSystem.fontWeightNormal,
            ),
          ),
        ),
      ),
    );
  }

  String _getLocaleCode(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'EN';
      case 'zh':
        if (locale.countryCode == 'CN') return '简';
        if (locale.countryCode == 'TW') return '繁';
        return '中';
      case 'ja': return '日';
      case 'ko': return '韩';
      case 'ru': return '俄';
      case 'de': return '德';
      case 'fr': return '法';
      case 'es': return '西';
      default: return locale.languageCode.toUpperCase();
    }
  }
}
