import 'dart:io' show Directory, Platform;
import 'package:path/path.dart' as path;

/// 音乐扫描配置类
class MusicScannerConfig {
  // 支持的音频文件扩展名
  static const List<String> supportedAudioExtensions = [
    '.mp3',
    '.flac',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
  ];

  // 获取默认音乐路径
  static List<String> getDefaultMusicPaths() {
    final paths = <String>[];

    if (Platform.isWindows) {
      final userHome = Platform.environment['USERPROFILE'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isMacOS) {
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isLinux) {
      final userHome = Platform.environment['HOME'];
      if (userHome != null) {
        paths.add(path.join(userHome, 'Music'));
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      paths.addAll(getMobileMusicPaths());
    }

    return paths;
  }

  /// 机器上的音乐库：第一个存在的默认音乐路径。
  ///
  /// 扫描路径和 app 写入文件的位置都用它，两边说的是同一个地方。
  static String? getDefaultMusicLibrary() {
    final paths = getDefaultMusicPaths();
    for (final candidate in paths) {
      if (Directory(candidate).existsSync()) return candidate;
    }
    return paths.isEmpty ? null : paths.first;
  }

  // 获取移动平台音乐路径
  static List<String> getMobileMusicPaths() {
    if (Platform.isAndroid) {
      return ['/storage/emulated/0/Music'];
    } else if (Platform.isIOS) {
      return ['/var/mobile/Media/Music'];
    }
    return [];
  }

  // 检查文件是否为音频文件
  static bool isAudioFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return supportedAudioExtensions.contains(ext);
  }

  // 验证路径是否安全，防止路径遍历攻击
  static bool isValidPath(String inputPath) {
    try {
      final normalizedPath = path.normalize(inputPath);
      if (normalizedPath.contains('..')) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
