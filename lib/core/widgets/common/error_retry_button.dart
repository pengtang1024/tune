import 'package:flutter/material.dart';

/// 错误重试按钮组件
class ErrorRetryButton extends StatelessWidget {
  /// 重试回调
  final VoidCallback? onRetry;

  /// 错误消息
  final String message;

  /// 按钮文本
  final String buttonText;

  /// 构造函数
  const ErrorRetryButton({
    super.key,
    this.onRetry,
    this.message = 'An error occurred',
    this.buttonText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: Text(buttonText),
        ),
      ],
    );
  }
}