import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/extension/router_extension.dart';
import 'package:tune/providers/theme_providers.dart';
import 'package:tune/providers/localization_providers.dart';
import 'package:tune/providers/router_providers.dart'; // 添加路由提供者
import 'package:tune/ui/home/providers/home_providers.dart';
import 'package:tune/ui/core/layout/widgets/desktop_layout.dart';
import 'package:tune/ui/core/layout/widgets/mobile_layout.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/ui/home/widgets/home_page.dart';
import 'package:tune/ui/recommend/widgets/recommend_page.dart';
import 'package:tune/ui/featured/widgets/featured_page.dart';
import 'package:tune/ui/library/widgets/library_page.dart';
import 'package:tune/ui/core/settings/widgets/settings_page.dart';

class ScreenLayout extends ConsumerWidget {
  final Widget child;

  const ScreenLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 页面加载时自动加载歌曲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(homeViewModelProvider.notifier);
      viewModel.loadSongs();
    });

    return ScreenContentLayout(child: child);
  }
}

class ScreenContentLayout extends ConsumerWidget {
  final Widget child;

  const ScreenContentLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    // 监听当前主题模式
    final currentThemeMode = ref.watch(themeModeProvider);
    // 监听当前语言环境
    final currentLocale = ref.watch(localeProvider);

    // 根据屏幕宽度判断是手机还是桌面布局
    final isDesktop = MediaQuery.of(context).size.width > 600;

    // 根据路由路径设置标题
    final currentRoutePath = GoRouterState.of(context).uri.toString();
    String appBarTitle = _getAppBarTitle(context, currentRoutePath);

    final content = Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // 语言切换按钮
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageSelector(context, ref),
            tooltip: '切换语言',
          ),
          // 主题切换按钮
          IconButton(
            icon: _getThemeIcon(currentThemeMode),
            onPressed: () => _switchThemeMode(ref, currentThemeMode),
            tooltip: _getThemeTooltip(currentThemeMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 导航到设置页面
              context.go('/settings');
            },
            tooltip: '设置',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    // 根据设备类型返回不同的布局
    if (isDesktop) {
      return DesktopLayout(child: content);
    } else {
      return MobileLayout(child: content);
    }
  }

  String _getAppBarTitle(BuildContext context, String routePath) {
    // 根据路由路径设置标题
    switch (routePath) {
      case '/':
        return context.loc.home;
      case '/settings':
        return context.loc.settings;
      case '/about':
        return context.loc.about;
      case '/recommend':
        return context.loc.recommend;
      case '/search':
        return context.loc.search;
      case '/library':
        return context.loc.library;
      case '/featured':
        return context.loc.featured;
      case '/player':
        return context.loc.player;
      case '/playlist':
        return context.loc.playlist;
      default:
        return context.loc.app_name;
    }
  }

  /// 根据当前主题模式获取对应的图标
  Widget _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return const Icon(Icons.light_mode);
      case ThemeMode.dark:
        return const Icon(Icons.dark_mode);
      case ThemeMode.system:
        return const Icon(Icons.auto_mode);
    }
  }

  /// 根据当前主题模式获取提示文本
  String _getThemeTooltip(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '切换到深色模式';
      case ThemeMode.dark:
        return '切换到系统默认';
      case ThemeMode.system:
        return '切换到浅色模式';
    }
  }

  /// 切换主题模式
  void _switchThemeMode(WidgetRef ref, ThemeMode currentThemeMode) {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    // 循环切换主题模式: system -> light -> dark -> system
    switch (currentThemeMode) {
      case ThemeMode.system:
        themeNotifier.updateThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        themeNotifier.updateThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        themeNotifier.updateThemeMode(ThemeMode.system);
        break;
    }
  }

  /// 显示语言选择对话框
  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider).languageCode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择语言'),
          children: [
            _buildLanguageOption(context, ref, 'English', 'en', currentLocale),
            _buildLanguageOption(context, ref, '中文', 'zh', currentLocale),
          ],
        );
      },
    );
  }

  /// 构建语言选项
  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String name, String code, String currentCode) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        // 更新语言环境
        ref.read(localeProvider.notifier).updateLocale(Locale(code));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          if (currentCode == code)
            const Icon(Icons.check, color: Colors.blue),
        ],
      ),
    );
  }
}

class RouterContent extends StatelessWidget {
  const RouterContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Placeholder(), // 暂时使用Placeholder，实际项目中应该使用具体的路由组件
    );
  }
}
