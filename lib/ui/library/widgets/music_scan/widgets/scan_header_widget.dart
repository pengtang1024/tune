import 'package:flutter/material.dart';

/// 扫描页面头部信息组件
/// 显示标题和描述信息
class ScanHeaderWidget extends StatelessWidget {
  const ScanHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '扫描本地音乐',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '扫描本地音乐库，自动整理您的音乐文件并提取元数据',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}