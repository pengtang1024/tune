import 'package:on_audio_query/on_audio_query.dart';

class Song extends SongModel {
  Song(super._info);

  // 只重写需要修改的属性
  @override
  int get duration => super.duration ?? 0;

  // 添加fromJson方法
  factory Song.fromJson(Map<String, dynamic> json) {
    // 使用on_audio_query的fromMap构造函数
    return Song(json);
  }

  // 添加toJson方法
  Map<String, dynamic> toJson() {
    final map = getMap;
    // 确保返回类型为Map<String, dynamic>
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
}