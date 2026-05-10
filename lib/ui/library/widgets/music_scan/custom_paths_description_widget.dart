import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class CustomPathsDescriptionWidget extends StatelessWidget {
  const CustomPathsDescriptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppDesignSystem.spacing8),
        Text(
          '添加自定义文件夹路径以扫描特定位置的音乐文件',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        SizedBox(height: AppDesignSystem.spacing16),
      ],
    );
  }
}
