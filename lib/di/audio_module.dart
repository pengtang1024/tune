import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tune/core/services/platform_music_scanner_service.dart';
import 'package:tune/data/datasources/audio_local_data_source.dart';
import 'package:tune/data/datasources/audio_remote_data_source.dart';
import 'package:tune/data/repositories/audio_repository_impl.dart';
import 'package:tune/data/services/media/audio_service.dart';
import 'package:tune/data/services/media/i_audio_service.dart';
import 'package:tune/domain/repositories/audio_repository.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/domain/usecases/play_audio.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/features/audio/presentation/bloc/music_scan/music_scan_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';

/// 音频模块注册
class AudioModule {
  /// 初始化音频模块
  static Future<void> init(GetIt getIt) async {
    // 注册AudioPlayer
    getIt.registerLazySingleton<AudioPlayer>(() => AudioPlayer());

    // 注册数据源
    getIt.registerLazySingleton<AudioLocalDataSource>(
      () => AudioLocalDataSourceImpl(),
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
    getIt.registerLazySingleton<IAudioService>(
      () => AudioService(
        audioPlayer: getIt<AudioPlayer>(),
      ),
    );

    // 注册Bloc
    getIt.registerFactory<PlayerBloc>(
      () => PlayerBloc(
        audioService: getIt<IAudioService>(),
        getAllSongs: getIt<GetAllSongs>(),
      ),
    );
    
    // 注册音乐扫描Bloc
    getIt.registerFactory<MusicScanBloc>(
      () => MusicScanBloc(
        musicScannerService: getIt<PlatformMusicScannerService>(),
      ),
    );
  }
}