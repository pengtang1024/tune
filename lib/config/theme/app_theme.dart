import 'package:flutter/material.dart';

/// 应用主题配置类
/// 
/// 定义了应用程序的各种主题样式，包括颜色、字体、形状等设计元素。
/// 每个主题都遵循Material Design设计规范，并针对不同的视觉风格进行了定制。
class AppTheme {
  /// 潮流轻电主题 - 浅色模式
  /// 
  /// 设计理念：以科技感的电光蓝为主色，搭配简洁的白色背景，营造现代、潮流的视觉效果。
  /// 适用场景：适合喜欢科技感和现代风格的用户，在明亮环境下使用效果更佳。
  static final ThemeData trendyElectroTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFC7D2FE), // 雾蓝紫
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFC7D2FE), // 雾蓝紫
      onPrimary: Color(0xFF1E293B), // 深灰蓝
      secondary: Color(0xFFFBCFE8), // 柔粉作为辅助色
      onSecondary: Color(0xFF1E293B), // 深灰蓝
      tertiary: Color(0xFFBFDBFE), // 浅蓝作为辅助色2
      onTertiary: Color(0xFF1E293B), // 深灰蓝
      surface: Color(0xFFFAFAFC), // 极浅灰背景色
      onSurface: Color(0xFF1E293B), // 深灰蓝文本主色
      onSurfaceVariant: Color(0xFF64748B), // 灰蓝文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFC), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFC7D2FE),
      foregroundColor: Color(0xFF1E293B),
      titleTextStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFFFFFFF), // 白色卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 潮流轻电主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用电光蓝和青色，营造神秘而富有科技感的视觉效果。
  /// 适用场景：适合夜间使用，减少眼部疲劳，同时保持科技感的视觉风格。
  static final ThemeData trendyElectroDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF5B21B6), // 暗紫蓝
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF5B21B6), // 暗紫蓝
      onPrimary: Color(0xFFF8FAFC), // 浅灰
      secondary: Color(0xFFEC4899), // 粉紫作为辅助色
      onSecondary: Color(0xFFF8FAFC), // 浅灰
      tertiary: Color(0xFF2563EB), // 中蓝作为辅助色2
      onTertiary: Color(0xFFF8FAFC), // 浅灰
      surface: Color(0xFF1E1B4B), // 深紫黑背景色
      onSurface: Color(0xFFF8FAFC), // 浅灰文本主色
      onSurfaceVariant: Color(0xFF94A3B8), // 中灰蓝文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1B4B), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF5B21B6),
      foregroundColor: Color(0xFFF8FAFC),
      titleTextStyle: TextStyle(
        color: Color(0xFFF8FAFC),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF312E81), // 暗紫灰卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 极简灰调主题 - 浅色模式
  /// 
  /// 设计理念：以灰色为主调，搭配简洁的黑白灰配色，营造极简、专业的视觉效果。
  /// 适用场景：适合喜欢简约风格和专业感的用户，在办公或学习环境中使用效果更佳。
  static final ThemeData minimalGrayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF9CA3AF), // 中灰
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9CA3AF), // 中灰
      onPrimary: Color(0xFF111827), // 近黑
      secondary: Color(0xFFD1D5DB), // 浅灰作为辅助色
      onSecondary: Color(0xFF111827), // 近黑
      tertiary: Color(0xFF93C5FD), // 雾蓝作为辅助色2
      onTertiary: Color(0xFF111827), // 近黑
      surface: Color(0xFFF9FAFB), // 极浅灰背景色
      onSurface: Color(0xFF111827), // 近黑文本主色
      onSurfaceVariant: Color(0xFF6B7280), // 中灰文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFFF9FAFB), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF9CA3AF),
      foregroundColor: Color(0xFF111827),
      titleTextStyle: TextStyle(
        color: Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white, // 白色卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 极简灰调主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用不同层次的灰色，营造专业、沉稳的视觉效果。
  /// 适用场景：适合夜间使用，减少眼部疲劳，同时保持专业感的视觉风格。
  static final ThemeData minimalGrayDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4B5563), // 深灰
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4B5563), // 深灰
      onPrimary: Color(0xFFF9FAFB), // 近白
      secondary: Color(0xFF6B7280), // 中灰作为辅助色
      onSecondary: Color(0xFFF9FAFB), // 近白
      tertiary: Color(0xFF60A5FA), // 柔蓝作为辅助色2
      onTertiary: Color(0xFFF9FAFB), // 近白
      surface: Color(0xFF1F2937), // 深灰黑背景色
      onSurface: Color(0xFFF9FAFB), // 近白文本主色
      onSurfaceVariant: Color(0xFFD1D5DB), // 浅灰文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFF1F2937), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4B5563),
      foregroundColor: Color(0xFFF9FAFB),
      titleTextStyle: TextStyle(
        color: Color(0xFFF9FAFB),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF374151), // 暗灰卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 自然森系主题 - 浅色模式
  /// 
  /// 设计理念：以绿色为主调，搭配自然的色彩，营造清新、自然的视觉效果。
  /// 适用场景：适合喜欢自然风格和环保理念的用户，在放松时使用效果更佳。
  static final ThemeData natureForestTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFA7F3D0), // 浅青绿
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFA7F3D0), // 浅青绿
      onPrimary: Color(0xFF1E293B), // 深灰
      secondary: Color(0xFFDCFCE7), // 芽绿白作为辅助色
      onSecondary: Color(0xFF1E293B), // 深灰
      tertiary: Color(0xFFEFEBE9), // 木色灰作为辅助色2
      onTertiary: Color(0xFF1E293B), // 深灰
      surface: Color(0xFFF0FDF4), // 浅绿白背景色
      onSurface: Color(0xFF1E293B), // 深灰文本主色
      onSurfaceVariant: Color(0xFF64748B), // 灰蓝文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFFF0FDF4), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFA7F3D0),
      foregroundColor: Color(0xFF1E293B),
      titleTextStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white, // 白色卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 自然森系主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用森林绿和苔藓绿，营造深邃、神秘的自然视觉效果。
  /// 适用场景：适合夜间使用，带来宁静自然的视觉体验。
  static final ThemeData natureForestDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4D7C0F), // 橄榄绿
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4D7C0F), // 橄榄绿
      onPrimary: Color(0xFFF0FDF4), // 浅绿白
      secondary: Color(0xFF10B981), // 青绿作为辅助色
      onSecondary: Color(0xFFF0FDF4), // 浅绿白
      tertiary: Color(0xFFA8A29E), // 暖灰棕作为辅助色2
      onTertiary: Color(0xFFF0FDF4), // 浅绿白
      surface: Color(0xFF132F10), // 深绿黑背景色
      onSurface: Color(0xFFF0FDF4), // 浅绿白文本主色
      onSurfaceVariant: Color(0xFFA7F3D0), // 浅青绿文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFF132F10), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4D7C0F),
      foregroundColor: Color(0xFFF0FDF4),
      titleTextStyle: TextStyle(
        color: Color(0xFFF0FDF4),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1F3A18), // 暗绿灰卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 赛博霓虹主题 - 浅色模式
  /// 
  /// 设计理念：以霓虹粉和电光蓝为主调，搭配高对比度的色彩，营造未来感和赛博朋克风格。
  /// 适用场景：适合喜欢个性和未来感的用户，在娱乐时使用效果更佳。
  static final ThemeData cyberNeonTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFBFDBFE), // 浅蓝
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFBFDBFE), // 浅蓝
      onPrimary: Color(0xFF1E293B), // 深灰蓝
      secondary: Color(0xFFEDE9FE), // 紫白作为辅助色
      onSecondary: Color(0xFF1E293B), // 深灰蓝
      tertiary: Color(0xFFCCFBF1), // 青白作为辅助色2
      onTertiary: Color(0xFF1E293B), // 深灰蓝
      surface: Color(0xFFF1F5F9), // 浅灰背景色
      onSurface: Color(0xFF1E293B), // 深灰蓝文本主色
      onSurfaceVariant: Color(0xFF64748B), // 灰蓝文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFBFDBFE),
      foregroundColor: Color(0xFF1E293B),
      titleTextStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white, // 白色卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 赛博霓虹主题 - 深色模式
  /// 
  /// 设计理念：在深黑色背景上使用霓虹粉和电光蓝，营造强烈的对比和未来感的视觉效果。
  /// 适用场景：适合夜间使用，带来强烈的视觉冲击和未来感体验。
  static final ThemeData cyberNeonDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1E40AF), // 暗蓝
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1E40AF), // 暗蓝
      onPrimary: Color(0xFFF1F5F9), // 浅灰
      secondary: Color(0xFF7C3AED), // 深紫作为辅助色
      onSecondary: Color(0xFFF1F5F9), // 浅灰
      tertiary: Color(0xFF06B6D4), // 青蓝作为辅助色2
      onTertiary: Color(0xFFF1F5F9), // 浅灰
      surface: Color(0xFF0F172A), // 靛蓝黑背景色
      onSurface: Color(0xFFF1F5F9), // 浅灰文本主色
      onSurfaceVariant: Color(0xFF94A3B8), // 中灰蓝文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E40AF),
      foregroundColor: Color(0xFFF1F5F9),
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF334155), // 深蓝灰卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 暖调治愈主题 - 浅色模式
  /// 
  /// 设计理念：以温暖的橙色和粉色为主调，搭配柔和的色彩，营造温馨、治愈的视觉效果。
  /// 适用场景：适合需要放松和治愈的用户，在休闲时使用效果更佳。
  static final ThemeData warmHealingTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFFDE68A), // 柔黄
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFDE68A), // 柔黄
      onPrimary: Color(0xFF374151), // 深棕
      secondary: Color(0xFFFEF3C7), // 米黄作为辅助色
      onSecondary: Color(0xFF374151), // 深棕
      tertiary: Color(0xFFFBCFE8), // 柔粉作为辅助色2
      onTertiary: Color(0xFF374151), // 深棕
      surface: Color(0xFFFFFAF0), // 浅橙白背景色
      onSurface: Color(0xFF374151), // 深棕文本主色
      onSurfaceVariant: Color(0xFF9CA3AF), // 中灰文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFAF0), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFDE68A),
      foregroundColor: Color(0xFF374151),
      titleTextStyle: TextStyle(
        color: Color(0xFF374151),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white, // 白色卡片
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// 暖调治愈主题 - 深色模式
  /// 
  /// 设计理念：在深棕色背景上使用温暖的橙色和粉色，营造温暖、舒适的视觉效果。
  /// 适用场景：适合夜间使用，带来温暖舒适的视觉体验。
  static final ThemeData warmHealingDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFB45309), // 深棕
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFB45309), // 深棕
      onPrimary: Color(0xFFFEF3C7), // 米黄
      secondary: Color(0xFFF59E0B), // 暖橙作为辅助色
      onSecondary: Color(0xFFFEF3C7), // 米黄
      tertiary: Color(0xFFEC4899), // 粉棕作为辅助色2
      onTertiary: Color(0xFFFEF3C7), // 米黄
      surface: Color(0xFF1F2937), // 深棕黑背景色
      onSurface: Color(0xFFFEF3C7), // 米黄文本主色
      onSurfaceVariant: Color(0xFFD1D5DB), // 浅灰文本次色
    ),
    scaffoldBackgroundColor: const Color(0xFF1F2937), // 页面底色
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      titleSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFB45309),
      foregroundColor: Color(0xFFFEF3C7),
      titleTextStyle: TextStyle(
        color: Color(0xFFFEF3C7),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF374151), // 深棕灰卡片
      surfaceTintColor: Colors.transparent,
    ),
  );
  
  /// 根据主题名称获取对应的AppTheme实例
  ///
  /// [themeName] 主题名称
  /// 返回包含浅色和深色主题的AppTheme实例
  static AppTheme getTheme(String themeName) {
    switch (themeName) {
      case 'trendyElectro':
        return AppTheme(
          themeData: trendyElectroTheme,
          darkThemeData: trendyElectroDarkTheme,
        );
      case 'minimalGray':
        return AppTheme(
          themeData: minimalGrayTheme,
          darkThemeData: minimalGrayDarkTheme,
        );
      case 'natureForest':
        return AppTheme(
          themeData: natureForestTheme,
          darkThemeData: natureForestDarkTheme,
        );
      case 'cyberNeon':
        return AppTheme(
          themeData: cyberNeonTheme,
          darkThemeData: cyberNeonDarkTheme,
        );
      case 'warmHealing':
        return AppTheme(
          themeData: warmHealingTheme,
          darkThemeData: warmHealingDarkTheme,
        );
      default:
        return AppTheme(
          themeData: trendyElectroTheme,
          darkThemeData: trendyElectroDarkTheme,
        );
    }
  }
  
  /// 浅色主题数据
  final ThemeData themeData;
  
  /// 深色主题数据
  final ThemeData darkThemeData;
  
  /// 创建AppTheme实例
  ///
  /// [themeData] 浅色主题数据
  /// [darkThemeData] 深色主题数据
  AppTheme({required this.themeData, required this.darkThemeData});
}