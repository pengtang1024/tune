import 'package:get_it/get_it.dart';
import 'package:tune/features/home/domain/usecases/get_recently_played_songs.dart';
import 'package:tune/features/home/domain/usecases/get_recommended_songs.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';

/// 业务逻辑注册（与具体功能相关的业务逻辑）
class BusinessModule {
  /// 初始化业务模块
  static Future<void> init(GetIt getIt) async {
    // 注册首页Bloc
    getIt.registerFactory<HomeBloc>(() => HomeBloc(
      getRecentlyPlayedSongs: getIt<GetRecentlyPlayedSongs>(), 
      getRecommendedSongs: getIt<GetRecommendedSongs>(),
    ));
  }
}