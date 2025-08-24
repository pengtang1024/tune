import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/widgets/tabs/animations_tab.dart';

class AnimationItemWidget extends ConsumerWidget {
  final AnimationItem animationItem;

  const AnimationItemWidget({super.key, required this.animationItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 60,
              // 使用AnimatedSwitcher实现动画启用/禁用的过渡效果
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ref.watch(animationsEnabledProvider)
                    ? Builder(
                        builder: (BuildContext context) {
                          // 传递主题给动画组件，确保主题适配
                          // 添加UniqueKey确保组件正确重建，避免黑屏问题
                          return Theme(
                            data: Theme.of(context),
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${animationItem.name}_${ref.watch(animationsEnabledProvider)}',
                              ),
                              child: animationItem.widget,
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.animation_outlined, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              animationItem.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 从animations_tab.dart复制的内部类定义
class AnimationItem {
  final String name;
  final Widget widget;

  AnimationItem({required this.name, required this.widget});
}
