import 'package:flutter/material.dart';

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
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1024) {
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
        return isExpanded ? 250.0 : 80.0;
      case DeviceType.tablet:
        return isExpanded ? 250.0 : 80.0;
      case DeviceType.desktop:
        // PC端优化：展开时180px，收起时60px
        return isExpanded ? 180.0 : 60.0;
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
        return 60.0; // PC端高度缩减至60px
    }
  }

  /// 获取适合当前设备的填充大小
  static double getPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 24.0;
      case DeviceType.desktop:
        return 12.0; // PC端减小填充，提高信息密度
    }
  }

  /// 获取适合当前设备的图标大小
  static double getIconSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 28.0;
      case DeviceType.desktop:
        return 20.0; // PC端减小图标大小
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
        return 16.0;
      case DeviceType.tablet:
        return 20.0;
      case DeviceType.desktop:
        return 12.0; // PC端减小间距
    }
  }

  /// 获取适合当前设备的菜单项高度
  static double getMenuItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return 48.0;
      case DeviceType.desktop:
        return 40.0; // PC端减小菜单项高度
    }
  }

  /// 获取适合当前设备的菜单项间距
  static double getMenuItemSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return 8.0;
      case DeviceType.desktop:
        return 6.0; // PC端减小间距
    }
  }

  /// 获取适合当前设备的列表项高度
  static double getListItemHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 72.0;
      case DeviceType.tablet:
        return 80.0;
      case DeviceType.desktop:
        return 60.0; // PC端减小列表项高度
    }
  }

  /// 获取适合当前设备的按钮最小尺寸
  static Size getButtonMinSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const Size(48.0, 48.0);
      case DeviceType.tablet:
        return const Size(52.0, 52.0);
      case DeviceType.desktop:
        return const Size(40.0, 40.0); // PC端减小按钮尺寸
    }
  }

  /// 获取适合当前设备的网格列数
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    final width = MediaQuery.of(context).size.width;
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        // 根据屏幕宽度动态计算列数
        if (width > 1600) {
          return 6;
        } else if (width > 1400) {
          return 5;
        } else if (width > 1200) {
          return 4;
        } else {
          return 3;
        }
    }
  }
}