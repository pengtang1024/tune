import 'package:flutter/material.dart';

/// 加载指示器组件
class LoadingIndicator extends StatelessWidget {
  /// 是否为全屏显示
  final bool fullscreen;

  /// 加载文本
  final String? text;

  /// 构造函数
  const LoadingIndicator({
    super.key,
    this.fullscreen = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final Widget indicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(text!),
        ],
      ],
    );

    if (fullscreen) {
      return Scaffold(
        body: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
}