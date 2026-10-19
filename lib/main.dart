import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/app.dart';
import 'package:tune/utils/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Log.error(
      'Flutter未捕获错误: ${details.exceptionAsString()}\n'
      '${details.stack?.toString() ?? ''}',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    Log.error('平台层未捕获错误: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: TuneApp()));
}
