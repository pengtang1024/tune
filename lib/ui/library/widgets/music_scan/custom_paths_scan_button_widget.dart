import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 自定义路径扫描按钮组件
/// 显示扫描自定义路径的按钮
class CustomPathsScanButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomPathsScanButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.folder_open),
            label: Text(context.loc.add_custom_directory),
          ),
        ),
      ],
    );
  }
}