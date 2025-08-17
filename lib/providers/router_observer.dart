import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';

/// 路由观察者，用于监听路由变化并更新标题栏
class AppBarRouteObserver extends NavigatorObserver {
  final ProviderRef ref;
  
  AppBarRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  /// 处理路由变化
  void _handleRouteChange(Route<dynamic> route) {
    // 检查路由设置是否包含GoRouterState
    final goRouteState = route.settings as GoRouterState?;
    if (goRouteState != null) {
      final path = goRouteState.uri.toString();
      
      // 获取路由额外信息
      final extra = goRouteState.extra as Map<String, dynamic>?;
      
      final title = extra?['title'] as String?;
      final showBackButton = extra?['showBack'] as bool?;
      
      // 更新标题栏状态
      final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
      appBarNotifier.handleRouteChange(
        path,
        title: title,
        showBackButton: showBackButton,
      );
    }
  }
}