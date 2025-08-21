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
        sampleRate = data['sampleRate'];

  // Getters for compatibility with existing code
  String get displayName => title;
  int get durationInMillis => duration;
  String get data => uri;
}