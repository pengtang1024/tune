import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Where the local channel finds what it needs (docs/smart-lyrics.md §6.2,
/// M4).
///
/// The binary the system already has comes first: a download is the
/// fallback, not the way in. The models live in the app's own folder, and
/// the app is the only one who puts them there.
class WhisperAssets {
  /// The folders the system keeps its programs in, in the order they are
  /// searched.
  final List<String> systemFolders;

  /// The folder the app keeps its own binary in.
  final String appFolder;

  /// The folder the models live in.
  final String modelsFolder;

  const WhisperAssets({
    required this.systemFolders,
    required this.appFolder,
    required this.modelsFolder,
  });

  /// The names a whisper binary answers to across the versions.
  static const List<String> binaryNames = ['whisper-cli', 'whisper-cpp', 'whisper'];

  /// The assets of this machine: the system's program folders, the app's
  /// own folder and the models beside it.
  factory WhisperAssets.ofMachine({
    required String appFolder,
    required String modelsFolder,
  }) => WhisperAssets(
    systemFolders: (Platform.environment['PATH'] ?? '')
        .split(':')
        .where((folder) => folder.isNotEmpty)
        .toList(),
    appFolder: appFolder,
    modelsFolder: modelsFolder,
  );

  /// The assets the app opens for itself, under the application support
  /// directory — one folder for the binary the reader may bring and the
  /// models the app downloads.
  static Future<WhisperAssets> appDefault() async {
    final base = await getApplicationSupportDirectory();
    final root = Directory(path.join(base.path, 'whisper'));
    return WhisperAssets.ofMachine(
      appFolder: path.join(root.path, 'bin'),
      modelsFolder: path.join(root.path, 'models'),
    );
  }

  /// The folder the engine runs its subprocess in, under the same root as
  /// the models.
  Future<Directory> workspace() async {
    final room = Directory('$appFolder/../workspace');
    await room.create(recursive: true);
    return room;
  }

  /// The binary the words are read with, `null` when the machine has none.
  Future<File?> findBinary() async {
    for (final folder in [...systemFolders, appFolder]) {
      for (final name in binaryNames) {
        final file = File('$folder/$name');
        if (await _isRunnable(file)) return file;
      }
    }
    return null;
  }

  /// The model of [name], when it was downloaded.
  Future<File?> findModel(String name) async {
    final file = File('$modelsFolder/ggml-$name.bin');
    if (!await file.exists()) return null;
    return file;
  }

  /// Whether the file is there and the machine may run it.
  static Future<bool> _isRunnable(File file) async {
    try {
      if (!await file.exists()) return false;
      final stat = await file.stat();
      // Any of the three execute bits: a program the reader can start.
      return stat.mode & 0x49 != 0;
    } on FileSystemException {
      return false;
    }
  }
}
