import 'package:get_it/get_it.dart';
import 'package:tune/core/services/platform_music_scanner_service.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_bloc.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source_impl.dart';
import 'package:tune/features/home/data/repositories/home_repository_impl.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';
import 'package:tune/features/home/domain/usecases/get_recently_played_songs.dart';
import 'package:tune/features/home/domain/usecases/get_recommended_songs.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';

/// 业务逻辑注册（与具体功能相关的业务逻辑）
class BusinessModule {
  /// 初始化业务模块
  static Future<void> init(GetIt getIt) async {
    // 注册数据源
    getIt.registerLazySingleton<HomeLocalDataSource>(() => HomeLocalDataSourceImpl());

    // 注册仓库
    getIt.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(localDataSource: getIt<HomeLocalDataSource>()));

    // 注册首页用例
    getIt.registerLazySingleton<GetRecentlyPlayedSongs>(() => GetRecentlyPlayedSongs(repository: getIt<HomeRepository>()));
    getIt.registerLazySingleton<GetRecommendedSongs>(() => GetRecommendedSongs(repository: getIt<HomeRepository>()));

    // 注册首页Bloc
    getIt.registerFactory<HomeBloc>(() => HomeBloc(
      getRecentlyPlayedSongs: getIt<GetRecentlyPlayedSongs>(), 
      getRecommendedSongs: getIt<GetRecommendedSongs>()
    ));
    
    // 注册平台相关的音乐扫描服务
    getIt.registerLazySingleton<PlatformMusicScannerService>(() => PlatformMusicScannerServiceFactory.create());
    
    // 注册音乐扫描Bloc
    getIt.registerFactory<MusicScanBloc>(() => MusicScanBloc(
      musicScannerService: getIt<PlatformMusicScannerService>()
    ));
  }
}