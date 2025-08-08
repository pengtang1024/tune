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
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6200EE), // 电光紫作为主色调
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF6200EE), // 电光紫
      onPrimary: Colors.white,
      secondary: const Color(0xFF03DAC6), // 青色作为辅助色
      onSecondary: Colors.black,
      surface: Colors.white, // 使用surface替代background
      onSurface: Colors.black, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6200EE),
      foregroundColor: Colors.white,
    ),
  );

  /// 潮流轻电主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用电光蓝和青色，营造神秘而富有科技感的视觉效果。
  /// 适用场景：适合夜间使用，减少眼部疲劳，同时保持科技感的视觉风格。
  static final ThemeData trendyElectroDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFBB86FC), // 淡紫色作为主色调
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFBB86FC), // 淡紫色作为主色
      onPrimary: Colors.black,
      secondary: const Color(0xFF03DAC6), // 青色作为辅助色
      onSecondary: Colors.black,
      surface: const Color(0xFF121212), // 深灰色背景，使用surface替代background
      onSurface: Colors.white, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
  );

  /// 极简灰调主题 - 浅色模式
  /// 
  /// 设计理念：以灰色为主调，搭配简洁的黑白灰配色，营造极简、专业的视觉效果。
  /// 适用场景：适合喜欢简约风格和专业感的用户，在办公或学习环境中使用效果更佳。
  static final ThemeData minimalGrayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9E9E9E), // 灰色作为主色调
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF9E9E9E), // 灰色作为主色
      onPrimary: Colors.black,
      secondary: const Color(0xFF616161), // 深灰色作为辅助色
      onSecondary: Colors.white,
      surface: Colors.white, // 使用surface替代background
      onSurface: Colors.black, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF9E9E9E),
      foregroundColor: Colors.black,
    ),
  );

  /// 极简灰调主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用不同层次的灰色，营造专业、沉稳的视觉效果。
  /// 适用场景：适合夜间使用，减少眼部疲劳，同时保持专业感的视觉风格。
  static final ThemeData minimalGrayDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF757575), // 中灰色作为主色调
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF757575), // 中灰色作为主色
      onPrimary: Colors.white,
      secondary: const Color(0xFFBDBDBD), // 浅灰色作为辅助色
      onSecondary: Colors.black,
      surface: const Color(0xFF212121), // 深黑色背景，使用surface替代background
      onSurface: Colors.white, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF212121),
      foregroundColor: Colors.white,
    ),
  );

  /// 自然森系主题 - 浅色模式
  /// 
  /// 设计理念：以绿色为主调，搭配自然的色彩，营造清新、自然的视觉效果。
  /// 适用场景：适合喜欢自然风格和环保理念的用户，在放松时使用效果更佳。
  static final ThemeData natureForestTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // 绿色作为主色调
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF4CAF50), // 绿色作为主色
      onPrimary: Colors.white,
      secondary: const Color(0xFF8BC34A), // 浅绿色作为辅助色
      onSecondary: Colors.black,
      surface: Colors.white, // 使用surface替代background
      onSurface: Colors.black, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
    ),
  );

  /// 自然森系主题 - 深色模式
  /// 
  /// 设计理念：在深色背景上使用森林绿和苔藓绿，营造深邃、神秘的自然视觉效果。
  /// 适用场景：适合夜间使用，带来宁静自然的视觉体验。
  static final ThemeData natureForestDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF388E3C), // 深绿色作为主色调
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF388E3C), // 深绿色作为主色
      onPrimary: Colors.white,
      secondary: const Color(0xFF66BB6A), // 中绿色作为辅助色
      onSecondary: Colors.black,
      surface: const Color(0xFF1B5E20), // 深绿色背景，使用surface替代background
      onSurface: Colors.white, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
    ),
  );

  /// 赛博霓虹主题 - 浅色模式
  /// 
  /// 设计理念：以霓虹粉和电光蓝为主调，搭配高对比度的色彩，营造未来感和赛博朋克风格。
  /// 适用场景：适合喜欢个性和未来感的用户，在娱乐时使用效果更佳。
  static final ThemeData cyberNeonTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF4081), // 霓虹粉作为主色调
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFFFF4081), // 霓虹粉作为主色
      onPrimary: Colors.white,
      secondary: const Color(0xFF6200EE), // 电光紫作为辅助色
      onSecondary: Colors.white,
      surface: Colors.white, // 使用surface替代background
      onSurface: Colors.black, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF4081),
      foregroundColor: Colors.white,
    ),
  );

  /// 赛博霓虹主题 - 深色模式
  /// 
  /// 设计理念：在深黑色背景上使用霓虹粉和电光蓝，营造强烈的对比和未来感的视觉效果。
  /// 适用场景：适合夜间使用，带来强烈的视觉冲击和未来感体验。
  static final ThemeData cyberNeonDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF50057), // 深霓虹粉作为主色调
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFF50057), // 深霓虹粉作为主色
      onPrimary: Colors.white,
      secondary: const Color(0xFFBB86FC), // 淡紫色作为辅助色
      onSecondary: Colors.black,
      surface: const Color(0xFF0A0A0A), // 几乎纯黑的背景，使用surface替代background
      onSurface: Colors.white, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      foregroundColor: Colors.white,
    ),
  );

  /// 暖调治愈主题 - 浅色模式
  /// 
  /// 设计理念：以温暖的橙色和粉色为主调，搭配柔和的色彩，营造温馨、治愈的视觉效果。
  /// 适用场景：适合需要放松和治愈的用户，在休闲时使用效果更佳。
  static final ThemeData warmHealingTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9800), // 橙色作为主色调
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFFFF9800), // 橙色作为主色
      onPrimary: Colors.black,
      secondary: const Color(0xFFF8BBD0), // 浅粉色作为辅助色
      onSecondary: Colors.black,
      surface: Colors.white, // 使用surface替代background
      onSurface: Colors.black, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF9800),
      foregroundColor: Colors.black,
    ),
  );

  /// 暖调治愈主题 - 深色模式
  /// 
  /// 设计理念：在深棕色背景上使用温暖的橙色和粉色，营造温暖、舒适的视觉效果。
  /// 适用场景：适合夜间使用，带来温暖舒适的视觉体验。
  static final ThemeData warmHealingDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9800), // 橙色作为主色调
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFFFB74D), // 浅橙色作为主色
      onPrimary: Colors.black,
      secondary: const Color(0xFFF8BBD0), // 浅粉色作为辅助色
      onSecondary: Colors.black,
      surface: const Color(0xFF3E2723), // 深棕色背景，使用surface替代background
      onSurface: Colors.white, // 使用onSurface替代onBackground
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3E2723),
      foregroundColor: Colors.white,
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