import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/theme_providers.dart';
import 'package:tune/providers/localization_providers.dart';
import 'package:tune/providers/router_providers.dart'; // 添加路由提供者
import 'package:tune/ui/home/providers/home_providers.dart';
import 'package:tune/ui/home/widgets/desktop_home_layout.dart';
import 'package:tune/ui/home/widgets/mobile_home_layout.dart';
import 'package:tune/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;
  
  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 页面加载时自动加载歌曲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(homeViewModelProvider.notifier);
      viewModel.loadSongs();
    });

    return HomeScreenContent(child: child);
  }
}

class HomeScreenContent extends ConsumerWidget {
  final Widget child;
  
  const HomeScreenContent({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    // 监听当前主题模式
    final currentThemeMode = ref.watch(themeModeProvider);
    // 监听当前语言环境
    final currentLocale = ref.watch(localeProvider);
    // 监听路由状态
    final routerState = ref.watch(routerProvider);

    // 根据屏幕宽度判断是手机还是桌面布局
    final isDesktop = MediaQuery.of(context).size.width > 600;

    // 根据路由名称和本地化文件确定标题
    final currentRoute = GoRouterState.of(context).uri.toString();
    final localizations = AppLocalizations.of(context);
    
    // 更新路由状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (routerState.selectedMenuItem != currentRoute) {
        ref.read(routerProvider.notifier).updateSelectedMenuItem(currentRoute);
      }
    });
    
    String appBarTitle = localizations?.app_name ?? 'Tune'; // 默认标题
    
    // 根据路由名称确定标题
    if (currentRoute == '/') {
      appBarTitle = localizations?.home ?? 'Home';
    } else if (currentRoute.contains('recommend')) {
      appBarTitle = localizations?.recommend ?? 'Recommend';
    } else if (currentRoute.contains('featured')) {
      appBarTitle = localizations?.featured ?? 'Featured';
    } else if (currentRoute.contains('library')) {
      appBarTitle = localizations?.library ?? 'Library';
    } else if (currentRoute.contains('settings')) {
      appBarTitle = localizations?.settings ?? 'Settings';
    }
    // 对于其他路由，可以添加更多条件或保持默认标题

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
              context.push('/settings');
              ref.read(routerProvider.notifier).updateSelectedMenuItem('/settings');
            },
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
      return DesktopHomeLayout(child: content);
    } else {
      return MobileHomeLayout(child: content);
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