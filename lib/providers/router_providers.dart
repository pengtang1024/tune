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
  RouterNotifier() : super(RouterState(selectedMenuItem: '/'));

  void updateSelectedMenuItem(String path) {
    state = state.copyWith(selectedMenuItem: path);
  }
}

/// 路由状态提供者
final routerProvider = StateNotifierProvider<RouterNotifier, RouterState>((ref) {
  return RouterNotifier();
});

/// GoRouter提供者，用于在整个应用中提供路由实例
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
          ),
          GoRoute(
            path: '/recommend',
            name: 'recommend',
            builder: (BuildContext context, GoRouterState state) {
              return const RecommendPage();
            },
          ),
          GoRoute(
            path: '/featured',
            name: 'featured',
            builder: (BuildContext context, GoRouterState state) {
              return const FeaturedPage();
            },
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            builder: (BuildContext context, GoRouterState state) {
              return const LibraryPage();
            },
          ),
          GoRoute(
            path: '/music-scan',
            name: 'music-scan',
            builder: (BuildContext context, GoRouterState state) {
              return const MusicScanPage();
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsPage();
            },
          ),
        ],
      ),
    ],
  );
});