import 'package:flutter/material.dart';

/// 扫描结果头部组件
/// 显示扫描结果的标题和计数
class ScanResultsHeaderWidget extends StatelessWidget {
  final int scannedCount;

  const ScanResultsHeaderWidget({
    super.key,
    required this.scannedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '扫描结果 ($scannedCount 首歌曲)',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}