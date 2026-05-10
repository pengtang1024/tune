import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class ThemeOptionButton extends StatelessWidget {
  final ThemeMode themeMode;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onSelected;
  final IconData icon;
  final String label;

  const ThemeOptionButton({
    super.key,
    required this.themeMode,
    required this.currentThemeMode,
    required this.onSelected,
    required this.icon,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeMode == currentThemeMode;

    return AppInteractions.pressableScale(
      scaleValue: 0.93,
      onTap: () => onSelected(themeMode),
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
        child: Icon(icon, size: AppDesignSystem.iconSize24, color: isSelected ? AppDesignSystem.primary : null),
      ),
    );
  }
}
