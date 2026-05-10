import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class CompactWindowSizeButton extends StatelessWidget {
  final String size;
  final String currentSize;
  final Function(String) onSelected;

  const CompactWindowSizeButton({
    super.key,
    required this.size,
    required this.currentSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = size == currentSize;
    final icon = size == 'small'
        ? Icons.square_outlined
        : size == 'medium'
            ? Icons.square
            : Icons.square_rounded;

    return AppInteractions.pressableScale(
      scaleValue: 0.93,
      onTap: () => onSelected(size),
      child: AnimatedContainer(
        duration: AppDesignSystem.duration300,
        decoration: BoxDecoration(
          color: isSelected ? AppDesignSystem.primary.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppDesignSystem.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: AppDesignSystem.borderRadius12,
          boxShadow: isSelected
              ? [BoxShadow(color: AppDesignSystem.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
        width: 44, height: 44,
        transform: isSelected ? Matrix4.translationValues(0, -2, 0) : null,
        child: Icon(icon, size: AppDesignSystem.iconSize20, color: isSelected ? AppDesignSystem.primary : null),
      ),
    );
  }
}
