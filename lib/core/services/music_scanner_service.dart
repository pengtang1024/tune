import 'dart:async';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as on_audio;
import 'package:permission_handler/permission_handler.dart';
import 'package:tune/domain/entities/song.dart';

/// 音乐扫描状态枚举
enum ScanStatus {
  /// 空闲状态
  idle,

  /// 正在扫描
  scanning,

  /// 扫描完成
  completed,

  /// 扫描出错
  error,

  /// 扫描已取消
  cancelled,
}

/// 扫描进度类
class ScanProgress {
  final ScanStatus status;
  final int progress; // 0-100
  final String message;
  final List<Song> songs;
  final int? totalSongs;

  ScanProgress({
    required this.status,
    required this.progress,
    required this.message,
    required this.songs,
    this.totalSongs,
  });
}

/// 音乐扫描服务
/// 负责处理设备上的音乐文件扫描，提供进度跟踪和状态管理功能
class MusicScannerService {
  final on_audio.OnAudioQuery _audioQuery = on_audio.OnAudioQuery();

  /// 当前扫描状态
  ScanStatus _status = ScanStatus.idle;
  ScanStatus get status => _status;

  /// 扫描进度 (0-100)
  int _progress = 0;
  int get progress => _progress;

  /// 扫描到的歌曲数量
  int _songCount = 0;
  int get songCount => _songCount;

  /// 扫描控制器，用于取消扫描
  StreamController<ScanProgress>? _scanController;

