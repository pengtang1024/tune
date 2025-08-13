import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:tune/domain/entities/song.dart';
import 'package:tune/core/services/music_scanner_service.dart' as music_scanner_service;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as audio_metadata_reader;

/// 跨平台音乐扫描服务接口
abstract class PlatformMusicScannerService {
  /// 扫描所有音乐
  Stream<music_scanner_service.ScanProgress> scanAllMusic();

  /// 扫描指定文件夹中的音乐
  Stream<music_scanner_service.ScanProgress> scanMusicInFolder(String folderPath);

  /// 取消扫描
  void cancelScan();

  /// 请求权限
  Future<bool> requestPermissions();
}

/// Android平台音乐扫描服务
class AndroidMusicScannerService implements PlatformMusicScannerService {
  final music_scanner_service.MusicScannerService _scannerService = music_scanner_service.MusicScannerService();
  
  @override
  Stream<music_scanner_service.ScanProgress> scanAllMusic() {
    return _scannerService.scanAllMusic();
  }

  @override
  Stream<music_scanner_service.ScanProgress> scanMusicInFolder(String folderPath) {
    return _scannerService.scanMusicInFolder(folderPath);
  }

  @override
  void cancelScan() {
    _scannerService.cancelScan();
  }

  @override
  Future<bool> requestPermissions() {
    return _scannerService.requestPermissions();
  }
}

/// iOS平台音乐扫描服务
class IOSMusicScannerService implements PlatformMusicScannerService {
  final music_scanner_service.MusicScannerService _scannerService = music_scanner_service.MusicScannerService();

  @override
  Stream<music_scanner_service.ScanProgress> scanAllMusic() {
    return _scannerService.scanAllMusic();
  }

  @override
  Stream<music_scanner_service.ScanProgress> scanMusicInFolder(String folderPath) {
    return _scannerService.scanMusicInFolder(folderPath);
  }

  @override
  void cancelScan() {
    _scannerService.cancelScan();
  }

  @override
  Future<bool> requestPermissions() {
    return _scannerService.requestPermissions();
  }
}

/// 桌面平台音乐扫描服务
class DesktopMusicScannerService implements PlatformMusicScannerService {
  bool _isCancelled = false;
  
