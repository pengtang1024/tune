import 'package:flutter/material.dart';

/// 自定义路径描述组件
/// 显示自定义扫描路径的功能说明
class CustomPathsDescriptionWidget extends StatelessWidget {
  const CustomPathsDescriptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          '添加自定义文件夹路径以扫描特定位置的音乐文件',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}