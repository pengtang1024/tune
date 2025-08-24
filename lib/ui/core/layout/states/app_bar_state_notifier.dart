import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/core/layout/states/app_bar_state.dart';

/// AppBar模块状态管理器
/// 负责全局标题栏状态的管理与更新
class AppBarStateNotifier extends StateNotifier<AppBarState> {
  final Ref ref;

  AppBarStateNotifier(this.ref) : super(AppBarState.initial()) {
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
    final sharedPrefs = ref.read(sharedPreferencesServiceProvider);

    // 加载主题模式
    final themeModeIndex = sharedPrefs.getInt('theme_mode');
    final themeMode = themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length
        ? ThemeMode.values[themeModeIndex]
        : ThemeMode.system;

    Locale locale;
    final languageCode = sharedPrefs.getString('language_code');
    final countryCode = sharedPrefs.getString('country_code');

    if (languageCode != null) {
      // 如果有保存的语言设置，则使用保存的设置
      try {
        locale = AppLocalizations.supportedLocales.firstWhere(
          (supportedLocale) => supportedLocale.languageCode == languageCode &&
                              (countryCode == null || supportedLocale.countryCode == countryCode),
        );
      } catch (e) {
        // 如果找不到匹配的语言环境，则使用默认语言环境
        locale = AppLocalizations.supportedLocales.first;
      }
    } else {
      // 如果没有保存的语言设置，则根据系统语言设置默认语言
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      try {
        // 尝试匹配系统语言
        locale = AppLocalizations.supportedLocales.firstWhere(
          (supportedLocale) => supportedLocale.languageCode == systemLocale.languageCode &&
                              (supportedLocale.countryCode == null || supportedLocale.countryCode == systemLocale.countryCode),
        );
      } catch (e) {
        // 如果系统语言不支持，则使用英语作为默认语言
        locale = const Locale('en');
      }
    }

    state = state.copyWith(
      themeMode: themeMode,
      locale: locale,
    );
  }

  /// 保存主题模式
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final sharedPrefs = ref.read(sharedPreferencesServiceProvider);
    await sharedPrefs.setInt('theme_mode', themeMode.index);
  }

  /// 保存语言设置
  Future<void> _saveLanguage(Locale locale) async {
    final sharedPrefs= ref.read(sharedPreferencesServiceProvider);
    await sharedPrefs.setString('language_code', locale.languageCode);
    if (locale.countryCode != null) {
      await sharedPrefs.setString('country_code', locale.countryCode!);
    } else {
      await sharedPrefs.remove('country_code');
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
    updateThemeMode(newThemeMode);
  }

  /// 设置主题模式（支持浅色、深色、自动三种模式）
  ///
  /// @param themeMode 要设置的主题模式，包括亮色、暗色等选项
  void setThemeMode(ThemeMode themeMode) {
    updateThemeMode(themeMode);
  }

  /// 切换语言
  void switchLanguage(Locale locale) {
    updateLocale(locale);
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

  /// 更新语言环境
  void updateLocale(Locale locale) {
    if (state.locale != locale) {
      state = state.copyWith(locale: locale);
      _saveLanguage(locale);
    }
  }

  /// 更新主题模式
  void updateThemeMode(ThemeMode themeMode) {
    if (state.themeMode != themeMode) {
      state = state.copyWith(themeMode: themeMode);
      _saveThemeMode(themeMode);
    }
  }
}