  /// 常见的音乐文件夹路径
  List<String> get _commonMusicPaths {
    final paths = <String>[];
    
    // Windows
    if (Platform.isWindows) {
      final userprofile = Platform.environment['USERPROFILE'];
      if (userprofile != null) {
        paths.add(path.join(userprofile, 'Music'));
      }
    }
    
    // macOS
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(path.join(home, 'Music'));
      }
    }
    
    // Linux
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(path.join(home, 'Music'));
      }
    }
    
    // 通用路径（如果上面没有添加）
    final home = Platform.environment['HOME'];
    if (home != null) {
      final musicPath = path.join(home, 'Music');
      if (!paths.contains(musicPath)) {
        paths.add(musicPath);
      }
    }
    
    // 中文路径
    if (Platform.isWindows) {
      final userprofile = Platform.environment['USERPROFILE'];
      if (userprofile != null) {
        paths.add(path.join(userprofile, '音乐'));
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(path.join(home, '音乐'));
      }
    }
    
    return paths;
  }

  DesktopMusicScannerService() {
    print('=== 创建 DesktopMusicScannerService 实例 ===');
    print('当前平台: ${Platform.operatingSystem}');
    print('平台版本: ${Platform.operatingSystemVersion}');
    print('Dart 版本: ${Platform.version}');
    print('常见音乐路径列表:');
    for (int i = 0; i < _commonMusicPaths.length; i++) {
      print('  [$i] ${_commonMusicPaths[i]}');
    }
    
    // 验证每个路径是否存在
    print('验证路径是否存在:');
    for (int i = 0; i < _commonMusicPaths.length; i++) {
      final dir = Directory(_commonMusicPaths[i]);
      final exists = dir.existsSync();
      print('  [$i] ${_commonMusicPaths[i]}: ${exists ? "存在" : "不存在"}');
    }
  }

  @override
  Stream<music_scanner_service.ScanProgress> scanAllMusic() async* {
    _isCancelled = false;
    
    print('=== 开始全盘扫描音乐 ===');
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.idle,
      progress: 0,
      message: '开始扫描音乐',
      songs: <Song>[],
    );

    try {
      // 获取所有可能的音乐目录
      final possibleMusicDirs = await _getPossibleMusicDirectories();
      
      if (_isCancelled) {
        print('扫描已被取消');
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.cancelled,
          progress: 0,
          message: '扫描已取消',
          songs: <Song>[],
        );
        return;
      }
      
      // 确保所有目录存在
      final validDirs = <Directory>[];
      for (final dir in possibleMusicDirs) {
        if (await dir.exists()) {
          validDirs.add(dir);
          print('目录存在: ${dir.path}');
        } else {
          print('目录不存在，跳过: ${dir.path}');
        }
      }
      
      if (validDirs.isEmpty) {
        final message = '未找到任何音乐目录，使用应用程序文档目录';
        print(message);
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.scanning,
          progress: 5,
          message: message,
          songs: <Song>[],
        );
        
        final appDocDir = await getApplicationDocumentsDirectory();
        validDirs.add(appDocDir);
      }
      
      // 开始扫描有效的目录
      final allSongs = <Song>[];
      final totalDirs = validDirs.length;
      
      print('开始扫描 $totalDirs 个有效目录');
      for (int i = 0; i < validDirs.length; i++) {
        if (_isCancelled) break;
        
        final dir = validDirs[i];
        final progressPercent = ((i / totalDirs) * 90).toInt() + 5; // 从5%开始到95%
        
        final dirMessage = '正在扫描目录 ($i/$totalDirs): ${dir.path}';
        print(dirMessage);
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.scanning,
          progress: progressPercent,
          message: dirMessage,
          songs: allSongs,
        );
        
        try {
          final songs = await _scanDirectory(dir);
          allSongs.addAll(songs);
          
          final dirMessage = '完成扫描目录 ($i/$totalDirs): ${dir.path}，找到 ${songs.length} 首歌曲';
          print(dirMessage);
          yield music_scanner_service.ScanProgress(
            status: music_scanner_service.ScanStatus.scanning,
            progress: progressPercent,
            message: dirMessage,
            songs: allSongs,
          );
        } catch (e) {
          print('扫描目录时出错 ${dir.path}: $e');
        }
      }
      
      if (_isCancelled) {
        print('扫描已被取消');
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.cancelled,
          progress: 0,
          message: '扫描已取消',
          songs: <Song>[],
        );
        return;
      }
      
      // 最终完成状态
      final successMsg = '扫描成功完成，共扫描 ${validDirs.length} 个目录，找到 ${allSongs.length} 首歌曲';
      print(successMsg);
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.completed,
        progress: 100,
        message: successMsg,
        songs: allSongs,
        totalSongs: allSongs.length,
      );
    } catch (e, stackTrace) {
      final errorMsg = '扫描过程中出现未捕获的错误: $e';
      print(errorMsg);
      print('错误堆栈: $stackTrace');
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.error,
        progress: 0,
        message: '$errorMsg\n\n详细信息: $stackTrace',
        songs: <Song>[],
      );
    }
    
    print('=== 全盘扫描音乐过程结束 ===');
  }
  
  /// 获取所有可能的音乐目录
  Future<List<Directory>> _getPossibleMusicDirectories() async {
    final dirs = <Directory>[];
    
    print('=== 获取所有可能的音乐目录 ===');
    print('当前平台: ${Platform.operatingSystem}');
    
    // 添加标准音乐目录
    try {
      final musicDir = await getMusicDirectory();
      print('添加标准音乐目录: ${musicDir.path}');
      dirs.add(musicDir);
    } catch (e) {
      print('无法获取标准音乐目录: $e');
    }
    
    // 添加常见音乐路径
    for (final path in _commonMusicPaths) {
      print('添加常见音乐路径: $path');
      dirs.add(Directory(path));
    }
    
    // 去重并过滤掉不存在的目录
    final uniqueDirs = <Directory>[];
    final seenPaths = <String>{};
    
    for (final dir in dirs) {
      // 标准化路径以避免重复
      final normalizedPath = path.normalize(dir.path);
      if (!seenPaths.contains(normalizedPath)) {
        seenPaths.add(normalizedPath);
        uniqueDirs.add(dir);
      }
    }
    
    print('找到 ${uniqueDirs.length} 个可能的音乐目录');
    for (int i = 0; i < uniqueDirs.length; i++) {
      print('  [$i] ${uniqueDirs[i].path}');
    }
    
    return uniqueDirs;
  }

  @override
  Stream<music_scanner_service.ScanProgress> scanMusicInFolder(String folderPath) async* {
    _isCancelled = false;
    
    print('=== 开始扫描指定文件夹 ===');
    print('文件夹路径: $folderPath');
    
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.scanning,
      progress: 0,
      message: '开始扫描文件夹: $folderPath',
      songs: <Song>[],
    );

    try {
      final folder = Directory(folderPath);
      print('检查文件夹是否存在...');
      final folderExists = await folder.exists();
      print('文件夹存在状态: $folderExists');
      
      if (!folderExists) {
        print('指定的文件夹不存在: $folderPath');
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.error,
          progress: 0,
          message: '指定的文件夹不存在: $folderPath',
          songs: <Song>[],
        );
        return;
      }
      
      print('准备扫描文件夹中的音乐文件...');
      // 扫描音乐文件
      final songs = await _scanDirectory(folder);
      print('文件夹扫描完成，找到 ${songs.length} 首歌曲');
      
      if (_isCancelled) {
        print('扫描已被取消');
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.cancelled,
          progress: 0,
          message: '扫描已取消',
          songs: <Song>[],
        );
        return;
      }
      
      print('文件夹扫描成功完成，共找到 ${songs.length} 首歌曲');
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.completed,
        progress: 100,
        message: '扫描完成，共找到 ${songs.length} 首歌曲',
        songs: songs,
        totalSongs: songs.length,
      );
    } catch (e, stackTrace) {
      print('扫描文件夹过程中出现未捕获的错误: $e');
      print('错误堆栈: $stackTrace');
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.error,
        progress: 0,
        message: '扫描过程中出现错误: $e\n\n详细信息: $stackTrace',
        songs: <Song>[],
      );
    }
    
    print('=== 文件夹扫描过程结束 ===');
  }

  /// 扫描指定的多个目录
  Stream<music_scanner_service.ScanProgress> scanMusicInFolders(List<String> folderPaths) async* {
    _isCancelled = false;
    
    print('=== 开始扫描指定的多个文件夹 ===');
    for (var path in folderPaths) {
      print('  扫描路径: $path');
    }
    
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.scanning,
      progress: 0,
      message: '开始扫描 ${folderPaths.length} 个文件夹',
      songs: <Song>[],
    );

    try {
      final allSongs = <Song>[];
      final totalFolders = folderPaths.length;
      
      for (int i = 0; i < folderPaths.length; i++) {
        if (_isCancelled) break;
        
        final folderPath = folderPaths[i];
        final progressPercent = ((i / totalFolders) * 100).toInt();
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.scanning,
          progress: progressPercent,
          message: '正在扫描文件夹 ($i/${totalFolders}): $folderPath',
          songs: allSongs,
        );
        
        final folder = Directory(folderPath);
        print('检查文件夹是否存在...');
        final folderExists = await folder.exists();
        print('文件夹存在状态: $folderExists');
        
        if (!folderExists) {
          print('指定的文件夹不存在: $folderPath');
          yield music_scanner_service.ScanProgress(
            status: music_scanner_service.ScanStatus.scanning,
            progress: progressPercent,
            message: '文件夹不存在，跳过: $folderPath',
            songs: allSongs,
          );
          continue;
        }
        
        print('准备扫描文件夹中的音乐文件...');
        // 扫描音乐文件
        final songs = await _scanDirectory(folder);
        allSongs.addAll(songs);
        print('文件夹扫描完成，找到 ${songs.length} 首歌曲');
        
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.scanning,
          progress: progressPercent,
          message: '完成扫描文件夹 ($i/${totalFolders}): $folderPath，找到 ${songs.length} 首歌曲',
          songs: allSongs,
        );
      }
      
      if (_isCancelled) {
        print('扫描已被取消');
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.cancelled,
          progress: 0,
          message: '扫描已取消',
          songs: <Song>[],
        );
        return;
      }
      
      // 最终完成状态
      final successMsg = '扫描成功完成，共扫描 ${folderPaths.length} 个文件夹，找到 ${allSongs.length} 首歌曲';
      print(successMsg);
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.completed,
        progress: 100,
        message: successMsg,
        songs: allSongs,
        totalSongs: allSongs.length,
      );
    } catch (e, stackTrace) {
      print('扫描文件夹过程中出现未捕获的错误: $e');
      print('错误堆栈: $stackTrace');
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.error,
        progress: 0,
        message: '扫描过程中出现错误: $e\n\n详细信息: $stackTrace',
        songs: <Song>[],
      );
    }
    
    print('=== 多文件夹扫描过程结束 ===');
  }

  /// 获取音频文件扩展名列表
  Set<String> _getAudioExtensions() {
    return {
      '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma', '.aiff', '.aif', 
      '.ape', '.wv', '.mp4', '.m4b', '.m4p', '.m4r', '.3gp', '.3g2', '.opus', 
      '.oga', '.spx', '.asf', '.amr', '.alac', '.ac3', '.dts', '.dff', '.dsf', 
      '.mka', '.m3u', '.m3u8', '.pls', '.cue', '.sdi', '.kar', '.mid', '.rmi'
    };
  }
  
  /// 扫描目录中的所有音频文件
  Future<List<Song>> _scanDirectory(Directory directory) async {
    final songs = <Song>[];
    final audioExtensions = _getAudioExtensions();
    
    try {
      print('开始扫描目录: ${directory.path}');
      if (!(await directory.exists())) {
        print('目录不存在: ${directory.path}');
        return songs;
      }
      print('目录可访问');
    } catch (e) {
      print('错误: 无法访问目录，可能是权限问题: $e');
      return songs;
    }
    
    // 获取目录中的所有文件
    print('正在列出目录中的所有文件（递归）...');
    Stream<FileSystemEntity> entitiesStream;
    try {
      entitiesStream = directory.list(recursive: true);
    } catch (e) {
      print('错误: 无法列出目录内容: $e');
      return songs;
    }
    
    final entities = <FileSystemEntity>[];
    await for (final entity in entitiesStream) {
      entities.add(entity);
    }
    print('目录列表完成，共找到 ${entities.length} 个项目');
    
    // 分离文件和目录
    final files = entities.whereType<File>().toList();
    final dirs = entities.whereType<Directory>().toList();
    print('其中文件数量: ${files.length}');
    print('其中目录数量: ${dirs.length}');
    
    // 显示前几个目录（用于调试）
    print('前5个目录:');
    for (int i = 0; i < dirs.length && i < 5; i++) {
      print('  ${dirs[i].path}');
    }
    
    int processed = 0;
    int matchedFiles = 0;
    int totalFiles = files.length;
    
    print('开始处理文件...');
    for (final file in files) {
      if (_isCancelled) {
        print('扫描已被取消');
        break;
      }
      
      final filePath = file.path;
      final fileExtension = path.extension(filePath).toLowerCase();
      
      // 显示正在处理的文件（前10个和每第100个）
      if (processed < 10 || processed % 100 == 0) {
        print('处理文件 ($processed/$totalFiles): $filePath');
      }
      
      if (audioExtensions.contains(fileExtension)) {
        print('发现音频文件: $filePath');
        matchedFiles++;
        
        try {
          final fileName = path.basenameWithoutExtension(filePath);
          int dateAdded = DateTime.now().millisecondsSinceEpoch;
          
          try {
            final stat = await file.stat();
            // 直接访问stat.changed属性，避免构造新的FileStat对象
            dateAdded = stat.changed.millisecondsSinceEpoch;
          } catch (e) {
            print('无法获取文件状态信息: $e');
            // 使用当前时间作为默认值
            dateAdded = DateTime.now().millisecondsSinceEpoch;
          }
          
          // 使用audio_metadata_reader获取音频元数据
          int duration = 0;
          String title = fileName;
          String artist = '未知艺术家';
          String album = '未知专辑';
          String genre = '未知流派';

          try {
            final file = File(filePath);
            final metadata = audio_metadata_reader.readMetadata(file);

            // 获取音频时长
            if (metadata.duration != null) {
              duration = metadata.duration!.inMilliseconds;
              print('音频文件时长: ${duration}ms');
            } else {
              print('无法获取音频时长');
            }

            // 获取标题
            if (metadata.title != null && metadata.title!.isNotEmpty) {
              title = metadata.title!;
            }

            // 获取艺术家
            if (metadata.artist != null && metadata.artist!.isNotEmpty) {
              artist = metadata.artist!;
            }

            // 获取专辑
            if (metadata.album != null && metadata.album!.isNotEmpty) {
              album = metadata.album!;
            }

            print('音频文件元数据: 标题=$title, 艺术家=$artist, 专辑=$album');
          } catch (e) {
            print('使用audio_metadata_reader获取元数据失败: $e');
          }

          
          // 过滤时长少于5秒的音频文件
          if (duration < 5000) { // 5秒 = 5000毫秒
            print('跳过时长少于5秒的文件: $filePath (时长: ${duration}ms)');
            continue; // 跳过当前文件
          }
          
          final song = Song(
            id: songs.length + 1,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            duration: duration, // 使用实际获取的时长
            uri: filePath,
            albumArtUri: null,
            dateAdded: dateAdded,
            isFavorite: false,
          );
          
          songs.add(song);
          print('添加歌曲: ${song.title} (${song.uri}) 时长: ${duration}ms');
        } catch (e) {
          print('处理文件时出错 $filePath: $e');
        }
      } else {
        // 显示一些非音频文件（用于调试路径结构）
        if (processed < 5) {
          print('非音频文件: $filePath');
        }
      }
      
      processed++;
      
      // 每处理100个文件更新一次进度
      if (processed % 100 == 0) {
        print('已处理 $processed/$totalFiles 个文件，匹配到 $matchedFiles 个音频文件');
      }
    }
    
    print('扫描完成: 处理了 $processed 个文件，找到 $matchedFiles 个音频文件');
    return songs;
  }

  @override
  void cancelScan() {
    print('扫描已被取消');
    _isCancelled = true;
  }

  @override
  Future<bool> requestPermissions() async {
    // 桌面端通常不需要特殊权限
    return true;
  }
  
  /// 获取平台相关的音乐目录
  Future<Directory> getMusicDirectory() async {
    print('=== 获取平台相关的音乐目录 ===');
    print('当前平台: ${Platform.operatingSystem}');
    print('平台版本: ${Platform.operatingSystemVersion}');
    
    if (Platform.isWindows) {
      // Windows: 通常在用户的"Music"文件夹中
      print('检测到 Windows 平台');
      final userprofile = Platform.environment['USERPROFILE'];
      print('USERPROFILE 环境变量: $userprofile');
      
      if (userprofile != null) {
        final musicPath = path.join(userprofile, 'Music');
        print('构建的音乐目录路径: $musicPath');
        
        final musicDir = Directory(musicPath);
        final exists = await musicDir.exists();
        print('音乐目录是否存在: $exists');
        
        if (exists) {
          print('返回标准音乐目录: $musicPath');
          return musicDir;
        } else {
          print('标准音乐目录不存在');
        }
      } else {
        print('USERPROFILE 环境变量为空');
      }
    } else if (Platform.isMacOS) {
      // macOS: 通常在用户的"Music"文件夹中
      print('检测到 macOS 平台');
      final home = Platform.environment['HOME'];
      print('HOME 环境变量: $home');
      
      if (home != null) {
        final musicPath = path.join(home, 'Music');
        print('构建的音乐目录路径: $musicPath');
        
        final musicDir = Directory(musicPath);
        final exists = await musicDir.exists();
        print('音乐目录是否存在: $exists');
        
        if (exists) {
          print('返回标准音乐目录: $musicPath');
          return musicDir;
        } else {
          print('标准音乐目录不存在');
        }
      } else {
        print('HOME 环境变量为空');
      }
    } else if (Platform.isLinux) {
      // Linux: 通常在用户的"Music"文件夹中
      print('检测到 Linux 平台');
      final home = Platform.environment['HOME'];
      print('HOME 环境变量: $home');
      
      if (home != null) {
        final musicPath = path.join(home, 'Music');
        print('构建的音乐目录路径: $musicPath');
        
        final musicDir = Directory(musicPath);
        final exists = await musicDir.exists();
        print('音乐目录是否存在: $exists');
        
        if (exists) {
          print('返回标准音乐目录: $musicPath');
          return musicDir;
        } else {
          print('标准音乐目录不存在');
        }
      } else {
        print('HOME 环境变量为空');
      }
    } else {
      print('未识别的平台: ${Platform.operatingSystem}');
    }
    
    print('尝试使用应用程序文档目录作为备选方案');
    // 默认使用应用程序文档目录
    final appDocDir = await getApplicationDocumentsDirectory();
    print('应用程序文档目录: ${appDocDir.path}');
    print('应用程序文档目录是否存在: ${await appDocDir.exists()}');
    return appDocDir;
  }
}

