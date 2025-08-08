import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tune/core/utils/localization_service.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = 
      _AppLocalizationsDelegate();

  String? translate(String key) {
    return LocalizationService().translate(key);
  }

  // 应用名称
  String get appName => translate('app_name') ?? 'Tune';
  
  // 页面标题
  String get homeTitle => translate('home_title') ?? 'Home';
  String get libraryTitle => translate('library_title') ?? 'Library';
  String get searchTitle => translate('search_title') ?? 'Search';
  String get settingsTitle => translate('settings_title') ?? 'Settings';
  
  // 按钮文本
  String get playButton => translate('play_button') ?? 'Play';
  String get pauseButton => translate('pause_button') ?? 'Pause';
  String get nextButton => translate('next_button') ?? 'Next';
  String get previousButton => translate('previous_button') ?? 'Previous';
  String get favoriteButton => translate('favorite_button') ?? 'Favorite';
  
  // 主题
  String get themeLight => translate('theme_light') ?? 'Light';
  String get themeDark => translate('theme_dark') ?? 'Dark';
  String get themeSystem => translate('theme_system') ?? 'System';
  
  // 底部播放栏
  String get bottomPlayerBarNowPlaying => translate('bottom_player_bar_now_playing') ?? 'Now Playing';
  String get bottomPlayerBarNoSong => translate('bottom_playerBar_no_song') ?? 'No song selected';
  
  // 歌曲列表
  String get songListTitle => translate('song_list_title') ?? 'Songs';
  String get songListNoSongs => translate('song_list_no_songs') ?? 'No songs found';
  
  // 设置页面
  String get settingsPageLanguage => translate('settings_page_language') ?? 'Language';
  String get settingsPageTheme => translate('settings_page_theme') ?? 'Theme';
  String get settingsPageAbout => translate('settings_page_about') ?? 'About';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocalizationService().getSupportedLocales().contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}