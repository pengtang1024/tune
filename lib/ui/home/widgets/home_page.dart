import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/home/widgets/welcome_section.dart';
import 'package:tune/ui/home/widgets/quick_actions_section.dart';
import 'package:tune/ui/home/widgets/recent_section.dart';
import 'package:tune/ui/home/widgets/library_overview_section.dart';
import 'package:tune/ui/home/widgets/components/home_app_bar.dart';

/// 现代化的首页组件
/// 展示欢迎信息、快速操作和最近播放的音乐
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateNotifierProvider);

    return Scaffold(
      appBar: const HomeAppBar(),
      body: CustomScrollView(
        slivers: [
          // 内容部分
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎区域
                  WelcomeSection(playerState: playerState),
                  
                  const SizedBox(height: 24),
                  
                  // 快速操作
                  const QuickActionsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // 最近播放
                  const RecentSection(),
                  
                  const SizedBox(height: 24),
                  
                  // 我的音乐库概览
                  const LibraryOverviewSection(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}