import 'package:flutter/material.dart';

/// 扫描按钮组件
/// 显示开始扫描按钮，根据扫描状态显示不同样式
class ScanButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;

  const ScanButtonWidget({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.search),
            label: const Text('开始扫描'),
          ),
        ),
      ],
    );
  }
}