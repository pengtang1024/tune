import 'package:get_it/get_it.dart';
import 'package:tune/data/datasources/audio_local_data_source.dart';
import 'package:tune/data/datasources/audio_remote_data_source.dart';
import 'package:tune/data/repositories/audio_repository_impl.dart';
import 'package:tune/domain/repositories/audio_repository.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/domain/usecases/play_audio.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source_impl.dart';
import 'package:tune/features/home/data/repositories/home_repository_impl.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';
import 'package:tune/features/home/domain/usecases/get_recently_played_songs.dart';
import 'package:tune/features/home/domain/usecases/get_recommended_songs.dart';

/// 数据层服务注册
class DataModule {
  /// 初始化数据模块
  static Future<void> init(GetIt getIt) async {
    // 注册数据源
    getIt.registerLazySingleton<AudioLocalDataSource>(() => AudioLocalDataSourceImpl());
    getIt.registerLazySingleton<AudioRemoteDataSource>(() => AudioRemoteDataSourceImpl());
    getIt.registerLazySingleton<HomeLocalDataSource>(() => HomeLocalDataSourceImpl());

    // 注册仓库
    getIt.registerLazySingleton<AudioRepository>(() => AudioRepositoryImpl(
      getIt<AudioLocalDataSource>(),
      getIt<AudioRemoteDataSource>(),
    ));
    getIt.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(
      localDataSource: getIt<HomeLocalDataSource>(),
    ));

    // 注册用例
    getIt.registerLazySingleton<GetAllSongs>(() => GetAllSongs(getIt<AudioRepository>()));
    getIt.registerLazySingleton<PlayAudio>(() => PlayAudio(getIt<AudioRepository>()));
    getIt.registerLazySingleton<SearchSongs>(() => SearchSongs(getIt<AudioRepository>()));
    getIt.registerLazySingleton<GetRecentlyPlayedSongs>(() => GetRecentlyPlayedSongs(repository: getIt<HomeRepository>()));
    getIt.registerLazySingleton<GetRecommendedSongs>(() => GetRecommendedSongs(repository: getIt<HomeRepository>()));
  }
}