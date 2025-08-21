import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/menu_provider.dart';
import 'package:tune/utils/logger.dart';

/// 路由观察者：监听路由变化并同步菜单状态和标题
class MenuRouteObserver extends NavigatorObserver {
  final Ref ref;

  /// MenuRouteObserver 构造函数
  ///
  /// 此构造函数用于创建 MenuRouteObserver 实例，并接收一个 ref 参数
  ///
  /// @param ref 用于依赖注入的引用对象，通常用于访问状态管理或其他服务
  MenuRouteObserver(this.ref);

  /// 当新路由被推入导航栈时触发
  @override
  void didPush(
    Route<dynamic> route,
    Route<dynamic>? previousRoute, {
    bool isDesktop = true,
  }) {
    super.didPush(route, previousRoute);
    Log.info(
      '1route: ${route.toString()} previousRoute: ${previousRoute?.toString()} isDesktop: $isDesktop',
    );
    _syncMenuState(route, isDesktop);
    _syncAppBarTitleAndBackButton(route, previousRoute);
  }

  /// 当路由被弹出导航栈时触发
  @override
  void didPop(
    Route<dynamic> route,
    Route<dynamic>? previousRoute, {
    bool isDesktop = true,
  }) {
    super.didPop(route, previousRoute);
    Log.info(
      '2route: ${route.settings.name} previousRoute: ${previousRoute?.settings.name} isDesktop: $isDesktop',
    );
    if (previousRoute != null) {
      _syncMenuState(previousRoute, isDesktop);
      _syncAppBarTitleAndBackButton(previousRoute, route);
    }
  }

  /// 当路由被替换时触发
  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
    bool isDesktop = true,
  }) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    Log.info(
      '3newRoute: ${newRoute?.settings.name} oldRoute: $oldRoute isDesktop: $isDesktop',
    );
    if (newRoute != null) {
      _syncMenuState(newRoute, isDesktop);
      _syncAppBarTitleAndBackButton(newRoute, oldRoute);
    }
  }

  /// 同步菜单状态到当前路由
  void _syncMenuState(Route<dynamic> route, bool isDesktop) {
    // 获取路由名称（在路由配置中确保name与path一致）
    final path = route.settings.name;
    Log.info('4path: ${route.settings.name} route isDesktop: $isDesktop');
    // 只处理我们定义的菜单路由
    if (path != null &&
        DeviceMenuItem.getByDevice(
          isDesktop,
        ).any((item) => item.path == path)) {
      Log.info('5path: ${route.settings.name} route isDesktop: $isDesktop');
      // 延迟更新菜单状态以避免在构建过程中修改状态
      Future.microtask(() {
        ref.read(menuStateProvider.notifier).syncWithRoute(path);
      });
    }
  }

  /// 同步AppBar标题和返回按钮到当前路由
  void _syncAppBarTitleAndBackButton(
    Route<dynamic>? currentRoute,
    Route<dynamic>? previousRoute,
  ) {
    final currentPath = currentRoute?.settings.name;
    if (currentPath != null) {
      // 根据路由路径确定标题
      String title = _getTitleForPath(currentPath);

      // 判断是否需要显示返回按钮（非主菜单路由需要显示返回按钮）
      bool showBackButton = !_isMainMenuRoute(currentPath);

      // 延迟更新标题以避免在构建过程中修改状态
      Future.microtask(() {
        try {
          final appBarState = ref.read(appBarStateNotifierProvider);
          if (appBarState.title != title ||
              appBarState.currentRoute != currentPath ||
              appBarState.showBackButton != showBackButton) {
            final appBarNotifier = ref.read(
              appBarStateNotifierProvider.notifier,
            );
            appBarNotifier.handleRouteChange(
              currentPath,
              title: title,
              showBackButton: showBackButton,
            );
          }
        } catch (e) {
          Log.error('Error updating app bar title: $e');
        }
      });
    }
  }

  /// 根据路由路径获取对应的标题
  String _getTitleForPath(String path) {
    // 注意：这些字符串应该使用本地化，但由于这是在路由观察器中，
    // 可能无法直接访问BuildContext来获取本地化实例
    // 在实际应用中，应该通过其他方式传递本地化标题
    switch (path) {
      case '/home':
        return 'home'; // 应该使用 localizations.home
      case '/recommend':
        return 'recommend'; // 应该使用 localizations.recommend
      case '/featured':
        return 'featured'; // 应该使用 localizations.featured
      case '/library':
        return 'library'; // 应该使用 localizations.library
      case '/music-scan':
        return 'music_scan'; // 应该使用自定义本地化字符串
      case '/settings':
        return 'settings'; // 应该使用 localizations.settings
      default:
        return 'app_name'; // 应该使用 localizations.app_name
    }
  }

  /// 判断是否为主菜单路由
  bool _isMainMenuRoute(String path) {
    final mainMenuRoutes = ['/home', '/recommend', '/featured', '/library'];
    return mainMenuRoutes.contains(path);
  }
}
