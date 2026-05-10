import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class ScanHeaderWidget extends StatelessWidget {
  const ScanHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '扫描本地音乐',
          style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          '扫描本地音乐库，自动整理您的音乐文件并提取元数据',
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: AppDesignSystem.neutral500,
          ),
        ),
      ],
    );
  }
}
