import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_animations.dart';

class SkeletonLoader {
  SkeletonLoader._();

  static Widget songList({int count = 8}) {
    return SizedBox(
      height: 72 * count.toDouble(),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing8,
            vertical: AppDesignSystem.spacing4,
          ),
          child: _songRowItem(),
        ),
      ),
    );
  }

  static Widget _songRowItem() {
    return AppAnimations.shimmerLoading(
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral200,
              borderRadius: AppDesignSystem.borderRadius8,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.neutral200,
                    borderRadius: AppDesignSystem.borderRadius4,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing6),
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.neutral200,
                    borderRadius: AppDesignSystem.borderRadius4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget card({double height = 120}) {
    return AppAnimations.shimmerLoading(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppDesignSystem.neutral200,
          borderRadius: AppDesignSystem.borderRadius16,
        ),
      ),
    );
  }

  static Widget homeHeader() {
    return Column(
      children: [
        AppAnimations.shimmerLoading(
          child: Container(
            width: AppDesignSystem.albumCoverSize120,
            height: AppDesignSystem.albumCoverSize120,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral200,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing20),
        AppAnimations.shimmerLoading(
          child: Container(
            width: 180, height: 28,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral200,
              borderRadius: AppDesignSystem.borderRadius8,
            ),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        AppAnimations.shimmerLoading(
          child: Container(
            width: 140, height: 16,
            decoration: BoxDecoration(
              color: AppDesignSystem.neutral200,
              borderRadius: AppDesignSystem.borderRadius8,
            ),
          ),
        ),
      ],
    );
  }
}

extension AdaptiveScroll on Widget {
  Widget withAdaptiveScroll({Axis scrollDirection = Axis.vertical, EdgeInsetsGeometry? padding}) {
    final isIOS = _isIOS();
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      physics: isIOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
      padding: padding,
      child: this,
    );
  }
}

extension AdaptiveList on ListView {
  static ListView adaptive({
    required List<Widget> children,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    final isIOS = _isIOS();
    return ListView(
      shrinkWrap: shrinkWrap,
      padding: padding,
      physics: isIOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
      children: children,
    );
  }
}

bool _isIOS() {
  return defaultTargetPlatform == TargetPlatform.iOS;
}
