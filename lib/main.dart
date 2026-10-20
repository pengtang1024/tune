import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/app.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/utils/logger.dart';

Future<void> main() async {
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

  final container = ProviderContainer();
  if (!await _claimThePlayerPlace(container)) {
    // Another player is already running; it got the files and the window.
    container.dispose();
    // The engine of the desktop keeps the process alive after the main
    // function is done, so this start ends the process by itself.
    await SystemNavigator.pop();
    return;
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TuneApp(),
    ),
  );
}

/// Takes the place of the player on the machine.
///
/// The place on the bus belongs to one player. A start that finds the place
/// taken hands its files over to the running player and leaves, so the
/// machine never has two players fighting over the sound card.
Future<bool> _claimThePlayerPlace(ProviderContainer container) async {
  final service = container.read(singleInstanceServiceProvider);

  final holdsPlace = await service.acquire();
  final files = service.startupFiles;
  if (files.isNotEmpty) Log.info('命令行里的文件: $files');

  if (!holdsPlace) {
    Log.info('已有播放器在运行，把文件交给它');
    await service.forwardFiles(files);
    await service.forwardActivation();
    return false;
  }

  service.requestFiles(files);
  return true;
}
