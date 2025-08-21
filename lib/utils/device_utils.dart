import 'package:flutter/material.dart';
import '../../core/constants/device_constants.dart';

/// 设备类型枚举
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// 设备工具类
class DeviceUtils {
  /// 根据屏幕宽度判断设备类型
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < DeviceConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < DeviceConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 检查是否为移动设备
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// 检查是否为平板设备
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// 检查是否为桌面设备
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// 获取适合当前设备的侧边栏宽度
  static double getSidebarWidth(BuildContext context, [bool isExpanded = true]) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return isExpanded ? DeviceConstants.mobileSidebarExpandedWidth : DeviceConstants.mobileSidebarCollapsedWidth;
      case DeviceType.tablet:
        return isExpanded ? DeviceConstants.mobileSidebarExpandedWidth : DeviceConstants.mobileSidebarCollapsedWidth;
      case DeviceType.desktop:
        // PC端优化：展开时180px，收起时60px
        return isExpanded ? DeviceConstants.desktopSidebarExpandedWidth : DeviceConstants.desktopSidebarCollapsedWidth;
    }
  }

  /// 获取适合当前设备的AppBar高度
  static double getAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return kToolbarHeight; // 使用默认高度
      case DeviceType.desktop:
        return DeviceConstants.desktopAppBarHeight; // PC端高度缩减至60px
    }
  }

  /// 获取适合当前设备的填充大小
  static double getPadding(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return DeviceConstants.mobilePadding;
      case DeviceType.tablet:
        return DeviceConstants.tabletPadding;
      case DeviceType.desktop:
        return DeviceConstants.desktopPadding; // PC端减小填充，提高信息密度
    }
  }

  /// 获取适合当前设备的图标大小
  static double getIconSize(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return DeviceConstants.mobileIconSize;
      case DeviceType.tablet:
        return DeviceConstants.tabletIconSize;
      case DeviceType.desktop:
        return DeviceConstants.desktopIconSize; // PC端减小图标大小
    }
  }

  /// 获取适合当前设备的字体大小
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return baseSize;
      case DeviceType.tablet:
        return baseSize * 1.1;
      case DeviceType.desktop:
        return baseSize * 0.9; // PC端适当减小字体
    }
  }

  /// 获取适合当前设备的间距
  static double getSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return DeviceConstants.mobilePadding;
      case DeviceType.tablet:
        return DeviceConstants.tabletPadding;
      case DeviceType.desktop:
        return DeviceConstants.desktopPadding; // PC端减小间距
    }
  }

  /// 获取适合当前设备的菜单项高度
  static double getMenuItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return DeviceConstants.mobileMenuItemHeight;
      case DeviceType.desktop:
        return DeviceConstants.desktopMenuItemHeight; // PC端减小菜单项高度
    }
  }

  /// 获取适合当前设备的菜单项间距
  static double getMenuItemSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return DeviceConstants.mobileMenuItemSpacing;
      case DeviceType.desktop:
        return DeviceConstants.desktopMenuItemSpacing; // PC端减小间距
    }
  }

  /// 获取适合当前设备的列表项高度
  static double getListItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return DeviceConstants.mobileListItemHeight;
      case DeviceType.tablet:
        return DeviceConstants.tabletListItemHeight;
      case DeviceType.desktop:
        return DeviceConstants.desktopListItemHeight; // PC端减小列表项高度
    }
  }

  /// 获取适合当前设备的按钮最小尺寸
  static Size getButtonMinSize(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return Size(DeviceConstants.mobileButtonMinWidth, DeviceConstants.mobileButtonMinHeight);
      case DeviceType.tablet:
        return Size(DeviceConstants.tabletButtonMinWidth, DeviceConstants.tabletButtonMinHeight);
      case DeviceType.desktop:
        return Size(DeviceConstants.desktopButtonMinWidth, DeviceConstants.desktopButtonMinHeight); // PC端减小按钮尺寸
    }
  }

  /// 获取适合当前设备的网格列数
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    final width = MediaQuery.of(context).size.width;

    switch (deviceType) {
      case DeviceType.mobile:
        return DeviceConstants.mobileGridColumns;
      case DeviceType.tablet:
        return DeviceConstants.tabletGridColumns;
      case DeviceType.desktop:
        // 根据屏幕宽度动态计算列数
        if (width > DeviceConstants.desktopGridBreakpointLarge) {
          return DeviceConstants.desktopGridColumnsExtraLarge;
        } else if (width > DeviceConstants.desktopGridBreakpointMedium) {
          return DeviceConstants.desktopGridColumnsLarge;
        } else if (width > DeviceConstants.desktopGridBreakpointSmall) {
          return DeviceConstants.desktopGridColumnsMedium;
        } else {
          return DeviceConstants.desktopGridColumnsSmall;
        }
    }
  }
}
