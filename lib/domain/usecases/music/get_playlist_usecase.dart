import 'package:tune/domain/entities/playlist.dart';
import 'package:tune/domain/repositories/music_repository.dart';

/// 获取歌单用例
class GetPlaylistUseCase {
  /// 音乐仓库
  final MusicRepository repository;

  /// 构造函数
  GetPlaylistUseCase(this.repository);

  /// 执行用例
  Future<Playlist?> call(int playlistId) async {
    return await repository.getPlaylistById(playlistId);
  }
}