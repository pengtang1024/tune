import 'package:flutter/material.dart';

/// 紧凑型窗口大小选项按钮组件
/// 提供三种窗口大小选项的可视化按钮，带有动画效果
class CompactWindowSizeButton extends StatelessWidget {
  final String size;
  final String currentSize;
  final Function(String) onSelected;

  const CompactWindowSizeButton({
    Key? key,
    required this.size,
    required this.currentSize,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = size == currentSize;
    final theme = Theme.of(context);
    final sizeIcon = size == 'small' 
        ? Icons.square_outlined
        : size == 'medium' 
            ? Icons.square
            : Icons.square_rounded;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSelected(size),
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
            borderRadius: BorderRadius.circular(12),
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
          child: Icon(sizeIcon, size: 20),
        ),
      ),
    );
  }
}