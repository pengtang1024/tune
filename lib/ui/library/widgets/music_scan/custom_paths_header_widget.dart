import 'package:flutter/material.dart';

/// 自定义路径头部组件
/// 显示自定义扫描路径的标题和添加按钮
class CustomPathsHeaderWidget extends StatelessWidget {
  final VoidCallback onAddPath;

  const CustomPathsHeaderWidget({
    super.key,
    required this.onAddPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '自定义扫描路径',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAddPath,
          tooltip: '添加自定义扫描路径',
        ),
      ],
    );
  }
}