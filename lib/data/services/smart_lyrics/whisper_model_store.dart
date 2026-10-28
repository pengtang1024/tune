import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:tune/utils/logger.dart';

/// The model of the local channel could not be fetched or does not match.
class WhisperModelException implements Exception {
  final String message;

  const WhisperModelException(this.message);

  @override
  String toString() => 'WhisperModelException: $message';
}

/// The models of the local whisper channel (docs/smart-lyrics.md §6.2,
/// M4): the app keeps them in its own folder, downloads them from the
/// whisper.cpp home, and checks every file against the checksum the home
/// publishes — a truncated or swapped file never becomes the model.
class WhisperModelStore {
  /// The folder the models live in.
  final Directory root;
  final Dio _dio;

  /// Where the models come from: the whisper.cpp home on the model hub.
  final String home;

  WhisperModelStore({
    required this.root,
    Dio? dio,
    this.home = 'https://huggingface.co/ggerganov/whisper.cpp',
  }) : _dio = dio ?? Dio();

  /// The file the model of [name] is in, when it is downloaded.
  Future<File?> findModel(String name) async {
    final file = File('${root.path}/${_fileNameOf(name)}');
    if (!await file.exists()) return null;
    return file;
  }

  /// The checksum the home publishes for the model of [name], `null` when
  /// the home says nothing about it.
  Future<String?> checksumOf(String name) async {
    final entry = await _entryOf(name);
    if (entry == null) return null;
    final lfs = entry['lfs'];
    if (lfs is! Map) return null;
    final digest = lfs['sha256'];
    return digest is String ? digest : null;
  }

  /// The size the home publishes for the model of [name].
  Future<int?> sizeOf(String name) async {
    final entry = await _entryOf(name);
    if (entry == null) return null;
    final lfs = entry['lfs'];
    if (lfs is! Map) return null;
    final size = lfs['size'];
    return size is num ? size.toInt() : int.tryParse('$size');
  }

  /// Downloads the model of [name] and checks it against [checksum].
  ///
  /// The file lands under its own name only when it is whole: a wrong
  /// checksum throws the download away, so a broken model never reaches a
  /// song.
  Future<void> download(
    String name, {
    required String checksum,
    void Function(double progress)? onProgress,
  }) async {
    final target = File('${root.path}/${_fileNameOf(name)}');
    final staging = File('${root.path}/.${_fileNameOf(name)}.part');
    try {
      await _dio.download(
        '$home/resolve/main/${_fileNameOf(name)}',
        staging.path,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          onProgress?.call((received / total).clamp(0, 1));
        },
      );

      final digest = await _sha256Of(staging);
      if (digest != checksum.toLowerCase()) {
        throw WhisperModelException(
          'the model of $name does not match the checksum the home published',
        );
      }

      await target.parent.create(recursive: true);
      if (await target.exists()) await target.delete();
      await staging.rename(target.path);
    } catch (error, stackTrace) {
      Log.error('本地模型下载失败: $error', stackTrace);
      if (await staging.exists()) await staging.delete();
      if (error is WhisperModelException) rethrow;
      throw WhisperModelException('the model of $name could not be fetched');
    }
  }

  /// The checksum of the file, read in pieces — a model is bigger than
  /// memory should have to hold.
  static Future<String> _sha256Of(File file) async {
    final digest = await file.openRead().transform(sha256).first;
    return digest.toString();
  }

  /// The row the home's file list holds for the model of [name].
  Future<Map<String, dynamic>?> _entryOf(String name) async {
    try {
      final response = await _dio.get<String>(
        'https://huggingface.co/api/models/ggerganov/whisper.cpp/tree/main',
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) return null;
      final decoded = jsonDecode(body);
      final rows = decoded is List
          ? decoded
          : (decoded is Map && decoded['objects'] is List
                ? decoded['objects'] as List
                : const []);
      final wanted = _fileNameOf(name);
      for (final row in rows) {
        if (row is Map && row['path'] == wanted) {
          return Map<String, dynamic>.from(row);
        }
      }
      return null;
    } catch (error, stackTrace) {
      Log.error('读取模型清单失败: $error', stackTrace);
      return null;
    }
  }

  static String _fileNameOf(String name) => 'ggml-$name.bin';
}
