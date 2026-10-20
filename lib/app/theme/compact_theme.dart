import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';

/// The visual language for Tune.
///
/// Warm paper and ink in light mode, almost-black espresso in dark mode, and a
/// single vermilion accent. Display type is Fraunces; UI text is Instrument
/// Sans; timestamps and metadata use JetBrains Mono.
///
/// Those three faces carry Latin glyphs only, so every style also names a CJK
/// family to fall back on. See [CompactTypography].
abstract final class CompactTheme {
  static const Color accent = Color(0xFFE6532F);
  static const Color accentDark = Color(0xFFFF6B48);
  static const Color moss = Color(0xFF5D7050);
  static const Color mossDark = Color(0xFFA9BE93);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF11100E)
        : const Color(0xFFF1ECE2);
    final panel = isDark ? const Color(0xFF191713) : const Color(0xFFFBF7F0);
    final panelHigh = isDark
        ? const Color(0xFF211E19)
        : const Color(0xFFE8E1D5);
    final text = isDark ? const Color(0xFFF2EBDD) : const Color(0xFF171512);
    final muted = isDark ? const Color(0xFFA59B8C) : const Color(0xFF746C60);
    final border = isDark ? const Color(0xFF2C2822) : const Color(0xFFD9D0C2);
    final primary = isDark ? accentDark : accent;
    final onPrimary = isDark
        ? const Color(0xFF1B0E0A)
        : const Color(0xFFFFFFFF);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: primary.withValues(alpha: isDark ? 0.22 : 0.14),
          onPrimaryContainer: text,
          secondary: isDark ? mossDark : moss,
          onSecondary: isDark ? const Color(0xFF161A12) : Colors.white,
          secondaryContainer: (isDark ? mossDark : moss).withValues(
            alpha: 0.16,
          ),
          onSecondaryContainer: text,
          surface: background,
          onSurface: text,
          surfaceContainerLowest: isDark
              ? const Color(0xFF0C0B09)
              : const Color(0xFFF8F4EC),
          surfaceContainerLow: isDark
              ? const Color(0xFF151310)
              : const Color(0xFFF5F0E7),
          surfaceContainer: panel,
          surfaceContainerHigh: panelHigh,
          surfaceContainerHighest: isDark
              ? const Color(0xFF2A2620)
              : const Color(0xFFDED6C8),
          onSurfaceVariant: muted,
          outline: isDark ? const Color(0xFF4A443B) : const Color(0xFFB8AD9C),
          outlineVariant: border,
          surfaceTint: Colors.transparent,
          error: isDark ? const Color(0xFFFF7A6E) : const Color(0xFFC43A2F),
          onError: isDark ? const Color(0xFF1B0B08) : Colors.white,
        );

    final baseText = Typography.material2021(platform: TargetPlatform.linux)
        .black
        .apply(
          bodyColor: text,
          displayColor: text,
          fontFamily: CompactTypography.sansFamily,
          fontFamilyFallback: CompactTypography.sansFallback,
        );

    // The interface text follows the scale, so a word keeps its size
    // wherever it appears. The display family sits above the scale: it is
    // the big serif voice of the shell and it has a size of its own.
    final textTheme = baseText.copyWith(
      displayLarge: _display(text, 40, -1.4),
      displayMedium: _display(text, 34, -1.0),
      displaySmall: _display(text, 28, -0.6),
      headlineLarge: _sans(text, 24, FontWeight.w700, -0.5),
      headlineMedium: _sans(text, 20, FontWeight.w700, -0.3),
      headlineSmall: _sans(text, CompactTypeScale.heading, FontWeight.w600),
      titleLarge: _sans(text, 18, FontWeight.w600, -0.2),
      titleMedium: _sans(text, CompactTypeScale.title, FontWeight.w600),
      titleSmall: _sans(text, CompactTypeScale.strong, FontWeight.w600),
      bodyLarge: _sans(text, CompactTypeScale.title, FontWeight.w400),
      bodyMedium: _sans(text, CompactTypeScale.strong, FontWeight.w400),
      bodySmall: _sans(text, CompactTypeScale.body, FontWeight.w400),
      labelLarge: _sans(text, CompactTypeScale.strong, FontWeight.w600, 0.1),
      labelMedium: _sans(text, CompactTypeScale.label, FontWeight.w600, 0.2),
      labelSmall: _sans(text, CompactTypeScale.micro, FontWeight.w600, 0.4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: CompactTypography.sansFamily,
      fontFamilyFallback: CompactTypography.sansFallback,
      textTheme: textTheme,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: muted, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: _sans(onPrimary, CompactTypeScale.body, FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: BorderSide(color: border),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          textStyle: _sans(text, CompactTypeScale.body, FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          textStyle: _sans(text, CompactTypeScale.body, FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelHigh,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        hintStyle: _sans(muted, CompactTypeScale.body, FontWeight.w400),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelHigh,
        selectedColor: primary.withValues(alpha: isDark ? 0.22 : 0.13),
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: _sans(muted, CompactTypeScale.body, FontWeight.w600),
        secondaryLabelStyle: _sans(primary, CompactTypeScale.body, FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        titleTextStyle: _sans(text, CompactTypeScale.heading, FontWeight.w700),
        contentTextStyle: _sans(muted, CompactTypeScale.body, FontWeight.w400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFFF2EBDD)
            : const Color(0xFF171512),
        contentTextStyle: _sans(
          isDark ? const Color(0xFF171512) : const Color(0xFFF2EBDD),
          12.5,
          FontWeight.w500,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        insetPadding: const EdgeInsets.all(16),
        elevation: 0,
      ),
      tooltipTheme: _tooltipTheme(isDark),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return panelHigh;
        }),
        trackOutlineColor: WidgetStatePropertyAll(border),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: 0.35)),
        crossAxisMargin: 2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panelHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
        textStyle: _sans(text, 13, FontWeight.w500),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
    );
  }

  /// The look of every hint of the app.
  ///
  /// A hint is a drop of ink: a dark card with paper words, in the light theme
  /// and in the dark one. In the light theme it is deep ink on the paper of
  /// the page. In the dark theme it is a panel of the app, lifted by a rim of
  /// a warmer tone and by a shadow, so that it stays a card and never becomes
  /// a white box on a dark desk.
  ///
  /// The hint opens above the thing it belongs to, because a pointer that
  /// rests on a button would cover a hint below it, and it stays long enough
  /// to be read.
  static TooltipThemeData _tooltipTheme(bool isDark) {
    final card = isDark ? const Color(0xFF211E19) : const Color(0xFF171512);
    final rim = isDark ? const Color(0xFF4A443B) : const Color(0xFF3B332A);
    final words = const Color(0xFFF2EBDD);

    return TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 4),
      exitDuration: const Duration(milliseconds: 120),
      preferBelow: false,
      verticalOffset: 12,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      constraints: const BoxConstraints(minHeight: 26, maxWidth: 320),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: rim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      textStyle: _sans(words, 12, FontWeight.w500),
    );
  }

  static TextStyle _sans(
    Color color,
    double size,
    FontWeight weight, [
    double letterSpacing = 0,
  ]) {
    return CompactTypography.sans(
      color,
      size: size,
      weight: weight,
      letterSpacing: letterSpacing,
      height: 1.3,
    );
  }

  static TextStyle _display(Color color, double size, double letterSpacing) {
    return CompactTypography.display(
      color,
      size: size,
      letterSpacing: letterSpacing,
      height: 0.98,
    );
  }
}
