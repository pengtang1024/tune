import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/layout_providers.dart';

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
        title: isExpanded
            ? Row(
                children: [
                  Icon(isExpanded ? Icons.arrow_back_ios : null),
                  const SizedBox(width: 10),
                  const Text('收起侧边栏'),
                ],
              )
            : const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 24,
                ),
              ),
        trailing: null,
        onTap: () {
          final layoutNotifier = ref.read(layoutStateNotifierProvider.notifier);
          layoutNotifier.toggleExpanded();
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}