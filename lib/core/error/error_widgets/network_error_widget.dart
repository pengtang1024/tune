import 'package:flutter/material.dart';

/// 网络错误页面组件
class NetworkErrorWidget extends StatelessWidget {
  /// 重试回调
  final VoidCallback? onRetry;

  /// 错误消息
  final String message;

  /// 构造函数
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Network error occurred',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.network_check,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}