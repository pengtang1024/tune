import 'package:flutter/material.dart';
import 'package:tune/ui/widgets/empty_state.dart';

/// 空状态组件
/// 显示没有找到音乐文件时的提示信息
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.music_off,
      title: '未找到音乐文件',
      subtitle: '点击"开始扫描"按钮扫描本地音乐',
    );
  }
}