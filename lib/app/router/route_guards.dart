import 'package:auto_route/auto_route.dart';

import 'app_router.dart';

/// 路由守卫基类
///
/// 用于检查路由访问权限
class RouteGuards {
  /// 检查用户是否已登录
  static Future<bool> isLoggedIn() async {
    // TODO: 实现登录状态检查逻辑
    return true;
  }

  /// 检查平台权限
  static Future<bool> hasPlatformPermission() async {
    // TODO: 实现平台权限检查逻辑
    return true;
  }
}

/// 登录守卫
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    // 检查用户是否已登录
    if (await RouteGuards.isLoggedIn()) {
      resolver.next(true);
    } else {
      // 重定向到登录页面
      resolver.redirect(const LoginRoute());
      resolver.next(false);
    }
  }
}
