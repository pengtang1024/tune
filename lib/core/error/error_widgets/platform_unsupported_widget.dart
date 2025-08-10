import 'package:flutter/material.dart';

/// 平台不支持页面组件
class PlatformUnsupportedWidget extends StatelessWidget {
  /// 平台名称
  final String platform;

  /// 功能描述
  final String feature;

  /// 构造函数
  const PlatformUnsupportedWidget({
    super.key,
    required this.platform,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Platform Not Supported',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$feature is not supported on $platform',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}