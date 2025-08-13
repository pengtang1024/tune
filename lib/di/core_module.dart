import 'package:get_it/get_it.dart';
import 'package:tune/core/bloc/localization/localization_bloc.dart';
import 'package:tune/core/bloc/theme/theme_bloc.dart';
import 'package:tune/core/services/search_history_service.dart';
import 'package:tune/core/storage/local/local_storage_impl.dart';
import 'package:tune/core/storage/storage.dart' as storage;

/// 核心模块注册
class CoreModule {
  /// 注册核心服务
  static Future<void> init(GetIt getIt) async {
    // 注册本地存储服务
    final localStorage = LocalStorageImpl();
    getIt.registerSingleton<storage.Storage>(localStorage);
    getIt.registerSingleton<LocalStorageImpl>(localStorage);

    // 初始化本地存储
    localStorage.init();

    // 注册搜索历史服务
    getIt.registerSingleton(SearchHistoryService(localStorage));
    
    // 注册核心 BLoCs
    getIt.registerLazySingleton<ThemeBloc>(() => ThemeBloc());
    getIt.registerLazySingleton<LocalizationBloc>(() => LocalizationBloc());
  }
}