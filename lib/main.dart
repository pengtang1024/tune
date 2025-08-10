import 'package:flutter/material.dart';
import 'package:tune/app/app.dart';
import 'package:tune/app/app_initializer.dart';

void main() async {
  // 初始化应用
  await AppInitializer.init();

  // 运行应用
  runApp(const App());
}
