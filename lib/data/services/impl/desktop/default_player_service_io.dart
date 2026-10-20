import 'dart:io' show File, Platform, Process;

import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/desktop/default_player_service.dart';
import 'package:tune/utils/logger.dart';

/// The default handler of audio files, as the desktop sees it.
///
/// The desktop is asked through `xdg-mime`, the tool that reads and writes
/// the associations of the desktop.
class DefaultPlayerServiceImpl implements DefaultPlayerService {
  @override
  bool get isSupported => Platform.isLinux;

  @override
  Future<bool> isDesktopEntryInstalled() async {
    for (final directory in _applicationDirectories()) {
      final entry = File('$directory/$tuneDesktopEntryName');
      if (entry.existsSync()) return true;
    }
    return false;
  }

  @override
  Future<bool> isDefaultHandler(String mimeType) async {
    final result = await _run(['query', 'default', mimeType]);
    if (result == null) return false;
    return result.trim() == tuneDesktopEntryName;
  }

  @override
  Future<bool> makeDefaultHandler(String mimeType) async {
    final result = await _run(['default', tuneDesktopEntryName, mimeType]);
    return result != null;
  }

  /// The directories the desktop looks for desktop entries in.
  List<String> _applicationDirectories() {
    final home = Platform.environment['HOME'] ?? '';
    final dataHome = Platform.environment['XDG_DATA_HOME'];
    return [
      if (dataHome != null && dataHome.isNotEmpty) dataHome,
      if (home.isNotEmpty) '$home/.local/share',
      '/usr/local/share',
      '/usr/share',
    ];
  }

  /// Runs `xdg-mime` and returns what it printed, or null when it failed.
  Future<String?> _run(List<String> arguments) async {
    if (!isSupported) return null;
    try {
      final result = await Process.run('xdg-mime', arguments);
      if (result.exitCode != 0) {
        Log.error('xdg-mime ${arguments.join(' ')} 失败: ${result.stderr}');
        return null;
      }
      return result.stdout as String;
    } catch (error, stackTrace) {
      Log.error('调用 xdg-mime 失败: $error\n$stackTrace');
      return null;
    }
  }
}
