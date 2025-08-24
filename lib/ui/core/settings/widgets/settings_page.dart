import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/widgets/tabs/about_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/account_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/animations_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/equalizer_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/general_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/music_library_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/playback_tab.dart';

/// 设置页面组件
/// 提供应用设置功能，包括常规设置和音乐库设置
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsTabView();
  }
}

// 保留原有的TabView实现
class SettingsTabView extends ConsumerWidget {
  final int selectedTabIndex;

  const SettingsTabView({super.key, this.selectedTabIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DefaultTabController(
        initialIndex: selectedTabIndex,
        length: 7, // 更新标签页数量
        child: Column(
          children: [
            // 标签页标题栏
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: context.loc.general_tab),
                Tab(text: context.loc.library_tab),
                Tab(text: context.loc.account_tab),
                Tab(text: context.loc.playback_tab),
                Tab(text: context.loc.equalizer_tab),
                Tab(text: context.loc.about_tab),
                Tab(text: context.loc.animations_tab),
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
                  EqualizerTab(),
                  AboutTab(),
                  AnimationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}