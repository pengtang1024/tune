import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/ui/core/layout/widgets/screen_layout.dart';
import 'package:tune/ui/home/widgets/home_page.dart';
import 'package:tune/ui/recommend/widgets/recommend_page.dart';
import 'package:tune/ui/featured/widgets/featured_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/library/widgets/music_scan_page.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';
import 'package:tune/providers/router_observer.dart';

/// 路由状态
class RouterState {
  final String selectedMenuItem;

  RouterState({required this.selectedMenuItem});

  RouterState copyWith({
    String? selectedMenuItem,
  }) {
    return RouterState(
      selectedMenuItem: selectedMenuItem ?? this.selectedMenuItem,
    );
  }

  /// 根据路由路径获取对应的菜单索引
  int getSelectedIndex() {
    switch (selectedMenuItem) {
      case '/':
        return 0;
      case '/recommend':
        return 1;
      case '/featured':
        return 2;
      case '/library':
        return 3;
      case '/music-scan':
        // 音乐扫描页面也归类到音乐库部分
        return 3;
      default:
        // 默认返回主页索引
        return 0;
    }
  }
}

/// 路由状态管理器
class RouterNotifier extends StateNotifier<RouterState> {
  GoRouter? _router;

  RouterNotifier() : super(RouterState(selectedMenuItem: '/')) {
    // 初始化时注册路由观察者
  }

  void setRouter(GoRouter router) {
    _router = router;
  }

  void updateSelectedMenuItem(String path) {
    state = state.copyWith(selectedMenuItem: path);
  }

  /// 根据索引导航到对应页面
  void goToIndex(int index) {
    if (_router == null) return;

    switch (index) {
      case 0:
        _router!.go('/');
        break;
      case 1:
        _router!.go('/recommend');
        break;
      case 2:
        _router!.go('/featured');
        break;
      case 3:
        _router!.go('/library');
        break;
      default:
        _router!.go('/');
    }
  }
}

/// 路由状态提供者
final routerProvider = StateNotifierProvider<RouterNotifier, RouterState>((ref) {
  return RouterNotifier();
});


/// GoRouter提供者，用于在整个应用中提供路由实例
final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerProvider.notifier);
  
  // 创建一个GlobalKey用于Navigator
  final navigatorKey = GlobalKey<NavigatorState>();
  
  final router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ScreenLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (BuildContext context, GoRouterState state) {
              return const HomePage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
          GoRoute(
            path: '/recommend',
            name: 'recommend',
            builder: (BuildContext context, GoRouterState state) {
              return const RecommendPage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
          GoRoute(
            path: '/featured',
            name: 'featured',
            builder: (BuildContext context, GoRouterState state) {
              return const FeaturedPage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            builder: (BuildContext context, GoRouterState state) {
              return const LibraryPage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
          GoRoute(
            path: '/music-scan',
            name: 'music-scan',
            builder: (BuildContext context, GoRouterState state) {
              return const MusicScanPage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsPage();
            },
            routes: [
              // 添加子路由示例
            ],
          ),
        ],
      ),
    ],
  );
  
  // 设置路由器实例
  routerNotifier.setRouter(router);
  
  return router;
});