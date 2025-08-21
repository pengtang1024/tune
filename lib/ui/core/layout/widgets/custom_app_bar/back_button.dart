import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/app_bar_providers.dart';

/// AppBar 返回按钮组件
/// 负责处理页面返回逻辑
class BackButtonWidget extends ConsumerWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarState = ref.watch(appBarStateNotifierProvider);

    if (!appBarState.showBackButton) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // 使用GoRouter返回上一页
        final goRouter = GoRouter.of(context);
        if (goRouter.canPop()) {
          goRouter.pop();
        } else {
          // 如果无法使用GoRouter返回，则导航到首页
          // 但要避免在首页时仍然尝试导航到首页
          final currentPath = goRouter.routeInformationProvider.value.uri.toString();
          if (currentPath != '/' && currentPath != '/home') {
            context.go('/home');
          }
        }
      },
    );
  }
}
