import 'package:flutter/material.dart';

/// 空状态组件
/// 显示没有找到音乐文件时的提示信息
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.music_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '未找到音乐文件\n点击"开始扫描"按钮扫描本地音乐',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}