import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/music_service.dart';
import 'package:tune/domain/models/song.dart';

/// 平台音乐服务实现
class PlatformMusicService implements MusicService {
  late final CrossPlatformMusicScanner _crossPlatformScanner;

  PlatformMusicService() {
    _crossPlatformScanner = CrossPlatformMusicScannerImpl();
  }

  /// 获取所有歌曲
  @override
  Future<List<Song>> getAllSongs() async {
    // 在 Web 平台上返回空列表
    if (kIsWeb) {
      return [];
    }

    // 在桌面平台上使用跨平台扫描器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await _crossPlatformScanner.getAllSongs();
    }

    // 在移动平台上返回空列表
    return [];
  }

  /// 扫描音乐
  @override
  Future<List<Song>> scanMusic() async {
    // 在 Web 平台上返回空列表
    if (kIsWeb) {
      return [];
    }

    // 在桌面平台上使用跨平台扫描器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await _crossPlatformScanner.scanMusic();
    }

    // 在移动平台上返回空列表
    return [];
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    // 在 Web 平台上返回空列表
    if (kIsWeb) {
      return [];
    }

    // 在桌面平台上使用跨平台扫描器
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await _crossPlatformScanner.searchSongs(query);
    }

    // 在移动平台上返回空列表
    return [];
  }
}