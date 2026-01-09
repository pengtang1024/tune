import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

/// 现代化按钮组件
/// 提供一致的按钮样式和交互效果
class ModernButton extends StatelessWidget {
  final String text;
  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ModernButtonType type;
  final ModernButtonSize size;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? loadingWidget;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BorderSide? borderSide;

  const ModernButton({
    super.key,
    this.text = '',
    this.child,
    this.onPressed,
    this.onLongPress,
    this.type = ModernButtonType.primary,
    this.size = ModernButtonSize.medium,
    this.width,
    this.height,
    this.isLoading = false,
    this.isFullWidth = false,
    this.loadingWidget,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.borderSide,
  });

  /// 创建一个主要按钮
  factory ModernButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ModernButtonType.primary,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// 创建一个次要按钮
  factory ModernButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ModernButtonType.secondary,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// 创建一个轮廓按钮
  factory ModernButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ModernButtonType.outline,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// 创建一个文本按钮
  factory ModernButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ModernButtonType.text,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// 创建一个渐变按钮
  factory ModernButton.gradient({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ModernButtonType.gradient,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// 创建一个图标按钮
  factory ModernButton.icon({
    Key? key,
    required Widget icon,
    required String text,
    VoidCallback? onPressed,
    ModernButtonSize? size,
    ModernButtonType? type,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: text,
      child: icon,
      onPressed: onPressed,
      type: type ?? ModernButtonType.primary,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 获取按钮尺寸配置
    final sizeConfig = _getSizeConfig();
    final buttonHeight = height ?? sizeConfig.height;
    final buttonPadding = padding ?? sizeConfig.padding;

    // 获取按钮颜色
    final colors = _getButtonColors(isDark);

    // 构建按钮内容
    Widget buttonChild = _buildButtonContent(sizeConfig, context);

    // 如果是加载状态，显示加载指示器
    if (isLoading) {
      buttonChild = _buildLoadingWidget(sizeConfig, context);
    }

    // 如果是渐变按钮
    if (type == ModernButtonType.gradient) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: buttonHeight,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            onLongPress: isLoading ? null : onLongPress,
            borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
            child: Container(
              padding: buttonPadding,
              decoration: BoxDecoration(
                gradient: AppDesignSystem.primaryGradient,
                borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
                boxShadow: onPressed != null ? AppDesignSystem.shadowColored : [],
              ),
              child: Center(child: buttonChild),
            ),
          ),
        ),
      );
    }

    // 标准按钮
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: buttonHeight,
      child: Material(
        color: colors.backgroundColor,
        borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
        elevation: type == ModernButtonType.primary && onPressed != null ? 2 : 0,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          onLongPress: isLoading ? null : onLongPress,
          borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
          splashColor: colors.splashColor,
          highlightColor: colors.highlightColor,
          child: Container(
            padding: buttonPadding,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? AppDesignSystem.borderRadius12,
              border: colors.border,
            ),
            child: Center(child: buttonChild),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(_ButtonSizeConfig sizeConfig, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _getButtonColors(isDark);

    if (child != null) {
      // 如果有自定义子组件，文本和图标的布局需要手动处理
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (child is Icon) ...[
            DefaultTextStyle.merge(
              style: TextStyle(
                color: colors.foregroundColor,
                fontSize: sizeConfig.iconSize,
              ),
              child: child!,
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(width: AppDesignSystem.spacing8),
              Text(
                text,
                style: TextStyle(
                  color: colors.foregroundColor,
                  fontSize: sizeConfig.fontSize,
                  fontWeight: AppDesignSystem.fontWeightMedium,
                ),
              ),
            ],
          ] else ...[
            child!,
          ],
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: colors.foregroundColor,
        fontSize: sizeConfig.fontSize,
        fontWeight: AppDesignSystem.fontWeightMedium,
      ),
    );
  }

  Widget _buildLoadingWidget(_ButtonSizeConfig sizeConfig, BuildContext context) {
    if (loadingWidget != null) {
      return loadingWidget!;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _getButtonColors(isDark);

    return SizedBox(
      width: sizeConfig.fontSize,
      height: sizeConfig.fontSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colors.foregroundColor),
      ),
    );
  }

  _ButtonSizeConfig _getSizeConfig() {
    switch (size) {
      case ModernButtonSize.small:
        return const _ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight40,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
          fontSize: AppDesignSystem.fontSize14,
          iconSize: AppDesignSystem.iconSize20,
        );
      case ModernButtonSize.medium:
        return const _ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight48,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing24),
          fontSize: AppDesignSystem.fontSize16,
          iconSize: AppDesignSystem.iconSize24,
        );
      case ModernButtonSize.large:
        return const _ButtonSizeConfig(
          height: AppDesignSystem.buttonHeight56,
          padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing32),
          fontSize: AppDesignSystem.fontSize18,
          iconSize: AppDesignSystem.iconSize28,
        );
    }
  }

  _ButtonColors _getButtonColors(bool isDark) {
    switch (type) {
      case ModernButtonType.primary:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? AppDesignSystem.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          border: null,
        );
      case ModernButtonType.secondary:
        return _ButtonColors(
          backgroundColor: backgroundColor ?? 
              (isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral100),
          foregroundColor: foregroundColor ?? 
              (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          splashColor: AppDesignSystem.primary.withOpacity(0.1),
          highlightColor: AppDesignSystem.primary.withOpacity(0.05),
          border: null,
        );
      case ModernButtonType.outline:
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? 
              (isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900),
          splashColor: AppDesignSystem.primary.withOpacity(0.1),
          highlightColor: AppDesignSystem.primary.withOpacity(0.05),
          border: Border.all(
            color: borderColor ?? AppDesignSystem.primary,
            width: 1,
          ),
        );
      case ModernButtonType.text:
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? AppDesignSystem.primary,
          splashColor: AppDesignSystem.primary.withOpacity(0.1),
          highlightColor: AppDesignSystem.primary.withOpacity(0.05),
          border: null,
        );
      case ModernButtonType.gradient:
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? Colors.white,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          border: null,
        );
    }
  }
}

/// 按钮类型枚举
enum ModernButtonType {
  primary,
  secondary,
  outline,
  text,
  gradient,
}

/// 按钮尺寸枚举
enum ModernButtonSize {
  small,
  medium,
  large,
}

/// 按钮尺寸配置
class _ButtonSizeConfig {
  final double height;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;

  const _ButtonSizeConfig({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });
}

/// 按钮颜色配置
class _ButtonColors {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color splashColor;
  final Color highlightColor;
  final BoxBorder? border;

  const _ButtonColors({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.splashColor,
    required this.highlightColor,
    this.border,
  });
}