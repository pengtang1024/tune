import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/menu_item.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/utils/device_utils.dart';

/// 菜单项组件
/// 仅负责显示单个菜单项
class MenuItemWidget extends ConsumerWidget {
  final DeviceMenuItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 根据设备类型设置合适的高度
    final deviceType = DeviceUtils.getDeviceType(context);
    final itemHeight = deviceType == DeviceType.mobile ? 48.0 : 56.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppDesignSystem.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: AppDesignSystem.borderRadius12,
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing8),
      child: SizedBox(
        height: itemHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppDesignSystem.borderRadius12,
            child: Row(
              children: [
                // 固定宽度的图标区域，确保展开和收起时宽度一致
                SizedBox(
                  width: 80.0,
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? AppDesignSystem.primary
                          : Theme.of(context).iconTheme.color,
                      size: AppDesignSystem.iconSize24,
                    ),
                  ),
                ),
                // 文字区域，收起时隐藏
                if (isExpanded)
                  Expanded(
                    child: Text(
                      _getLocalizedLabel(context, item.labelKey),
                      style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppDesignSystem.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected
                            ? AppDesignSystem.fontWeightSemiBold
                            : AppDesignSystem.fontWeightNormal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedLabel(BuildContext context, String labelKey) {
    // 根据标签键返回本地化字符串
    switch (labelKey) {
      case 'home':
        return context.loc.home;
      case 'recommend':
        return context.loc.recommend;
      case 'featured':
        return context.loc.featured;
      case 'library':
        return context.loc.library;
      case 'music_scan':
        return context.loc.music_scan; // 需要在本地化文件中添加这个键
      case 'settings':
        return context.loc.settings;
      case 'notification_test':
        return 'Notifications'; // 这是一个测试菜单项
      default:
        return labelKey;
    }
  }
}