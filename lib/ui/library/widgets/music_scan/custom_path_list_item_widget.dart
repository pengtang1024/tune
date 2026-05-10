import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class CustomPathListItemWidget extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const CustomPathListItemWidget({super.key, required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12, vertical: AppDesignSystem.spacing8),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, size: AppDesignSystem.iconSize20, color: AppDesignSystem.neutral400),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Text(path, style: AppDesignSystem.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: AppDesignSystem.iconSize20),
            color: AppDesignSystem.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
