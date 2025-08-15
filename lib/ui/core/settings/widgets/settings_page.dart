import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/settings/providers/settings_providers.dart';
import 'package:tune/ui/core/settings/widgets/tabs/account_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/general_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/music_library_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/playback_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/about_tab.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsTabView();
  }
}

class SettingsTabView extends ConsumerWidget {
  const SettingsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SettingsTabBarView(),
    );
  }
}

class SettingsTabBarView extends ConsumerWidget {
  const SettingsTabBarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5, // 更新标签页数量
      child: Column(
        children: [
          // 标签页标题栏
          TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: '账号'),
              Tab(text: '常规'),
              Tab(text: '音乐库'),
              Tab(text: '播放'),
              Tab(text: '关于'),
            ],
          ),
          // 标签页内容区域
          const Expanded(
            child: TabBarView(
              children: [
                AccountTab(),
                GeneralTab(),
                MusicLibraryTab(),
                PlaybackTab(),
                AboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
