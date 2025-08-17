import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/domain/models/menu_item.dart';
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
    final itemHeight = deviceType == DeviceType.mobile ? 40.0 : 48.0;

    return Material(
      color: isSelected ? context.theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: SizedBox(
        height: itemHeight, // 根据设备类型设置高度
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              // 固定宽度的图标区域，确保展开和收起时宽度一致
              SizedBox(
                width: 80.0,
                child: Center(
                  child: Icon(
                    item.icon,
                    color: isSelected ? context.theme.primaryColor : context.theme.iconTheme.color,
                    size: 24.0,
                  ),
                ),
              ),
              // 文字区域，收起时隐藏
              if (isExpanded)
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? context.theme.primaryColor : context.theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
