import 'package:flutter/material.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_button_widget.dart';

class ScanControlButtons extends StatelessWidget {
  final bool isScanning;
  final bool hasCustomPaths;
  final VoidCallback? onStartScan;

  const ScanControlButtons({
    super.key,
    required this.isScanning,
    required this.hasCustomPaths,
    this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '扫描控制',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 200,
              child: ScanButtonWidget(
                onPressed: hasCustomPaths && !isScanning ? onStartScan : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}