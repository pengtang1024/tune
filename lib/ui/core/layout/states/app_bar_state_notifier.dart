import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/states/app_bar_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/l10n/app_localizations.dart';

/// AppBar模块状态管理器
/// 负责全局标题栏状态的管理与更新
class AppBarStateNotifier extends StateNotifier<AppBarState> {
  AppBarStateNotifier() : super(AppBarState.initial()) {
    _loadPreferences();
    _initSupportedLocales();
    _initUserInfo();
  }

  /// 初始化支持的语言列表
  void _initSupportedLocales() {
    state = state.copyWith(
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  /// 初始化用户信息
  void _initUserInfo() {
    // 设置默认用户信息
    state = state.copyWith(
      username: 'Tune User',
      userLevel: 5,
      userTags: const ['vip', '听众', '精英'],
    );
  }

  /// 加载用户偏好设置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载主题模式
    final themeModeIndex = prefs.getInt('theme_mode');
    final themeMode = themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeModeIndex]
        : ThemeMode.system;
    
    // 加载语言设置
    final languageCode = prefs.getString('language_code') ?? 'zh';
    final countryCode = prefs.getString('country_code');
    final locale = countryCode != null 
        ? Locale(languageCode, countryCode) 
        : Locale(languageCode);
    
    state = state.copyWith(
      themeMode: themeMode,
      locale: locale,
    );
  }
  
  /// 保存主题模式
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', themeMode.index);
  }
  
  /// 保存语言设置
  Future<void> _saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('country_code', locale.countryCode!);
    } else {
      await prefs.remove('country_code');
    }
  }

  /// 更新标题
  void updateTitle(String title) {
    if (state.title != title) {
      state = state.copyWith(title: title);
    }
  }

  /// 切换返回按钮显示状态
  void toggleBackButton(bool show) {
    if (state.showBackButton != show) {
      state = state.copyWith(showBackButton: show);
    }
  }

  /// 同时更新标题和返回按钮状态
  void updateAppBar(String title, bool showBackButton) {
    // 只有当状态真正改变时才更新
    if (state.title != title || state.showBackButton != showBackButton) {
      state = state.copyWith(
        title: title,
        showBackButton: showBackButton,
      );
    }
  }

  /// 添加动态按钮（从右到左添加，插入到列表开头）
  void addDynamicAction(Widget action) {
    final updatedActions = List<Widget>.from(state.dynamicActions)
      ..insert(0, action); // 从右到左添加，插入到列表开头
    state = state.copyWith(dynamicActions: updatedActions);
  }

  /// 移除所有动态按钮
  void clearDynamicActions() {
    if (state.dynamicActions.isNotEmpty) {
      state = state.copyWith(dynamicActions: const []);
    }
  }
  
  /// 循环切换主题模式（浅色->深色->随系统->浅色）
  void toggleThemeMode() {
    ThemeMode newThemeMode;
    switch (state.themeMode) {
      case ThemeMode.light:
        newThemeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newThemeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newThemeMode = ThemeMode.light;
        break;
    }
    
    state = state.copyWith(themeMode: newThemeMode);
    _saveThemeMode(newThemeMode);
  }
  
  /// 设置主题模式（支持浅色、深色、自动三种模式）
  void setThemeMode(ThemeMode themeMode) {
    if (state.themeMode != themeMode) {
      state = state.copyWith(themeMode: themeMode);
      _saveThemeMode(themeMode);
    }
  }
  
  /// 切换语言
  void switchLanguage(Locale locale) {
    if (state.locale != locale) {
      state = state.copyWith(locale: locale);
      _saveLanguage(locale);
    }
  }
  
  /// 切换"我的"下拉框显示状态
  void toggleMyDropdown() {
    state = state.copyWith(showMyDropdown: !state.showMyDropdown);
  }
  
  /// 设置"我的"下拉框显示状态
  void setShowMyDropdown(bool show) {
    if (state.showMyDropdown != show) {
      state = state.copyWith(showMyDropdown: show);
    }
  }
  
  /// 切换语言选择框显示状态
  void toggleLanguageDropdown() {
    state = state.copyWith(showLanguageDropdown: !state.showLanguageDropdown);
  }
  
  /// 设置语言选择框显示状态
  void setShowLanguageDropdown(bool show) {
    if (state.showLanguageDropdown != show) {
      state = state.copyWith(showLanguageDropdown: show);
    }
  }
  
  /// 处理路由变化
  void handleRouteChange(String route, {String? title, bool? showBackButton}) {
    // 检查路由是否发生变化
    if (state.currentRoute != route) {
      state = state.copyWith(currentRoute: route);
    }
    
    // 如果提供了标题或返回按钮状态，则更新它们
    if (title != null || showBackButton != null) {
      state = state.copyWith(
        title: title ?? state.title,
        showBackButton: showBackButton ?? state.showBackButton,
      );
    }
  }
  
  /// 更新用户信息
  void updateUserInfo({
    String? avatarUrl,
    String? username,
    int? level,
    List<String>? tags,
  }) {
    state = state.copyWith(
      userAvatarUrl: avatarUrl,
      username: username,
      userLevel: level,
      userTags: tags,
    );
  }
  
  /// 设置播放按钮悬停状态
  void setPlayButtonHover(bool isHovered) {
    if (state.isPlayButtonHovered != isHovered) {
      state = state.copyWith(isPlayButtonHovered: isHovered);
    }
  }
  
  /// 加载用户信息（模拟方法，实际项目中应从网络或本地存储加载）
  Future<void> loadUserInfo() async {
    // 模拟异步加载用户信息
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 设置默认用户信息
    state = state.copyWith(
      username: 'Tune User',
      userLevel: 5,
      userTags: const ['vip', '听众', '精英'],
    );
  }
}