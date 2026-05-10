import 'package:flutter/material.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_description_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_scan_button_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_path_list_item_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class CustomPathsManager extends StatelessWidget {
  final List<String> customScanPaths;
  final VoidCallback onAddPath;
  final Function(int) onRemovePath;

  const CustomPathsManager({
    super.key,
    required this.customScanPaths,
    required this.onAddPath,
    required this.onRemovePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomPathsHeaderWidget(onAddPath: onAddPath),
        const SizedBox(height: AppDesignSystem.spacing16),
        const CustomPathsDescriptionWidget(),
        const SizedBox(height: AppDesignSystem.spacing24),
        CustomPathsScanButtonWidget(onPressed: onAddPath),
        const SizedBox(height: AppDesignSystem.spacing24),
        if (customScanPaths.isNotEmpty) ...[
          Text(
            'Custom scan paths:',
            style: AppDesignSystem.textTheme.titleMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightBold),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customScanPaths.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
                child: CustomPathListItemWidget(
                  path: customScanPaths[index],
                  onDelete: () => onRemovePath(index),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