  /// 请求必要的权限
  /// 根据不同平台请求相应的权限
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13 及以上版本需要不同的权限
      try {
        final versionString = Platform.version;
        // 提取 Android 版本号
        final versionParts = versionString.split(' ');
        if (versionParts.length > 2) {
          final androidVersion = versionParts[2].split('.').first;
          final versionNumber = int.tryParse(androidVersion) ?? 0;

          if (versionNumber >= 13) {
            var status = await Permission.audio.request();
            if (status != PermissionStatus.granted) {
              // 如果权限被拒绝，打开应用设置页面
              await openAppSettings();
              return false;
            }
            return true;
          }
        }

        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          // 如果权限被拒绝，打开应用设置页面
          await openAppSettings();
          return false;
        }
        return true;
      } catch (e) {
        // 出现异常时，默认请求存储权限
        var status = await Permission.storage.request();
        if (status != PermissionStatus.granted) {
          // 如果权限被拒绝，打开应用设置页面
          await openAppSettings();
          return false;
        }
        return true;
      }
    } else if (Platform.isIOS) {
      var status = await Permission.mediaLibrary.request();
      if (status != PermissionStatus.granted) {
        // 如果权限被拒绝，打开应用设置页面
        await openAppSettings();
        return false;
      }
      return true;
    }

    // 其他平台不需要权限
    return true;
  }

  /// 全盘扫描音乐
  /// 扫描设备上的所有音乐文件
  Stream<ScanProgress> scanAllMusic() async* {
    // 检查权限
    if (!(await requestPermissions())) {
      yield ScanProgress(
        status: ScanStatus.error,
        progress: 0,
        message: '权限不足，无法扫描音乐。请在设置中授予存储访问权限。',
        songs: <Song>[],
      );
      return;
    }

    _status = ScanStatus.scanning;
    _progress = 0;

    yield ScanProgress(
      status: _status,
      progress: _progress,
      message: '开始扫描音乐',
      songs: <Song>[],
    );

    try {
      // 查询所有歌曲
      final songs = await _audioQuery.querySongs(
        sortType: on_audio.SongSortType.DATE_ADDED,
        orderType: on_audio.OrderType.DESC_OR_GREATER,
        uriType: on_audio.UriType.EXTERNAL,
      );

      _songCount = songs.length;

      // 如果没有找到歌曲，提供更明确的提示
      if (_songCount == 0) {
        _status = ScanStatus.completed;
        _progress = 100;

        yield ScanProgress(
          status: _status,
          progress: _progress,
          message: '扫描完成，但未找到任何音乐文件。请确保设备上存在音乐文件，并且文件格式受支持（如MP3、FLAC等）。',
          songs: <Song>[],
          totalSongs: _songCount,
        );
        return;
      }

      // 分批处理以显示进度
      const batchSize = 50;
      final List<Song> scannedSongs = <Song>[];

      for (int i = 0; i <= songs.length; i += batchSize) {
        // 检查是否已取消
        if (_status == ScanStatus.cancelled) {
          yield ScanProgress(
            status: _status,
            progress: _progress,
            message: '扫描已取消',
            songs: scannedSongs,
            totalSongs: _songCount,
          );
          return;
        }

        final batch = songs.skip(i).take(batchSize).toList();
        final batchSongs = <Song>[];
        for (var song in batch) {
          String? albumArtUri;
          // 修复类型问题：确保正确处理 albumArtUri
          try {
            if (song.data is Map) {
              final data = song.data as Map;
              if (data.containsKey('albumArtUri')) {
                final albumArtData = data['albumArtUri'];
                if (albumArtData != null) {
                  albumArtUri = albumArtData.toString();
                }
              }
            }
          } catch (e) {
            // 如果处理失败，保持albumArtUri为null
            albumArtUri = null;
          }

          int id = 0;
          id = song.id;

          int duration = 0;
          // 修复类型问题：安全处理 duration
          try {
            if (song.duration is int) {
              duration = song.duration as int;
            } else if (song.duration is String) {
              duration = int.tryParse(song.duration as String) ?? 0;
            } else if (song.duration != null) {
              duration = int.tryParse(song.duration.toString()) ?? 0;
            }
          } catch (e) {
            // 如果转换失败，使用默认值0
            duration = 0;
          }

          int dateAdded = 0;
          if (song.dateAdded != null) {
            if (song.dateAdded is int) {
              dateAdded = song.dateAdded as int;
            } else if (song.dateAdded is String) {
              dateAdded = int.tryParse(song.dateAdded as String) ?? 0;
            } else {
              dateAdded = song.dateAdded?.toInt() ?? 0;
            }
          }

          batchSongs.add(
            Song(
              id: id,
              title: song.title,
              artist: song.artist ?? '未知艺术家',
              album: song.album ?? '未知专辑',
              genre: song.genre ?? '未知流派',
              duration: duration,
              uri: song.uri ?? '',
              albumArtUri: albumArtUri,
              dateAdded: dateAdded,
              isFavorite: false,
            )
          );
        }

        scannedSongs.addAll(batchSongs);
        _progress = songs.isNotEmpty ? (i * 100 ~/ songs.length) : 100;

        yield ScanProgress(
          status: ScanStatus.scanning,
          progress: _progress,
          message: '正在扫描: $i/${songs.length}',
          songs: scannedSongs,
          totalSongs: _songCount,
        );

        // 添加一个小延迟，以便UI可以更新
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _status = ScanStatus.completed;
      _progress = 100;

      yield ScanProgress(
        status: _status,
        progress: _progress,
        message: '扫描完成，共找到 $_songCount 首歌曲',
        songs: scannedSongs,
        totalSongs: _songCount,
      );
    } catch (e, stackTrace) {
      _status = ScanStatus.error;
      yield ScanProgress(
        status: _status,
        progress: _progress,
        message: '扫描过程中出现错误: $e\n\n详细信息: $stackTrace',
        songs: <Song>[],
      );
    }
  }

  /// 扫描指定文件夹中的音乐
  /// 扫描指定路径下的音乐文件
  Stream<ScanProgress> scanMusicInFolder(String folderPath) async* {
    // 检查权限
    if (!(await requestPermissions())) {
      yield ScanProgress(
        status: ScanStatus.error,
        progress: 0,
        message: '权限不足，无法扫描音乐。请在设置中授予存储访问权限。',
        songs: <Song>[],
      );
      return;
    }

    _status = ScanStatus.scanning;
    _progress = 0;

    yield ScanProgress(
      status: _status,
      progress: _progress,
      message: '开始扫描文件夹: $folderPath',
      songs: <Song>[],
    );

    try {
      // 查询指定文件夹中的歌曲
      final songs = await _audioQuery.querySongs(
        sortType: on_audio.SongSortType.DATE_ADDED,
        orderType: on_audio.OrderType.DESC_OR_GREATER,
        uriType: on_audio.UriType.EXTERNAL,
        path: folderPath,
      );

      _songCount = songs.length;

      // 如果没有找到歌曲，提供更明确的提示
      if (_songCount == 0) {
        _status = ScanStatus.completed;
        _progress = 100;

        yield ScanProgress(
          status: _status,
          progress: _progress,
          message: '在指定文件夹中未找到任何音乐文件。请确保文件夹路径正确且包含受支持的音乐文件（如MP3、FLAC等）。',
          songs: <Song>[],
          totalSongs: _songCount,
        );
        return;
      }

      _progress = 100;
      _status = ScanStatus.completed;

      final scannedSongs = <Song>[];
      for (var song in songs) {
        String? albumArtUri;
        // 修复类型问题：确保正确处理 albumArtUri
        try {
          if (song.data is Map) {
            final data = song.data as Map;
            if (data.containsKey('albumArtUri')) {
              final albumArtData = data['albumArtUri'];
              if (albumArtData != null) {
                albumArtUri = albumArtData.toString();
              }
            }
          }
        } catch (e) {
          // 如果处理失败，保持albumArtUri为null
          albumArtUri = null;
        }

        int id = 0;
        id = song.id;

        int duration = 0;
        // 修复类型问题：安全处理 duration
        try {
          if (song.duration is int) {
            duration = song.duration as int;
          } else if (song.duration is String) {
            duration = int.tryParse(song.duration as String) ?? 0;
          } else if (song.duration != null) {
            duration = int.tryParse(song.duration.toString()) ?? 0;
          }
        } catch (e) {
          // 如果转换失败，使用默认值0
          duration = 0;
        }

        int dateAdded = 0;
        if (song.dateAdded != null) {
          if (song.dateAdded is int) {
            dateAdded = song.dateAdded as int;
          } else if (song.dateAdded is String) {
            dateAdded = int.tryParse(song.dateAdded as String) ?? 0;
          } else {
            dateAdded = song.dateAdded?.toInt() ?? 0;
          }
        }

        scannedSongs.add(
          Song(
            id: id,
            title: song.title,
            artist: song.artist ?? '未知艺术家',
            album: song.album ?? '未知专辑',
            genre: song.genre ?? '未知流派',
            duration: duration,
            uri: song.uri ?? '',
            albumArtUri: albumArtUri,
            dateAdded: dateAdded,
            isFavorite: false,
          )
        );
      }

      yield ScanProgress(
        status: _status,
        progress: _progress,
        message: '扫描完成，共找到 $_songCount 首歌曲',
        songs: scannedSongs,
        totalSongs: _songCount,
      );
    } catch (e, stackTrace) {
      _status = ScanStatus.error;
      yield ScanProgress(
        status: _status,
        progress: _progress,
        message: '扫描过程中出现错误: $e\n\n详细信息: $stackTrace',
        songs: <Song>[],
      );
    }
  }

  /// 取消当前扫描
  void cancelScan() {
    _status = ScanStatus.cancelled;
  }

  /// 释放资源
  void dispose() {
    _scanController?.close();
  }
}
