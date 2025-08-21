import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 自定义路径扫描按钮组件
/// 显示扫描自定义路径的按钮
class CustomPathsScanButtonWidget extends StatelessWidget {
  final bool isScanning;
  final bool hasCustomPaths;
  final VoidCallback onPressed;

  const CustomPathsScanButtonWidget({
    super.key,
    required this.isScanning,
    required this.hasCustomPaths,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCustomPaths) {
      return const SizedBox.shrink();
    }

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
                : const Icon(Icons.folder_open),
            label: Text(isScanning ? context.loc.scan_local_music : context.loc.scan_local_music),
          ),
        ),
      ],
    );
  }
}