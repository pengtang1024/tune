import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:tune/data/datasources/audio_local_data_source.dart';
import 'package:tune/data/datasources/audio_remote_data_source.dart';
import 'package:tune/data/repositories/audio_repository_impl.dart';
import 'package:tune/domain/repositories/audio_repository.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/domain/usecases/play_audio.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/core/services/audio_service.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';

final getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init() async {
    // 注册AudioPlayer
    getIt.registerLazySingleton<AudioPlayer>(() => AudioPlayer());
    
    // 注册OnAudioQuery
    getIt.registerLazySingleton<OnAudioQuery>(() => OnAudioQuery());
    
    // 注册数据源
    getIt.registerLazySingleton<AudioLocalDataSource>(
      () => AudioLocalDataSourceImpl(getIt<OnAudioQuery>()),
    );
    
    getIt.registerLazySingleton<AudioRemoteDataSource>(
      () => AudioRemoteDataSourceImpl(),
    );
    
    // 注册仓库
    getIt.registerLazySingleton<AudioRepository>(
      () => AudioRepositoryImpl(
        getIt<AudioLocalDataSource>(),
        getIt<AudioRemoteDataSource>(),
      ),
    );
    
    // 注册用例
    getIt.registerLazySingleton<GetAllSongs>(
      () => GetAllSongs(getIt<AudioRepository>()),
    );
    
    getIt.registerLazySingleton<PlayAudio>(
      () => PlayAudio(getIt<AudioRepository>()),
    );
    
    getIt.registerLazySingleton<SearchSongs>(
      () => SearchSongs(getIt<AudioRepository>()),
    );
    
    // 注册服务
    getIt.registerLazySingleton<AudioService>(
      () => AudioService(),
    );
    
    // Player Bloc
    getIt.registerFactory(
      () => PlayerBloc(
        audioService: getIt<AudioService>(),
        getAllSongs: getIt<GetAllSongs>(),
      ),
    );
  }
  
  // 获取实例的便捷方法
  static T get<T extends Object>() => getIt<T>();
  
  // 获取AudioPlayer实例
  AudioPlayer get audioPlayer => getIt<AudioPlayer>();
  
  // 获取PlayerBloc实例
  PlayerBloc getPlayerBloc() => PlayerBloc(
        audioService: getIt<AudioService>(),
        getAllSongs: getIt<GetAllSongs>(),
      );
}