import 'package:flutter/material.dart';

/// 桌面端首页（仅布局差异）
class HomePageDesktop extends StatelessWidget {
  /// 构造函数
  const HomePageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Page Desktop'),
      ),
    );
  }
}