import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Song>> getRecentlyPlayedSongs() async {
    try {
      return await localDataSource.getRecentlyPlayedSongs();
    } catch (e) {
      // 出错时返回空列表而不是抛出异常
      return [];
    }
  }

  @override
  Future<List<Song>> getRecommendedSongs() async {
    try {
      return await localDataSource.getRecommendedSongs();
    } catch (e) {
      // 出错时返回空列表而不是抛出异常
      return [];
    }
  }

  @override
  Future<void> saveRecentlyPlayedSong(Song song) async {
    try {
      await localDataSource.saveRecentlyPlayedSong(song);
    } catch (e) {
      // 静默处理保存错误
    }
  }
}