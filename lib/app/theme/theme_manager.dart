import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:tune/core/utils/platform_detector.dart';

import 'base_theme.dart';
import 'cyber_neon_theme.dart';
import 'minimal_gray_theme.dart';
import 'monochrome_theme.dart';
import 'nature_forest_theme.dart';
import 'trendy_electro_theme.dart';
import 'warm_healing_theme.dart';
import 'warm_orange_gradient_theme.dart';
import 'vibrant_red_theme.dart';

/// 主题管理器
///
/// 管理应用程序的所有主题，支持多平台、多主题（含深浅模式）
/// 兼顾 Material 和 Cupertino 风格，同时支持自定义颜色、字体和格式
class ThemeManager {
  /// 支持的主题类型
  static const List<String> supportedThemes = ['trendyElectro', 'minimalGray', 'natureForest', 'cyberNeon', 'warmHealing', 'warmOrangeGradient', 'monochrome', 'vibrantRed'];

  /// 验证主题名称是否有效
  static bool isValidTheme(String? themeName) {
    return themeName != null && supportedThemes.contains(themeName);
  }

  /// 获取默认主题名称
  static String get defaultTheme => 'trendyElectro';

  /// 根据主题名称获取对应的主题实例
  static BaseTheme getThemeInstance(String themeName, String? fontFamily, ThemeMode? themeMode) {
    switch (themeName) {
      case 'minimalGray':
        return MinimalGrayTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'natureForest':
        return NatureForestTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'cyberNeon':
        return CyberNeonTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'warmHealing':
        return WarmHealingTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'warmOrangeGradient':
        return WarmOrangeGradientTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'monochrome':
        return MonochromeTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'vibrantRed':
        return VibrantRedTheme(fontFamily: fontFamily, themeMode: themeMode);
      case 'trendyElectro':
      default:
        return TrendyElectroTheme(fontFamily: fontFamily, themeMode: themeMode);
    }
  }

  /// 获取当前平台应该使用的主题数据
  static Diagnosticable getThemeData(BuildContext context, String themeName, String? fontFamily, ThemeMode? themeMode) {
    if (PlatformDetector.isWeb) {
      // Web平台使用Web主题
      return getWebTheme(themeName, fontFamily ?? '', themeMode);
    } else if (PlatformDetector.isCupertino) {
      // 移动平台(Android/iOS)使用Material主题
      return getCupertinoTheme(themeName, fontFamily, themeMode);
    } else if (PlatformDetector.isMaterial) {
      return getMaterialTheme(themeName, fontFamily, themeMode);
    } else {
      // 默认使用Material主题
      return getMaterialTheme(themeName, fontFamily, themeMode);
    }
  }

  /// 获取Material主题
  static ThemeData getMaterialTheme(String themeName, String? fontFamily, ThemeMode? themeMode) {
    final theme = getThemeInstance(themeName, fontFamily, themeMode);
    return _applyFontFamily(theme.buildThemeData(fontFamily, themeMode ?? ThemeMode.system), fontFamily, themeMode);
  }

  /// 获取Cupertino主题
  static CupertinoThemeData getCupertinoTheme(String themeName, String? fontFamily, ThemeMode? themeMode) {
    final theme = getThemeInstance(themeName, fontFamily, themeMode);
    return _applyCupertinoFontFamily(theme.cupertinoTheme, fontFamily, themeMode);
  }

  /// 获取Web主题
  static ThemeData getWebTheme(String themeName, String fontFamily, ThemeMode? themeMode) {
    final theme = getThemeInstance(themeName, fontFamily, themeMode);
    return _applyFontFamily(theme.buildThemeData(fontFamily, themeMode ?? ThemeMode.system), fontFamily, themeMode);
  }

  /// 应用字体家族到Material主题
  static ThemeData _applyFontFamily(ThemeData theme, String? fontFamily, ThemeMode? themeMode) {
    return theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: _getEffectiveFontFamily(fontFamily, themeMode)));
  }

  /// 应用字体家族到Cupertino主题
  static CupertinoThemeData _applyCupertinoFontFamily(CupertinoThemeData theme, String? fontFamily, ThemeMode? themeMode) {
    final effectiveFontFamily = _getEffectiveFontFamily(fontFamily, themeMode);
    if (effectiveFontFamily == null) {
      return theme;
    }

    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(textStyle: theme.textTheme.textStyle.copyWith(fontFamily: effectiveFontFamily)),
    );
  }

  /// 获取有效的字体家族
  static String? _getEffectiveFontFamily(String? fontFamily, ThemeMode? themeMode) {
    return fontFamily;
  }
}
