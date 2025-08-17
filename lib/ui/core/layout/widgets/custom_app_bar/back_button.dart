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
        // 总是尝试返回，如果无法返回再导航到首页
        final goRouter = GoRouter.of(context);
        if (goRouter.canPop()) {
          goRouter.pop();
        } else {
          // 检查当前路由是否不是首页，如果不是则返回首页
          final currentPath = goRouter.routeInformationProvider.value.uri.toString();
          if (currentPath != '/') {
            context.go('/');
          }
          // 如果当前已经在首页，则不执行任何操作
        }
      },
    );
  }
}
