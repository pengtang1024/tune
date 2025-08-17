import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/providers/layout_providers.dart';

/// 展开/收起按钮组件
/// 仅负责显示展开/收起侧边栏的按钮
class ExpandButtonWidget extends ConsumerWidget {
  final bool isExpanded;

  const ExpandButtonWidget({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios),
        title: isExpanded
            ? const Text('收起侧边栏')
            : null,
        onTap: () {
          final layoutNotifier = ref.read(layoutStateNotifierProvider.notifier);
          layoutNotifier.toggleSidebar();
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}