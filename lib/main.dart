import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/app.dart';
import 'package:tune/app/licenses.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_auto_fill_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_leak_check_controller.dart';
import 'package:tune/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerThirdPartyLicenses();

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
    UncontrolledProviderScope(container: container, child: const TuneApp()),
  );

  // The free check of the smart lyrics pipeline (docs/smart-lyrics.md
  // §7.2): periodic, quiet, and free — the loop it lives in starts once,
  // here, and every tick decides for itself whether the machine is idle
  // enough to ask the human pool again.
  container.read(smartLyricsLeakCheckControllerProvider).start();

  // The library fills itself (2026-10-29 用户拍板): with the toggle on —
  // and it is on by default — the batch drains the gap until every song
  // carries words. No button, no queue-watching; the toggle closes the
  // door and the loop walks through it.
  container.read(smartLyricsAutoFillControllerProvider).start();
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
