import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);
    return Text(
      appBarState.title,
      style: AppDesignSystem.textTheme.titleLarge?.copyWith(
        fontWeight: AppDesignSystem.fontWeightBold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
