import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_state.dart';
import 'package:tune/features/home/presentation/widgets/sections/quick_actions_section.dart';
import 'package:tune/features/home/presentation/widgets/sections/songs_section.dart';
import 'package:tune/features/home/presentation/widgets/sections/recently_played_section.dart';
import 'package:tune/features/home/presentation/widgets/sections/recommendations_section.dart';
import 'package:tune/l10n/app_localizations.dart';

class DesktopHomeContent extends StatefulWidget {
  const DesktopHomeContent({super.key});

  @override
  State<DesktopHomeContent> createState() => _DesktopHomeContentState();
}

class _DesktopHomeContentState extends State<DesktopHomeContent> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        // 侧边栏导航
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSidebarExpanded ? 250 : 70,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // 顶部应用Logo区域
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Row(
                  mainAxisAlignment: _isSidebarExpanded 
                    ? MainAxisAlignment.start 
                    : MainAxisAlignment.center, // 收起时图标居中
                  children: [
                    if (_isSidebarExpanded) ...[
                      Text(
                        localizations.app_name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
              
              // 导航菜单项 - 移除外部的Expanded和ListView，直接使用列表
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavigationItem(
                      context,
                      icon: Icons.home,
                      title: localizations.home_title,
                      isSelected: true,
                      isExpanded: _isSidebarExpanded,
                    ),
                    _buildNavigationItem(
                      context,
                      icon: Icons.music_note,
                      title: localizations.library_title,
                      onTap: () {
                        context.pushRoute(const LibraryRoute());
                      },
                      isExpanded: _isSidebarExpanded,
                    ),
                    _buildNavigationItem(
                      context,
                      icon: Icons.favorite,
                      title: localizations.favorites,
                      onTap: () {
                        // TODO: 导航到收藏页面
                      },
                      isExpanded: _isSidebarExpanded,
                    ),
                    _buildNavigationItem(
                      context,
                      icon: Icons.playlist_play,
                      title: localizations.playlists,
                      onTap: () {
                        // TODO: 导航到播放列表页面
                      },
                      isExpanded: _isSidebarExpanded,
                    ),
                    _buildNavigationItem(
                      context,
                      icon: Icons.history,
                      title: localizations.recently_played,
                      onTap: () {
                        // TODO: 导航到最近播放页面
                      },
                      isExpanded: _isSidebarExpanded,
                    ),
                    
                    // 展开/收起按钮
                    ListTile(
                      leading: Icon(
                        _isSidebarExpanded 
                          ? Icons.arrow_back_ios_new 
                          : Icons.arrow_forward_ios,
                        size: 16.0,
                      ),
                      title: _isSidebarExpanded
                        ? const Text('Toggle Sidebar')
                        : null,
                      onTap: () {
                        setState(() {
                          _isSidebarExpanded = !_isSidebarExpanded;
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _isSidebarExpanded ? 16.0 : 22.0, // 调整收起时的内边距使图标居中
                        vertical: 8.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 主内容区域
        Expanded(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, homeState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 欢迎信息
                      Text(
                        localizations.home_title,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 20),

                      // 快捷功能
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.quick_actions,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: 实现扫描本地歌曲功能
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(localizations.library_title),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 快捷操作网格
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: QuickActionsSection(),
                      ),

                      const SizedBox(height: 20),

                      // 本地音乐列表
                      const SongsSection(),

                      const SizedBox(height: 20),

                      // 最近播放
                      Text(
                        localizations.recently_played,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 12),
                      RecentlyPlayedSection(homeState: homeState, localizations: localizations),

                      const SizedBox(height: 20),

                      // 推荐内容
                      Text(
                        localizations.recommendations,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 12),
                      RecommendationsSection(homeState: homeState, localizations: localizations),
                      const SizedBox(height: 20), // 添加底部间距
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isSelected = false,
    required bool isExpanded,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: isExpanded 
        ? Text(title) 
        : null, // 当侧边栏收缩时隐藏标题
      selected: isSelected,
      selectedTileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // 移除圆角
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 16.0 : 22.0, // 调整收起时的内边距使图标居中
        vertical: 8.0,
      ),
      horizontalTitleGap: 16.0, // 设置图标和文字之间的间距
      tileColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}