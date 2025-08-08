import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _selectedLocaleKey = 'selected_locale';

  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  late SharedPreferences _prefs;
  final Map<String, Map<String, String>> _loadedLanguagePacks = {};
  String? _currentLocale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 加载内置语言包
    await _loadBuiltInLanguagePacks();
    
    // 获取当前选择的语言
    _currentLocale = _prefs.getString(_selectedLocaleKey);
  }

  Future<void> _loadBuiltInLanguagePacks() async {
    try {
      // 加载英语语言包
      final enStrings = await rootBundle.loadString('lib/l10n/app_en.arb');
      final enMap = Map<String, String>.from(json.decode(enStrings) as Map);
      _loadedLanguagePacks['en'] = enMap;

      // 加载中文语言包
      final zhStrings = await rootBundle.loadString('lib/l10n/app_zh.arb');
      final zhMap = Map<String, String>.from(json.decode(zhStrings) as Map);
      _loadedLanguagePacks['zh'] = zhMap;
    } catch (e) {
      // 如果语言包文件不存在，则使用默认值
      _loadedLanguagePacks['en'] = {
        'app_name': 'Tune',
        'home_title': 'Home',
        'library_title': 'Library',
        'search_title': 'Search',
        'settings_title': 'Settings',
        'play_button': 'Play',
        'pause_button': 'Pause',
        'next_button': 'Next',
        'previous_button': 'Previous',
        'favorite_button': 'Favorite',
        'theme_light': 'Light',
        'theme_dark': 'Dark',
        'theme_system': 'System',
        'bottom_player_bar_now_playing': 'Now Playing',
        'bottom_player_bar_no_song': 'No song selected',
        'song_list_title': 'Songs',
        'song_list_no_songs': 'No songs found',
        'player_page_duration': 'Duration',
        'player_page_artist': 'Artist',
        'player_page_album': 'Album',
        'search_page_hint': 'Search songs...',
        'search_page_empty': 'Enter a search term to find songs',
        'search_page_no_results': 'No songs found matching your search',
        'settings_page_language': 'Language',
        'settings_page_theme': 'Theme',
        'settings_page_about': 'About',
        'library_page_artists': 'Artists',
        'library_page_albums': 'Albums',
        'library_page_genres': 'Genres'
      };

      _loadedLanguagePacks['zh'] = {
        'app_name': 'Tune',
        'home_title': '首页',
        'library_title': '音乐库',
        'search_title': '搜索',
        'settings_title': '设置',
        'play_button': '播放',
        'pause_button': '暂停',
        'next_button': '下一首',
        'previous_button': '上一首',
        'favorite_button': '收藏',
        'theme_light': '浅色',
        'theme_dark': '深色',
        'theme_system': '系统',
        'bottom_player_bar_now_playing': '正在播放',
        'bottom_player_bar_no_song': '未选择歌曲',
        'song_list_title': '歌曲列表',
        'song_list_no_songs': '未找到歌曲',
        'player_page_duration': '时长',
        'player_page_artist': '艺术家',
        'player_page_album': '专辑',
        'search_page_hint': '搜索歌曲...',
        'search_page_empty': '输入搜索词来查找歌曲',
        'search_page_no_results': '未找到匹配的歌曲',
        'settings_page_language': '语言',
        'settings_page_theme': '主题',
        'settings_page_about': '关于',
        'library_page_artists': '艺术家',
        'library_page_albums': '专辑',
        'library_page_genres': '流派'
      };
    }
  }

  String? translate(String key) {
    if (_currentLocale == null) return null;
    
    final pack = _loadedLanguagePacks[_currentLocale!];
    if (pack == null) return null;
    
    return pack[key];
  }

  List<String> getSupportedLocales() {
    return _loadedLanguagePacks.keys.toList();
  }

  String getCurrentLocale() {
    return _currentLocale ?? 'en';
  }

  Future<void> setLocale(String locale) async {
    _currentLocale = locale;
    await _prefs.setString(_selectedLocaleKey, locale);
  }
}