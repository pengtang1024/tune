import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _selectedLocaleKey = 'selected_locale';

  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  late SharedPreferences _prefs;
  late Box<Map> _languagePacksBox;

  final Map<String, Map<String, String>> _loadedLanguagePacks = {};
  String? _currentLocale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _languagePacksBox = await Hive.openBox<Map>('language_packs');
    
    // 加载内置语言包
    await _loadBuiltInLanguagePacks();
    
    // 加载自定义语言包
    await _loadCustomLanguagePacks();
    
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
      };
    }
  }

  Future<void> _loadCustomLanguagePacks() async {
    // 从Hive加载自定义语言包
    for (var key in _languagePacksBox.keys) {
      final pack = _languagePacksBox.get(key);
      if (pack != null) {
        _loadedLanguagePacks[key.toString()] = 
            Map<String, String>.from(pack);
      }
    }
  }

  String? translate(String key) {
    if (_currentLocale == null) return null;
    
    final pack = _loadedLanguagePacks[_currentLocale];
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

  Future<void> addLanguagePack(String locale, Map<String, String> translations) async {
    // 保存到Hive
    await _languagePacksBox.put(locale, translations);
    
    // 更新内存中的语言包
    _loadedLanguagePacks[locale] = translations;
  }

  Future<void> removeLanguagePack(String locale) async {
    // 不能删除内置语言包
    if (locale == 'en' || locale == 'zh') return;
    
    // 从Hive删除
    await _languagePacksBox.delete(locale);
    
    // 从内存中删除
    _loadedLanguagePacks.remove(locale);
    
    // 如果删除的是当前语言，则切换回默认语言
    if (_currentLocale == locale) {
      await setLocale('en');
    }
  }

  Future<void> updateLanguagePack(String locale, Map<String, String> translations) async {
    await addLanguagePack(locale, translations);
  }
}