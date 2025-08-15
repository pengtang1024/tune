import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension RouterExtension on BuildContext {
  GoRouter get router => GoRouter.of(this);

  GoRouterDelegate get routerDelegate => router.routerDelegate;

  RouteInformationParser get routeInformationParser => router.routeInformationParser;
}