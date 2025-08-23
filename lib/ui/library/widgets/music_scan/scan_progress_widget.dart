import 'package:flutter/material.dart';
import 'package:tune/core/extension/theme_extension.dart';

/// 扫描进度条组件
/// 显示扫描进度
class ScanProgressWidget extends StatelessWidget {
  final double progress;

  const ScanProgressWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}