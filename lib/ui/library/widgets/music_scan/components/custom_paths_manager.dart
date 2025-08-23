import 'package:flutter/material.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_description_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_paths_scan_button_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/custom_path_list_item_widget.dart';

/// 管理自定义扫描路径的组件
class CustomPathsManager extends StatelessWidget {
  /// 当前存储的自定义扫描路径列表
  final List<String> customScanPaths;
  
  /// 添加新路径的回调函数
  final VoidCallback onAddPath;
  
  /// 根据索引移除指定路径的回调函数
  final Function(int) onRemovePath;

  const CustomPathsManager({
    super.key,
    required this.customScanPaths,
    required this.onAddPath,
    required this.onRemovePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示头部标题
          CustomPathsHeaderWidget(onAddPath: onAddPath),
          const SizedBox(height: 8),
          
          // 显示描述信息
          const CustomPathsDescriptionWidget(),
          const SizedBox(height: 16),
          
          // 扫描按钮，触发添加路径操作
          CustomPathsScanButtonWidget(onPressed: onAddPath),
          const SizedBox(height: 16),
          
          // 如果存在自定义路径，则显示路径列表
          if (customScanPaths.isNotEmpty) ...[
            const Text('自定义扫描路径:'),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customScanPaths.length,
              itemBuilder: (context, index) {
                return CustomPathListItemWidget(
                  path: customScanPaths[index],
                  // 包装成接受int参数的回调，触发移除指定索引的路径
                  onDelete: () => onRemovePath(index),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}