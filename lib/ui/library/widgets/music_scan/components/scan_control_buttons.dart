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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ScanButtonWidget(
            onPressed: hasCustomPaths && !isScanning ? onStartScan : null,
          ),
        ],
      ),
    );
  }
}