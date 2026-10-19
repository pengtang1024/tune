import 'package:flutter/material.dart';

/// 统一的设计系统 - Design Tokens
/// 包含应用中所有设计相关的常量和配置
class AppDesignSystem {
  AppDesignSystem._();

  // ========== 颜色系统 ==========
  
  /// 主色调
  static const Color primary = Color(0xFF6B46C1);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF553C9A);
  
  /// 辅助色调
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryDark = Color(0xFFDB2777);
  
  /// 第三色调
  static const Color tertiary = Color(0xFF06B6D4);
  static const Color tertiaryLight = Color(0xFF22D3EE);
  static const Color tertiaryDark = Color(0xFF0891B2);
  
  /// 强调色
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF2563EB);
  
  /// 中性色
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  
  /// 功能色
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  /// 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 背景渐变 — 通用页面背景
  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFF3F4F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 播放器页面渐变 — 更深的紫色调，营造沉浸感
  static const LinearGradient playerGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFE0E7FF),
    ],
  );

  static const LinearGradient playerGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0F0F),
      Color(0xFF1A1A1A),
      Color(0xFF2D1B69),
    ],
  );

  /// Hero Header 渐变 — 首页顶部的活力渐变
  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFAFA), Color(0xFFF3F4F6)],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
  );

  // ========== 间距系统 ==========
  
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  static const double spacing96 = 96.0;
  static const double spacing128 = 128.0;

  // ========== 圆角系统 ==========
  
  static const double radius4 = 4.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radius32 = 32.0;
  static const double radius48 = 48.0;
  static const double radius64 = 64.0;
  
  static BorderRadius borderRadius4 = BorderRadius.circular(radius4);
  static BorderRadius borderRadius6 = BorderRadius.circular(radius6);
  static BorderRadius borderRadius8 = BorderRadius.circular(radius8);
  static BorderRadius borderRadius12 = BorderRadius.circular(radius12);
  static BorderRadius borderRadius16 = BorderRadius.circular(radius16);
  static BorderRadius borderRadius20 = BorderRadius.circular(radius20);
  static BorderRadius borderRadius24 = BorderRadius.circular(radius24);
  static BorderRadius borderRadius28 = BorderRadius.circular(radius28);
  static BorderRadius borderRadius32 = BorderRadius.circular(radius32);
  static BorderRadius borderRadius48 = BorderRadius.circular(radius48);
  static BorderRadius borderRadius64 = BorderRadius.circular(radius64);

  // ========== 阴影系统 ==========
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, -1),
    ),
  ];
  
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowHeavy => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get shadowColored => [
    BoxShadow(
      color: primary.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ========== 字体系统 ==========
  
  /// 主字体 — 不指定 fontFamily，使用平台原生字体
  /// Android: Roboto | iOS/macOS: SF Pro | Windows: Segoe UI | Linux: Ubuntu
  /// 这确保每个平台都有最佳的原生阅读体验
  static const String fontFamilyPrimary = ''; // empty = use platform default
  
  /// 等宽字体 — 用于时间戳、代码、等宽数字
  static const String fontFamilySecondary = 'JetBrains Mono';
  
  // 字体大小
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize22 = 22.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  static const double fontSize36 = 36.0;
  static const double fontSize40 = 40.0;
  static const double fontSize44 = 44.0;
  static const double fontSize48 = 48.0;
  static const double fontSize56 = 56.0;
  static const double fontSize64 = 64.0;
  
  // 字重
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // ========== 尺寸系统 ==========
  
  static const double iconSize16 = 16.0;
  static const double iconSize20 = 20.0;
  static const double iconSize24 = 24.0;
  static const double iconSize28 = 28.0;
  static const double iconSize32 = 32.0;
  static const double iconSize36 = 36.0;
  static const double iconSize40 = 40.0;
  static const double iconSize48 = 48.0;
  static const double iconSize56 = 56.0;
  static const double iconSize64 = 64.0;
  static const double iconSize80 = 80.0;
  
  static const double buttonHeight40 = 40.0;
  static const double buttonHeight44 = 44.0;
  static const double buttonHeight48 = 48.0;
  static const double buttonHeight52 = 52.0;
  static const double buttonHeight56 = 56.0;
  
  static const double inputHeight40 = 40.0;
  static const double inputHeight44 = 44.0;
  static const double inputHeight48 = 48.0;
  static const double inputHeight52 = 52.0;
  static const double inputHeight56 = 56.0;
  
  // 组件尺寸
  static const double albumCoverSize48 = 48.0;
  static const double albumCoverSize56 = 56.0;
  static const double albumCoverSize64 = 64.0;
  static const double albumCoverSize72 = 72.0;
  static const double albumCoverSize80 = 80.0;
  static const double albumCoverSize96 = 96.0;
  static const double albumCoverSize120 = 120.0;
  static const double albumCoverSize160 = 160.0;
  static const double albumCoverSize200 = 200.0;
  static const double albumCoverSize240 = 240.0;
  static const double albumCoverSize320 = 320.0;

  // ========== 动画系统 ==========
  
  static const Duration duration150 = Duration(milliseconds: 150);
  static const Duration duration200 = Duration(milliseconds: 200);
  static const Duration duration300 = Duration(milliseconds: 300);
  static const Duration duration400 = Duration(milliseconds: 400);
  static const Duration duration500 = Duration(milliseconds: 500);
  static const Duration duration600 = Duration(milliseconds: 600);
  static const Duration duration800 = Duration(milliseconds: 800);
  static const Duration duration1000 = Duration(milliseconds: 1000);
  
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveBounceIn = Curves.bounceIn;
  static const Curve curveBounceOut = Curves.bounceOut;
  static const Curve curveElasticOut = Curves.elasticOut;

  // ========== 断点系统 ==========
  
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;
  static const double breakpointDesktop = 1440.0;
  static const double breakpointWide = 1920.0;

  // ========== Z-Index 系统 ==========
  
  static const int zIndex0 = 0;
  static const int zIndex1 = 1;
  static const int zIndex2 = 2;
  static const int zIndex3 = 3;
  static const int zIndex4 = 4;
  static const int zIndex5 = 5;
  static const int zIndex10 = 10;
  static const int zIndex20 = 20;
  static const int zIndex30 = 30;
  static const int zIndex40 = 40;
  static const int zIndex50 = 50;

  // ========== 透明度系统 ==========
  
  static const double opacity5 = 0.05;
  static const double opacity10 = 0.10;
  static const double opacity20 = 0.20;
  static const double opacity30 = 0.30;
  static const double opacity40 = 0.40;
  static const double opacity50 = 0.50;
  static const double opacity60 = 0.60;
  static const double opacity70 = 0.70;
  static const double opacity80 = 0.80;
  static const double opacity90 = 0.90;
  static const double opacity95 = 0.95;

  // ========== 文本样式系统 ==========
  
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: fontSize56,
      fontWeight: fontWeightBold,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: fontSize44,
      fontWeight: fontWeightBold,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontSize: fontSize36,
      fontWeight: fontWeightBold,
      height: 1.15,
    ),
    headlineLarge: TextStyle(
      fontSize: fontSize32,
      fontWeight: fontWeightSemiBold,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: fontSize28,
      fontWeight: fontWeightSemiBold,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: fontSize24,
      fontWeight: fontWeightSemiBold,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: fontSize22,
      fontWeight: fontWeightSemiBold,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: fontSize18,
      fontWeight: fontWeightMedium,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: fontSize16,
      fontWeight: fontWeightMedium,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: fontSize16,
      fontWeight: fontWeightNormal,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: fontSize14,
      fontWeight: fontWeightNormal,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: fontSize12,
      fontWeight: fontWeightNormal,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: fontSize14,
      fontWeight: fontWeightMedium,
      height: 1.4,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontSize: fontSize12,
      fontWeight: fontWeightMedium,
      height: 1.4,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: fontSize10,
      fontWeight: fontWeightMedium,
      height: 1.4,
      letterSpacing: 0.5,
    ),
  );
}