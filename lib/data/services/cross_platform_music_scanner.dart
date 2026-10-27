import 'dart:io' show Directory, File, FileSystemEntityType, Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/data/services/music_scanner_config.dart';
import 'package:tune/data/services/song_creator.dart';

/// Reads the tags of one file off the UI isolate.
///
/// Reading tags is synchronous work: a single large or malformed tag can hold
/// the thread for a second, and the scan runs while the reader is already
/// looking at the library. The worker gets the path and hands the song back.
/// On the web the worker runs where the app runs, because a browser has no
/// second thread for it.
Future<Song?> _readSongWorker(String filePath) =>
    compute(_songOfFile, filePath);

/// The worker of [_readSongWorker]; [compute] wants a top-level function.
Future<Song?> _songOfFile(String filePath) =>
    SongCreator.createFromFile(File(filePath));

/// Reads the tags of a batch of files in one worker.
///
/// A scan of twenty thousand files used to pay for one isolate per file and
/// read them strictly one by one; the batch hands one isolate a hundred
/// files at a time, and a handful of batches run side by side.
Future<List<Song?>?> _readSongsWorker(List<String> filePaths) =>
    compute(_songsOfFiles, filePaths);

/// The worker of [_readSongsFiles]; [compute] wants a top-level function.
Future<List<Song?>> _songsOfFiles(List<String> filePaths) async {
  final songs = <Song?>[];
  for (final filePath in filePaths) {
    try {
      songs.add(await SongCreator.createFromFile(File(filePath)));
    } catch (error) {
      Log.info('CrossPlatformMusicScanner: Failed to create song from file $filePath: $error');
      songs.add(null);
    }
  }
  return songs;
}

/// 跨平台音乐扫描服务接口
abstract class CrossPlatformMusicScanner {
  Future<void> init();
  Future<List<Song>> scanMusic();
  Future<List<Song>> scanMusicInDirectory(String directoryPath);
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths);
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  );
  Future<Song?> scanMusicFile(String filePath);
  Future<List<Song>> getAllSongs();
  Future<List<Song>> searchSongs(String query);
  List<String> getDefaultMusicPaths();
  Future<List<Song>> scanCustomPaths(List<String> paths);
}

/// 跨平台音乐扫描服务实现
class CrossPlatformMusicScannerImpl implements CrossPlatformMusicScanner {
  CrossPlatformMusicScannerImpl();

  /// How many batches read their tags at the same time.
  static const int _maxWorkers = 8;

  @override
  Future<void> init() async {
    Log.info('CrossPlatformMusicScannerImpl: 初始化完成');
  }

  @override
  Future<List<Song>> scanMusic() async {
    Log.info('CrossPlatformMusicScanner: Starting cross-platform music scan');

    if (kIsWeb) {
      Log.info('CrossPlatformMusicScanner: Running on Web platform');
      return [];
    } else if (Platform.isAndroid || Platform.isIOS) {
      Log.info('CrossPlatformMusicScanner: Running on mobile platform');
      try {
        final paths = MusicScannerConfig.getMobileMusicPaths();
        return await scanMusicInDirectories(paths);
      } catch (e) {
        Log.error('Failed to scan mobile music: $e');
        return [];
      }
    } else {
      Log.info('CrossPlatformMusicScanner: Running on desktop platform');
      final defaultPaths = getDefaultMusicPaths();
      return await scanMusicInDirectories(defaultPaths);
    }
  }

  @override
  Future<List<Song>> scanMusicInDirectory(String directoryPath) async {
    Log.info('CrossPlatformMusicScanner: Scanning directory: $directoryPath');
    return await _scanDirectory(directoryPath, (progress) {});
  }

  @override
  Future<List<Song>> scanMusicInDirectories(List<String> directoryPaths) async {
    Log.info(
      'CrossPlatformMusicScanner: Scanning ${directoryPaths.length} directories',
    );
    return await scanMusicInDirectoriesWithProgress(
      directoryPaths,
      (progress) {},
    );
  }

  @override
  Future<List<Song>> scanMusicInDirectoriesWithProgress(
    List<String> directoryPaths,
    Function(double) onProgress,
  ) async {
    Log.info(
      'CrossPlatformMusicScanner: Scanning ${directoryPaths.length} directories with progress',
    );
    final allSongs = <Song>[];

    for (int i = 0; i < directoryPaths.length; i++) {
      final dirPath = directoryPaths[i];
      try {
        final songs = await _scanDirectory(dirPath, (progress) {
          final overallProgress = (i + progress) / directoryPaths.length;
          onProgress(overallProgress);
        });
        allSongs.addAll(songs);
      } catch (e) {
        Log.info(
          'CrossPlatformMusicScanner: Failed to scan directory $dirPath: $e',
        );
      }
      onProgress((i + 1) / directoryPaths.length);
    }

    return allSongs;
  }

