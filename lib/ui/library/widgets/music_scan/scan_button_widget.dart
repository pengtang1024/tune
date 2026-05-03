import 'package:flutter/material.dart';
import 'package:tune/ui/widgets/modern_button.dart';

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
    return ModernButton(
      onPressed: onPressed,
      icon: Icons.search,
      text: '开始扫描',
    );
  }
}