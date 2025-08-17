import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/widgets/tabs/about_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/account_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/animations_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/general_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/music_library_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/playback_tab.dart';

/// 设置页面组件
/// 提供应用设置功能，包括常规设置和音乐库设置
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '常规'),
              Tab(text: '音乐库'),
              Tab(text: '账号'),
              Tab(text: '播放'),
              Tab(text: '关于'),
              Tab(text: '动画'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                GeneralTab(),
                MusicLibraryTab(),
                AccountTab(),
                PlaybackTab(),
                AboutTab(),
                AnimationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 保留原有的TabView实现
class SettingsTabView extends ConsumerWidget {
  final int selectedTabIndex;

  const SettingsTabView({super.key, this.selectedTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      initialIndex: selectedTabIndex,
      length: 6, // 更新标签页数量
      child: Column(
        children: [
          // 标签页标题栏
          TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: '常规'),
              Tab(text: '音乐库'),
              Tab(text: '账号'),
              Tab(text: '播放'),
              Tab(text: '关于'),
              Tab(text: '动画'),
            ],
          ),
          // 标签页内容区域
          const Expanded(
            child: TabBarView(
              children: [
                GeneralTab(),
                MusicLibraryTab(),
                AccountTab(),
                PlaybackTab(),
                AboutTab(),
                AnimationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