  @override
  Future<Song?> scanMusicFile(String filePath) async {
    Log.info('CrossPlatformMusicScanner: Scanning single file: $filePath');
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await _readSongWorker(filePath);
      }
    } catch (e) {
      Log.info('CrossPlatformMusicScanner: Failed to scan file $filePath: $e');
    }
    return null;
  }

  @override
  Future<List<Song>> getAllSongs() async {
    return await scanMusic();
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    final allSongs = await scanMusic();
    if (query.isEmpty) {
      return allSongs;
    }

    return allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  List<String> getDefaultMusicPaths() {
    return MusicScannerConfig.getDefaultMusicPaths();
  }

  Future<List<Song>> _scanDirectory(
    String directoryPath,
    Function(double) onProgress,
  ) async {
    final songs = <Song>[];
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      Log.info(
        'CrossPlatformMusicScanner: Directory does not exist: $directoryPath',
      );
      return songs;
    }

    try {
      final files = <File>[];
      await for (final file in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (file is File && MusicScannerConfig.isAudioFile(file.path)) {
          files.add(file);
        }
      }

      Log.info(
        'CrossPlatformMusicScanner: Found ${files.length} audio files in directory: $directoryPath',
      );

      // The batches are read by a fixed pool of workers side by side; the
      // pool is the processors the machine has, capped, so the scan cannot
      // crowd the rest of the desktop out.
      const chunkSize = 200;
      final chunks = <List<String>>[
        for (var start = 0; start < files.length; start += chunkSize)
          [
            for (var index = start; index < files.length && index < start + chunkSize; index++)
              files[index].path,
          ],
      ];
      final results = List<List<Song?>?>.filled(chunks.length, null);
      var nextChunk = 0;
      var processed = 0;
      Future<void> worker() async {
        while (true) {
          final index = nextChunk++;
          if (index >= chunks.length) return;
          try {
            results[index] = await _readSongsWorker(chunks[index]);
          } catch (error, stackTrace) {
            Log.error('读取一批文件的标签失败: $error\n$stackTrace');
          }
          processed += chunks[index].length;
          onProgress(processed / files.length);
        }
      }

      final workers = math.min(_maxWorkers, chunks.length);
      await Future.wait([
        for (var pool = 0; pool < workers; pool++) worker(),
      ]);
      songs.addAll([
        for (final result in results)
          if (result != null) ...result.whereType<Song>(),
      ]);
    } catch (e) {
      Log.info(
        'CrossPlatformMusicScanner: Error scanning directory $directoryPath: $e',
      );
    }

    Log.info(
      'CrossPlatformMusicScanner: Found ${songs.length} songs in directory: $directoryPath',
    );
    return songs;
  }

  @override
  Future<List<Song>> scanCustomPaths(List<String> paths) async {
    try {
      Log.info('开始扫描自定义路径: $paths');
      final allSongs = <Song>[];

      if (paths.isEmpty) {
        Log.info('自定义扫描路径列表为空');
        return allSongs;
      }

      for (final dirPath in paths) {
        try {
          Log.info('扫描路径: $dirPath');
          if (dirPath.isEmpty) {
            Log.info('跳过空路径');
            continue;
          }

          if (!MusicScannerConfig.isValidPath(dirPath)) {
            Log.info('无效路径，跳过: $dirPath');
            continue;
          }

          final dir = Directory(dirPath);
          if (!await dir.exists()) {
            Log.info('目录不存在，跳过: $dirPath');
            continue;
          }

          final stat = await dir.stat();
          if (stat.type != FileSystemEntityType.directory) {
            Log.info('路径不是目录，跳过: $dirPath');
            continue;
          }

          await for (final file in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            try {
              if (file is File) {
                if (!MusicScannerConfig.isValidPath(file.path)) {
                  Log.info('无效文件路径，跳过: ${file.path}');
                  continue;
                }

                if (MusicScannerConfig.isAudioFile(file.path)) {
                  final song = await _readSongWorker(file.path);
                  if (song != null) {
                    allSongs.add(song);
                  }
                }
              }
            } catch (e, stackTrace) {
              Log.error('处理文件时出错: ${file.path}, 错误: $e', stackTrace);
              continue;
            }
          }
        } catch (e, stackTrace) {
          Log.error('扫描路径时出错: $dirPath, 错误: $e', stackTrace);
          continue;
        }
      }

      Log.info('扫描完成，共找到 ${allSongs.length} 首歌曲');
      return allSongs;
    } catch (e, stackTrace) {
      Log.error('扫描自定义路径时发生严重错误: $e', stackTrace);
      rethrow;
    }
  }
}
