import 'package:flutter/material.dart';
import 'package:tune/core/extension/theme_extension.dart';

/// 扫描进度条组件
/// 显示扫描进度和计数信息
class ScanProgressWidget extends StatelessWidget {
  final bool isScanning;
  final int totalCount;
  final int scannedCount;

  const ScanProgressWidget({
    super.key,
    required this.isScanning,
    required this.totalCount,
    required this.scannedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (!isScanning || totalCount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: totalCount > 0 ? scannedCount / totalCount : 0,
            backgroundColor: context.theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '已扫描 $scannedCount / $totalCount 首歌曲',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}