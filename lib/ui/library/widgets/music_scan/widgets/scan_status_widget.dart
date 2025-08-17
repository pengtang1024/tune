import 'package:flutter/material.dart';

/// 扫描状态消息组件
/// 显示扫描过程中的状态信息
class ScanStatusWidget extends StatelessWidget {
  final String statusMessage;
  final String errorMessage;

  const ScanStatusWidget({
    super.key,
    required this.statusMessage,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (statusMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      statusMessage,
      style: TextStyle(
        color: errorMessage.isEmpty ? Colors.blue : Colors.red,
      ),
    );
  }
}