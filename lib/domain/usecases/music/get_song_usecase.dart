import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/music_repository.dart';

/// 获取单首歌曲用例
class GetSongUseCase {
  /// 音乐仓库
  final MusicRepository repository;

  /// 构造函数
  GetSongUseCase(this.repository);

  /// 执行用例
  Future<Song?> call(int songId) async {
    return await repository.getSongById(songId);
  }
}