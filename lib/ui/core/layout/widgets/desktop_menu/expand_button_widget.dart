import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/layout_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class ExpandButtonWidget extends ConsumerWidget {
  const ExpandButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutState = ref.watch(layoutStateNotifierProvider);
    final layoutNotifier = ref.read(layoutStateNotifierProvider.notifier);

    return AppInteractions.pressableScale(
      scaleValue: 0.92,
      onTap: () => layoutNotifier.toggleExpanded(),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
        decoration: BoxDecoration(
          borderRadius: AppDesignSystem.borderRadius8,
        ),
        child: AnimatedSwitcher(
          duration: AppDesignSystem.duration200,
          child: Icon(
            layoutState.isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            key: ValueKey(layoutState.isExpanded),
            size: AppDesignSystem.iconSize20,
            color: AppDesignSystem.neutral400,
          ),
        ),
      ),
    );
  }
}
