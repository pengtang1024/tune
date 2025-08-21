import 'dart:io' show File;
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration; // 以毫秒为单位
  final String uri;
  final int dateAdded;
  final String? genre;
  final int? year;
  final int? bitrate; // 比特率 (kbps)
  final int? sampleRate; // 采样率 (Hz)
  final int? trackNumber; // 音轨号
  final int? trackTotal; // 总音轨数
  final int? discNumber; // 光盘号
  final int? totalDisc; // 总光盘数
  final String? lyrics; // 歌词
  final List<String>? genres; // 流派列表
  final List<String>? performers; // 表演者列表
  final String? language; // 语言
  final int? size; // 文件大小（字节）
  final String? type; // 文件类型
  final bool isFavorite; // 是否收藏

  Song(Map<String, dynamic> data)
      : id = data['id'] ?? 0,
        title = data['title'] ?? '',
        artist = data['artist'] ?? '',
        album = data['album'] ?? '',
        duration = data['duration'] ?? 0,
        uri = data['uri'] ?? '',
        dateAdded = data['dateAdded'] ?? 0,
        genre = data['genre'],
        year = data['year'],
        bitrate = data['bitrate'],
        sampleRate = data['sampleRate'],
        trackNumber = data['trackNumber'],
        trackTotal = data['trackTotal'],
        discNumber = data['discNumber'],
        totalDisc = data['totalDisc'],
        lyrics = data['lyrics'],
        genres = data['genres'] is List ? List<String>.from(data['genres']) : null,
        performers = data['performers'] is List ? List<String>.from(data['performers']) : null,
        language = data['language'],
        size = data['size'],
        type = data['type'],
        isFavorite = data['isFavorite'] ?? false;

  // Getters for compatibility with existing code
  String get displayName => title;
  int get durationInMillis => duration;
  String get data => uri;
}