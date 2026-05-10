import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class MenuItemWidget extends ConsumerWidget {
  final DeviceMenuItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppInteractions.clickableCard(
      borderRadius: AppDesignSystem.borderRadius12,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDesignSystem.duration200,
        curve: AppDesignSystem.curveEaseInOut,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing2),
        padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppDesignSystem.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppDesignSystem.borderRadius12,
          border: isSelected
              ? Border.all(color: AppDesignSystem.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppDesignSystem.iconSize24 + AppDesignSystem.spacing12,
              child: Icon(
                item.icon,
                color: isSelected ? AppDesignSystem.primary : AppDesignSystem.neutral400,
                size: AppDesignSystem.iconSize24,
              ),
            ),
            if (isExpanded)
              Expanded(
                child: Text(
                  _getLabel(context, item.labelKey),
                  style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppDesignSystem.primary
                        : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral700),
                    fontWeight: isSelected
                        ? AppDesignSystem.fontWeightSemiBold
                        : AppDesignSystem.fontWeightNormal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getLabel(BuildContext context, String key) {
    switch (key) {
      case 'home':
        return context.loc.home;
      case 'library':
        return context.loc.library;
      case 'settings':
        return context.loc.settings;
      default:
        return key;
    }
  }
}
