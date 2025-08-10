import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme_interface.dart';
import 'web_theme.dart';
import 'trendy_electro_theme.dart';
import 'minimal_gray_theme.dart';
import 'nature_forest_theme.dart';
import 'cyber_neon_theme.dart';
import 'warm_healing_theme.dart';

/// 主题管理器
///
/// 管理应用程序的所有主题，支持多平台、多主题（含深浅模式）
/// 兼顾 Material 和 Cupertino 风格，同时支持自定义颜色、字体和格式
class ThemeManager {
  /// 支持的主题类型
  static const List<String> supportedThemes = [
    'trendyElectro',
    'minimalGray',
    'natureForest',
    'cyberNeon',
    'warmHealing',
  ];

  /// 验证主题名称是否有效
  static bool isValidTheme(String? themeName) {
    return themeName != null && supportedThemes.contains(themeName);
  }

  /// 获取默认主题名称
  static String get defaultTheme => 'trendyElectro';

  /// 根据主题名称获取对应的主题实例
  static AppThemeInterface getThemeInstance(String themeName) {
    switch (themeName) {
      case 'minimalGray':
        return MinimalGrayTheme();
      case 'natureForest':
        return NatureForestTheme();
      case 'cyberNeon':
        return CyberNeonTheme();
      case 'warmHealing':
        return WarmHealingTheme();
      case 'trendyElectro':
      default:
        return TrendyElectroTheme();
    }
  }

  /// 获取Material浅色主题
  static ThemeData getMaterialLightTheme(String themeName, String fontFamily) {
    final theme = getThemeInstance(themeName);
    return _applyFontFamily(theme.lightTheme, fontFamily);
  }

  /// 获取Material深色主题
  static ThemeData getMaterialDarkTheme(String themeName, String fontFamily) {
    final theme = getThemeInstance(themeName);
    return _applyFontFamily(theme.darkTheme, fontFamily);
  }

  /// 获取Cupertino主题
  static CupertinoThemeData getCupertinoTheme(String themeName, String fontFamily) {
    final theme = getThemeInstance(themeName);
    return _applyCupertinoFontFamily(theme.cupertinoTheme, fontFamily);
  }

  /// 获取Web主题
  static ThemeData getWebTheme(String themeName, String fontFamily) {
    final theme = getThemeInstance(themeName);
    return _applyFontFamily(theme.webTheme, fontFamily);
  }

  /// 应用字体家族到Material主题
  static ThemeData _applyFontFamily(ThemeData theme, String fontFamily) {
    return theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontFamily: _getEffectiveFontFamily(fontFamily),
      ),
    );
  }

  /// 应用字体家族到Cupertino主题
  static CupertinoThemeData _applyCupertinoFontFamily(
      CupertinoThemeData theme, String fontFamily) {
    final effectiveFontFamily = _getEffectiveFontFamily(fontFamily);
    if (effectiveFontFamily == null) {
      return theme;
    }

    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        textStyle: theme.textTheme.textStyle.copyWith(
          fontFamily: effectiveFontFamily,
        ),
      ),
    );
  }

  /// 获取有效的字体家族
  static String? _getEffectiveFontFamily(String? fontFamily) {
    if (fontFamily == null || fontFamily == 'Default') {
      return null; // 使用系统默认字体
    } else if (fontFamily.startsWith('JetBrainsMono')) {
      // 对于JetBrains Mono系列字体，使用统一字体系列名称
      return 'JetBrainsMono';
    } else {
      return fontFamily;
    }
  }

  /// 获取字体家族的静态方法（供其他类使用）
  static String? getFontFamily(String? fontFamily) {
    return _getEffectiveFontFamily(fontFamily);
  }
}
