import 'dart:developer';

import 'package:flutter/widgets.dart';

/// 路由监听器
///
/// 用于监听路由变化，统计页面访问等
class RouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 页面推入栈
    // TODO: 实现页面访问统计逻辑
    log('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 页面弹出栈
    // TODO: 实现页面访问统计逻辑
    log('Route popped: ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 页面被移除
    // TODO: 实现页面访问统计逻辑
    log('Route removed: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // 页面被替换
    // TODO: 实现页面访问统计逻辑
    log('Route replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}