/// Web平台音乐扫描服务
class WebMusicScannerService implements PlatformMusicScannerService {
  @override
  Stream<music_scanner_service.ScanProgress> scanAllMusic() async* {
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.scanning,
      progress: 0,
      message: '开始扫描音乐',
      songs: <Song>[],
    );

    try {
      // Web端需要实现自己的音乐扫描逻辑
      // 由于浏览器安全限制，Web端可能无法直接扫描本地文件
      // 可以通过文件上传或IndexedDB等方式实现
      
      // 模拟扫描过程
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.scanning,
        progress: 50,
        message: '正在扫描音乐文件...',
        songs: <Song>[],
      );
      
      // 模拟扫描完成
      final songs = <Song>[];
      
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.completed,
        progress: 100,
        message: '扫描完成，共找到 ${songs.length} 首歌曲',
        songs: songs,
        totalSongs: songs.length,
      );
    } catch (e) {
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.error,
        progress: 0,
        message: '扫描过程中出现错误: $e',
        songs: <Song>[],
      );
    }
  }

  @override
  Stream<music_scanner_service.ScanProgress> scanMusicInFolder(String folderPath) async* {
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.error,
      progress: 0,
      message: 'Web端不支持扫描指定文件夹',
      songs: <Song>[],
    );
  }

  @override
  void cancelScan() {
    // Web端取消扫描逻辑
  }

  @override
  Future<bool> requestPermissions() async {
    // Web端权限处理
    return true;
  }
}

/// 创建平台相关的音乐扫描服务工厂
class PlatformMusicScannerServiceFactory {
  static PlatformMusicScannerService create() {
    if (Platform.isAndroid) {
      return AndroidMusicScannerService();
    } else if (Platform.isIOS) {
      return IOSMusicScannerService();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return DesktopMusicScannerService();
    } else {
      // Web或其他平台
      return WebMusicScannerService();
    }
  }
}