import 'package:flutter/material.dart';

/// 自定义路径列表项组件
/// 显示单个自定义扫描路径
class CustomPathListItemWidget extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const CustomPathListItemWidget({
    super.key,
    required this.path,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(path),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}