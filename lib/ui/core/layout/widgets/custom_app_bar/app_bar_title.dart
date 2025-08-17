import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/app_bar_providers.dart';

/// AppBar 标题组件
/// 负责显示当前页面标题
class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);

    return Text(
      appBarState.title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
