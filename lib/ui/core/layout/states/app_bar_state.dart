import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppBar状态数据模型
/// 不可变状态设计，仅包含标题栏状态数据
class AppBarState {
  /// 标题文本
  final String title;
  
  /// 返回按钮显示状态
  final bool showBackButton;
  
  /// 动态按钮列表（按添加顺序存储）
  final List<Widget> dynamicActions;
  
  /// 当前主题模式
  final ThemeMode themeMode;
  
  /// 当前语言代码
  final Locale locale;
  
  /// "我的"下拉框显示状态
  final bool showMyDropdown;
  
  /// 本地化语言选择框显示状态
  final bool showLanguageDropdown;
  
  /// 当前路由路径
  final String currentRoute;
  
  /// 用户头像URL
  final String? userAvatarUrl;
  
  /// 用户名
  final String? username;
  
  /// 用户等级
  final int? userLevel;
  
  /// 用户标签列表
  final List<String> userTags;
  
  /// 支持的语言列表
  final List<Locale> supportedLocales;
  
  /// 播放按钮悬停状态
  final bool isPlayButtonHovered;

  AppBarState({
    required this.title,
    required this.showBackButton,
    this.dynamicActions = const [],
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('zh', 'CN'),
    this.showMyDropdown = false,
    this.showLanguageDropdown = false,
    this.currentRoute = '/',
    this.userAvatarUrl,
    this.username,
    this.userLevel,
    this.userTags = const [],
    this.supportedLocales = const [],
    this.isPlayButtonHovered = false,
  });

  /// 创建初始状态
  static AppBarState initial() {
    return AppBarState(
      title: 'Tune',
      showBackButton: false,
      dynamicActions: const [],
      themeMode: ThemeMode.system,
      locale: const Locale('zh', 'CN'),
      showMyDropdown: false,
      showLanguageDropdown: false,
      currentRoute: '/',
      userTags: const [],
      supportedLocales: const [],
      isPlayButtonHovered: false,
    );
  }

  /// 复制并更新状态
  AppBarState copyWith({
    String? title,
    bool? showBackButton,
    List<Widget>? dynamicActions,
    ThemeMode? themeMode,
    Locale? locale,
    bool? showMyDropdown,
    bool? showLanguageDropdown,
    String? currentRoute,
    String? userAvatarUrl,
    String? username,
    int? userLevel,
    List<String>? userTags,
    List<Locale>? supportedLocales,
    bool? isPlayButtonHovered,
  }) {
    return AppBarState(
      title: title ?? this.title,
      showBackButton: showBackButton ?? this.showBackButton,
      dynamicActions: dynamicActions ?? this.dynamicActions,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      showMyDropdown: showMyDropdown ?? this.showMyDropdown,
      showLanguageDropdown: showLanguageDropdown ?? this.showLanguageDropdown,
      currentRoute: currentRoute ?? this.currentRoute,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      username: username ?? this.username,
      userLevel: userLevel ?? this.userLevel,
      userTags: userTags ?? this.userTags,
      supportedLocales: supportedLocales ?? this.supportedLocales,
      isPlayButtonHovered: isPlayButtonHovered ?? this.isPlayButtonHovered,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppBarState &&
        other.title == title &&
        other.showBackButton == showBackButton &&
        listEquals(other.dynamicActions, dynamicActions) &&
        other.themeMode == themeMode &&
        other.locale == locale &&
        other.showMyDropdown == showMyDropdown &&
        other.showLanguageDropdown == showLanguageDropdown &&
        other.currentRoute == currentRoute &&
        other.userAvatarUrl == userAvatarUrl &&
        other.username == username &&
        other.userLevel == userLevel &&
        listEquals(other.userTags, userTags) &&
        listEquals(other.supportedLocales, supportedLocales) &&
        other.isPlayButtonHovered == isPlayButtonHovered;
  }

  @override
  int get hashCode => Object.hash(
        title,
        showBackButton,
        Object.hashAll(dynamicActions),
        themeMode,
        locale,
        showMyDropdown,
        showLanguageDropdown,
        currentRoute,
        userAvatarUrl,
        username,
        userLevel,
        Object.hashAll(userTags),
        Object.hashAll(supportedLocales),
        isPlayButtonHovered,
      );
}