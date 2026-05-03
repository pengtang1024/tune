import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

enum ModernButtonType {
  primary,
  secondary,
  outline,
  text,
  gradient,
}

enum ModernButtonSize {
  small,
  medium,
  large,
}

class ButtonSizeConfig {
  final double height;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  const ButtonSizeConfig({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}

class ButtonColors {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color splashColor;
  final Color highlightColor;
  final BoxBorder? border;

  const ButtonColors({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.splashColor,
    required this.highlightColor,
    this.border,
  });
}

class ModernButtonUtils {
  static ButtonSizeConfig getSizeConfig(ModernButtonSize size) {
    switch (size) {
      case ModernButtonSize.small:
        return const ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight40,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
          fontSize: AppDesignSystem.fontSize14,
          iconSize: AppDesignSystem.iconSize20,
        );
      case ModernButtonSize.medium:
        return const ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight48,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing24),
          fontSize: AppDesignSystem.fontSize16,
          iconSize: AppDesignSystem.iconSize24,
        );
      case ModernButtonSize.large:
        return const ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight56,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing32),
          fontSize: AppDesignSystem.fontSize18,
          iconSize: AppDesignSystem.iconSize28,
        );
    }
  }

  static ButtonColors getButtonColors(
    ModernButtonType type,
    bool isDark, {
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
  }) {
    switch (type) {
      case ModernButtonType.primary:
        return ButtonColors(
          backgroundColor: backgroundColor ?? AppDesignSystem.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          border: null,
        );
      case ModernButtonType.secondary:
        return ButtonColors(
          backgroundColor: backgroundColor ??
              (isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral100),
          foregroundColor: foregroundColor ??
              (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
          highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
          border: null,
        );
      case ModernButtonType.outline:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ??
              (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
          highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
          border: Border.all(
            color: borderColor ?? AppDesignSystem.primary,
            width: 1,
          ),
        );
      case ModernButtonType.text:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? AppDesignSystem.primary,
          splashColor: AppDesignSystem.primary.withValues(alpha: 0.1),
          highlightColor: AppDesignSystem.primary.withValues(alpha: 0.05),
          border: null,
        );
      case ModernButtonType.gradient:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? Colors.white,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          border: null,
        );
    }
  }
}