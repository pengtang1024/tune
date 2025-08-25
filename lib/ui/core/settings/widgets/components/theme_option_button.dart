import 'package:flutter/material.dart';

/// 主题选项按钮组件
/// 提供紧凑的主题选择按钮，仅显示图标
class ThemeOptionButton extends StatelessWidget {
  final ThemeMode themeMode;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onSelected;
  final IconData icon;
  final String label;

  const ThemeOptionButton({
    Key? key,
    required this.themeMode,
    required this.currentThemeMode,
    required this.onSelected,
    required this.icon,
    this.label = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = themeMode == currentThemeMode;
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelected(themeMode),
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
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}