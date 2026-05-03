import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_button_config.dart';

class ModernButton extends StatelessWidget {
  final String text;
  final IconData? icon;
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
    this.icon,
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

  factory ModernButton.icon({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    ModernButtonType type = ModernButtonType.primary,
    ModernButtonSize? size,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return ModernButton(
      key: key,
      text: '',
      onPressed: onPressed,
      type: type,
      size: size ?? ModernButtonSize.medium,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sizeConfig = ModernButtonUtils.getSizeConfig(size);
    final buttonHeight = height ?? sizeConfig.height;
    final buttonPadding = padding ?? sizeConfig.padding;
    final colors = ModernButtonUtils.getButtonColors(
      type,
      isDark,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
    );

    Widget buttonChild = _buildButtonContent(sizeConfig, colors, context);
    if (isLoading) {
      buttonChild = _buildLoadingWidget(sizeConfig, colors, context);
    }

    if (type == ModernButtonType.gradient) {
      return _buildGradientButton(buttonHeight, buttonPadding, buttonChild);
    }

    return _buildStandardButton(
      buttonHeight,
      buttonPadding,
      colors,
      buttonChild,
    );
  }

  Widget _buildButtonContent(
    ButtonSizeConfig sizeConfig,
    ButtonColors colors,
    BuildContext context,
  ) {
    if (child != null) {
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
              _buildText(text, sizeConfig, colors),
            ],
          ] else ...[
            child!,
          ],
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: colors.foregroundColor,
            size: sizeConfig.iconSize,
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(width: AppDesignSystem.spacing8),
            _buildText(text, sizeConfig, colors),
          ],
        ],
      );
    }

    return _buildText(text, sizeConfig, colors);
  }

  Widget _buildText(String text, ButtonSizeConfig sizeConfig, ButtonColors colors) {
    return Text(
      text,
      style: TextStyle(
        color: colors.foregroundColor,
        fontSize: sizeConfig.fontSize,
        fontWeight: AppDesignSystem.fontWeightMedium,
      ),
    );
  }

  Widget _buildLoadingWidget(
    ButtonSizeConfig sizeConfig,
    ButtonColors colors,
    BuildContext context,
  ) {
    if (loadingWidget != null) {
      return loadingWidget!;
    }

    return SizedBox(
      width: sizeConfig.fontSize,
      height: sizeConfig.fontSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colors.foregroundColor),
      ),
    );
  }

  Widget _buildGradientButton(
    double buttonHeight,
    EdgeInsetsGeometry buttonPadding,
    Widget buttonChild,
  ) {
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

  Widget _buildStandardButton(
    double buttonHeight,
    EdgeInsetsGeometry buttonPadding,
    ButtonColors colors,
    Widget buttonChild,
  ) {
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
}