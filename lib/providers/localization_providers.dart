import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/l10n/app_localizations.dart';

/// 本地化服务提供者
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  final persistenceService = ref.watch(sharedPreferencesServiceProvider);
  return LocalizationService(persistenceService: persistenceService);
});

/// 当前语言环境状态提供者
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final localizationService = ref.watch(localizationServiceProvider);
  return LocaleNotifier(localizationService);
});

/// 本地化服务类
class LocalizationService {
  final PersistenceService _persistenceService;

  LocalizationService({required PersistenceService persistenceService})
      : _persistenceService = persistenceService;

  /// 保存语言环境
  Future<void> saveLocale(Locale locale) async {
    await _persistenceService.setString('selected_locale', locale.languageCode);
  }

  /// 获取保存的语言环境
  Locale getLocale() {
    final localeString = _persistenceService.getString('selected_locale');
    if (localeString != null) {
      // 支持的语言列表
      final supportedLocales = AppLocalizations.supportedLocales;
      for (final locale in supportedLocales) {
        if (locale.languageCode == localeString) {
          return locale;
        }
      }
    }
    
    // 返回默认语言环境
    return const Locale('en');
  }
}

/// 语言环境状态管理器
class LocaleNotifier extends StateNotifier<Locale> {
  final LocalizationService _localizationService;

  LocaleNotifier(this._localizationService) : super(const Locale('en')) {
    // 初始化时从持久化存储中加载语言环境
    state = _localizationService.getLocale();
  }

  /// 更新语言环境
  Future<void> updateLocale(Locale? locale) async {
    if (locale == null) return;
    
    state = locale;
    await _localizationService.saveLocale(locale);
  }
}