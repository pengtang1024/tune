import 'package:flutter/material.dart';

/// 扫描按钮组件
/// 显示开始扫描按钮，根据扫描状态显示不同样式
class ScanButtonWidget extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onPressed;

  const ScanButtonWidget({
    super.key,
    required this.isScanning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isScanning ? null : onPressed,
            icon: isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(isScanning ? '扫描中...' : '开始扫描'),
          ),
        ),
      ],
    );
  }
}