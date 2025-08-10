import 'package:flutter/material.dart';

/// 桌面端音量滑块（带快捷键）
class DesktopVolumeSlider extends StatelessWidget {
  /// 当前音量值
  final double volume;

  /// 音量改变回调
  final Function(double)? onChanged;

  /// 构造函数
  const DesktopVolumeSlider({
    super.key,
    required this.volume,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.volume_down),
        const SizedBox(width: 8.0),
        SizedBox(
          width: 100.0,
          child: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8.0),
        const Icon(Icons.volume_up),
      ],
    );
  }
}