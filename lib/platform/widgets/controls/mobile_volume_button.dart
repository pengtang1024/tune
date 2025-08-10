import 'package:flutter/material.dart';

/// 移动端音量按钮（双击放大）
class MobileVolumeButton extends StatelessWidget {
  /// 点击回调
  final VoidCallback? onPressed;

  /// 双击回调
  final VoidCallback? onDoubleTap;

  /// 构造函数
  const MobileVolumeButton({
    super.key,
    this.onPressed,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      onDoubleTap: onDoubleTap,
      child: const CircleAvatar(
        child: Icon(Icons.volume_up),
      ),
    );
  }
}