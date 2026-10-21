import 'dart:io';

import 'package:tune/utils/logger.dart';

/// Hands a file or an address to the desktop.
///
/// The desktop knows what to do with a file: it opens the file with the
/// program the reader chose for that kind of file. The app does not open a
/// file manager of its own, so it asks the desktop through the tool the
/// desktop itself uses.
Future<bool> openExternal(String target) async {
  if (!Platform.isLinux) return false;

  try {
    final result = await Process.run('xdg-open', [target]);
    if (result.exitCode != 0) {
      Log.error('xdg-open 打开失败: ${result.stderr}');
      return false;
    }
    return true;
  } catch (error, stackTrace) {
    Log.error('调用 xdg-open 失败: $error\n$stackTrace');
    return false;
  }
}
