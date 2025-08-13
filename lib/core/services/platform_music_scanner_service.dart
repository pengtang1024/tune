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
  final List<String> _commonMusicPaths = [
    // Windows
    if (Platform.isWindows) 
      path.join(Platform.environment['USERPROFILE'] ?? '', 'Music'),
    
    // macOS
    if (Platform.isMacOS) 
      path.join(Platform.environment['HOME'] ?? '', 'Music'),
    
    // Linux
    if (Platform.isLinux) 
      path.join(Platform.environment['HOME'] ?? '', 'Music'),
      
    // 通用
    path.join(Platform.environment['HOME'] ?? '', 'Music'),
  ];

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
    
    print('=== 开始扫描所有音乐 ===');
    yield music_scanner_service.ScanProgress(
      status: music_scanner_service.ScanStatus.idle,
      progress: 0,
      message: '开始扫描音乐',
      songs: <Song>[],
    );

    try {
      // 获取标准音乐目录
      Directory? musicDir;
      print('尝试获取标准音乐目录...');
      try {
        musicDir = await getMusicDirectory();
        print('获取到标准音乐目录: ${musicDir.path}');
        print('目录是否存在: ${await musicDir.exists()}');
      } catch (e) {
        print('获取标准音乐目录时出错: $e');
        // 如果无法获取标准音乐目录，则使用常见路径
        print('尝试使用常见音乐路径...');
        for (int i = 0; i < _commonMusicPaths.length; i++) {
          final musicPath = _commonMusicPaths[i];
          print('检查路径 [$i]: $musicPath');
          final dir = Directory(musicPath);
          if (await dir.exists()) {
            print('找到存在的音乐目录: $musicPath');
            musicDir = dir;
            break;
          } else {
            print('路径不存在: $musicPath');
          }
        }
      }
      
      if (musicDir == null) {
        // 尝试使用常见路径
        print('musicDir为null，尝试使用常见音乐路径...');
        for (int i = 0; i < _commonMusicPaths.length; i++) {
          final musicPath = _commonMusicPaths[i];
          print('检查路径 [$i]: $musicPath');
          final dir = Directory(musicPath);
          if (await dir.exists()) {
            print('找到存在的音乐目录: $musicPath');
            musicDir = dir;
            break;
          } else {
            print('路径不存在: $musicPath');
          }
        }
      }
      
      // 如果仍然没有找到音乐目录，则使用应用程序文档目录
      if (musicDir == null) {
        print('未找到音乐目录，使用应用程序文档目录');
        musicDir = await getApplicationDocumentsDirectory();
      }
      
      // 确保目录存在，如果不存在则创建它
      if (!(await musicDir.exists())) {
        print('目录不存在，正在创建: ${musicDir.path}');
        await musicDir.create(recursive: true);
      }
      
      print('准备扫描目录: ${musicDir.path}');
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.scanning,
        progress: 10,
        message: '正在扫描目录: ${musicDir.path}',
        songs: <Song>[],
      );
      
      // 扫描音乐文件
      print('开始扫描音乐文件...');
      final songs = await _scanDirectory(musicDir);
      print('扫描完成，找到 ${songs.length} 首歌曲');
      
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
      
      final successMsg = '扫描成功完成，共找到 ${songs.length} 首歌曲';
      print(successMsg);
      yield music_scanner_service.ScanProgress(
        status: music_scanner_service.ScanStatus.completed,
        progress: 100,
        message: successMsg,
        songs: songs,
        totalSongs: songs.length,
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
    
    print('=== 扫描所有音乐过程结束 ===');
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
      
      for (int i = 0; i < folderPaths.length; i++) {
        if (_isCancelled) break;
        
        final folderPath = folderPaths[i];
        final progress = ((i / folderPaths.length) * 100).toInt();
        yield music_scanner_service.ScanProgress(
          status: music_scanner_service.ScanStatus.scanning,
          progress: progress,
          message: '正在扫描文件夹 ($i/${folderPaths.length}): $folderPath',
          songs: allSongs,
        );
        
        final folder = Directory(folderPath);
        print('检查文件夹是否存在...');
        final folderExists = await folder.exists();
        print('文件夹存在状态: $folderExists');
        
        if (!folderExists) {
          print('指定的文件夹不存在: $folderPath');
          continue;
        }
        
        print('准备扫描文件夹中的音乐文件...');
        // 扫描音乐文件
        final songs = await _scanDirectory(folder);
        allSongs.addAll(songs);
        print('文件夹扫描完成，找到 ${songs.length} 首歌曲');
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
      '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma', '.aiff', '.aif', '.ape', '.wv'
    };
  }
  
  /// 扫描目录中的所有音频文件
  Future<List<Song>> _scanDirectory(Directory directory) async {
    final songs = <Song>[];
    final audioExtensions = _getAudioExtensions();
    
    try {
      print('开始扫描目录: ${directory.path}');
      print('目录可访问');
    } catch (e) {
      print('错误: 无法访问目录，可能是权限问题: $e');
      return songs;
    }
    
    // 获取目录中的所有文件
    print('正在列出目录中的所有文件（递归）...');
    final entities = await directory.list(recursive: true).toList();
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
        print('处理文件 ($processed): $filePath');
      }
      
      if (audioExtensions.contains(fileExtension)) {
        print('发现音频文件: $filePath');
        matchedFiles++;
        
        try {
          final fileName = path.basenameWithoutExtension(filePath);
          final stat = await file.stat();
          
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
            print('获取音频元数据失败: $e');
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
            dateAdded: stat.changed.millisecondsSinceEpoch,
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
        print('已处理 $processed 个文件，匹配到 $matchedFiles 个音频文件');
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