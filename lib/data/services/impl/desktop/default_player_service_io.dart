import 'dart:io' show File, Platform, Process;

import 'package:flutter/foundation.dart' show visibleForTesting;
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
    for (final path in desktopEntryPaths()) {
      if (File(path).existsSync()) return true;
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

  /// The files the desktop entry of Tune may live in.
  ///
  /// The desktop looks for the entries of the installed programs in the
  /// `applications` subdirectory of every data directory, so that is where
  /// they are looked for: the entry of a program that is installed for one
  /// user lives in `~/.local/share/applications`, the entry of a program
  /// that is installed for everybody lives in `/usr/share/applications`.
  @visibleForTesting
  static List<String> desktopEntryPaths({
    String? home,
    String? dataHome,
    String? dataDirectories,
  }) {
    final userHome = home ?? Platform.environment['HOME'] ?? '';
    final userDataHome = dataHome ?? Platform.environment['XDG_DATA_HOME'] ?? '';
    final systemDataDirectories =
        dataDirectories ?? Platform.environment['XDG_DATA_DIRS'] ?? '';

    final userDirectories = <String>[
      if (userDataHome.isNotEmpty) userDataHome,
      if (userHome.isNotEmpty) '$userHome/.local/share',
    ];
    // The desktop reads the system directories from XDG_DATA_DIRS and falls
    // back to the two places every desktop keeps them.
    final systemDirectories =
        systemDataDirectories.isNotEmpty
            ? systemDataDirectories
                .split(':')
                .where((directory) => directory.isNotEmpty)
            : const ['/usr/local/share', '/usr/share'];

    return [
      for (final directory in [...userDirectories, ...systemDirectories])
        '$directory/applications/$tuneDesktopEntryName',
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
