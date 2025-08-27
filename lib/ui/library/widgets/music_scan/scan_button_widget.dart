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
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: Theme.of(context).textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      icon: const Icon(Icons.search, size: 20),
      label: const Text('开始扫描'),
    );
  }
}