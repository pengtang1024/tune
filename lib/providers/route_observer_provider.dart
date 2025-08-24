import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 路由观察器状态
class RouteObserverState {
  final String route;

  RouteObserverState({required this.route});

  RouteObserverState copyWith({
    String? route,
  }) {
    return RouteObserverState(
      route: route ?? this.route,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteObserverState && other.route == route;
  }

  @override
  int get hashCode => route.hashCode;
}

/// 路由观察器状态提供者
final routeObserverProvider = StateProvider<RouteObserverState>((ref) {
  return RouteObserverState(route: '/');
});