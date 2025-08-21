import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';

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
      '${context.loc.songs} ($scannedCount ${context.loc.songs})',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}