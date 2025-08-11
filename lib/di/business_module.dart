import 'package:get_it/get_it.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source.dart';
import 'package:tune/features/home/data/datasources/home_local_data_source_impl.dart';
import 'package:tune/features/home/data/repositories/home_repository_impl.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';
import 'package:tune/features/home/domain/usecases/get_recently_played_songs.dart';
import 'package:tune/features/home/domain/usecases/get_recommended_songs.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';

/// 业务模块注册
class BusinessModule {
  /// 初始化业务模块
  static Future<void> init(GetIt getIt) async {
    // 注册数据源
    getIt.registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(),
    );

    // 注册仓库
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        localDataSource: getIt<HomeLocalDataSource>(),
      ),
    );

    // 注册首页用例
    getIt.registerLazySingleton<GetRecentlyPlayedSongs>(
      () => GetRecentlyPlayedSongs(repository: getIt<HomeRepository>()),
    );
    getIt.registerLazySingleton<GetRecommendedSongs>(
      () => GetRecommendedSongs(repository: getIt<HomeRepository>()),
    );

    // 注册首页Bloc
    getIt.registerFactory<HomeBloc>(
      () => HomeBloc(
        getRecentlyPlayedSongs: getIt<GetRecentlyPlayedSongs>(),
        getRecommendedSongs: getIt<GetRecommendedSongs>(),
      ),
    );
  }
}