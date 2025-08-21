import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/layout_providers.dart';

/// 展开/收起按钮组件
/// 仅负责显示展开/收起侧边栏的按钮
class ExpandButtonWidget extends ConsumerWidget {
  const ExpandButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(layoutStateNotifierProvider);
    final layoutNotifier = ref.read(layoutStateNotifierProvider.notifier);

    return IconButton(
      icon: layoutState.isExpanded
          ? const Icon(Icons.arrow_back)
          : const Icon(Icons.menu),
      onPressed: () {
        layoutNotifier.toggleExpanded();
      },
      tooltip: layoutState.isExpanded ? '收起侧边栏' : '展开侧边栏', // 这里需要添加到本地化字符串中，暂时保留硬编码
    );
  }
}
