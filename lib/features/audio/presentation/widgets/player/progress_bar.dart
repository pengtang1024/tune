import 'package:flutter/material.dart';

/// 进度条组件
class ProgressBar extends StatelessWidget {
  /// 当前进度
  final Duration current;

  /// 总时长
  final Duration total;

  /// 拖动回调
  final Function(Duration)? onChanged;

  /// 构造函数
  const ProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: current.inMilliseconds.toDouble(),
          min: 0.0,
          max: total.inMilliseconds.toDouble(),
          onChanged: onChanged != null
              ? (value) => onChanged!(Duration(milliseconds: value.toInt()))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(current)),
              Text(_formatDuration(total)),
            ],
          ),
        ),
      ],
    );
  }

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
