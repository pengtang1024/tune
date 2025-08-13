import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
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

class _DesktopHomeContentState extends State<DesktopHomeContent>
    with SingleTickerProviderStateMixin {
  bool _isSidebarExpanded = true;
  int _selectedMenuItemIndex = 0; // 0: 首页, 1: 音乐库, 2: 收藏, 3: 播放列表, 4: 最近播放
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isSidebarExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Row(
      children: [
        // 侧边栏导航
        NavigationRail(
          extended: _isSidebarExpanded,
          selectedIndex: _selectedMenuItemIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedMenuItemIndex = index;
            });
            if (index == 1) {
              context.router.push(MusicLibraryRoute());
            }
          },
          labelType: _isSidebarExpanded
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.home),
              label: Text(localizations.home_title),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.music_note),
              label: Text(localizations.library_title),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.favorite),
              label: Text(localizations.favorites),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.playlist_play),
              label: Text(localizations.playlists),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.history),
              label: Text(localizations.recently_played),
            ),
          ],
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
                      // 根据选中的菜单项显示不同的内容
                      _buildContentByIndex(_selectedMenuItemIndex, context, localizations, homeState),
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

  Widget _buildContentByIndex(int index, BuildContext context, AppLocalizations localizations, HomeState homeState) {
    switch (index) {
      case 0: // 首页
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎信息
            Text(
              localizations.home_title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            RecommendationsSection(homeState: homeState, localizations: localizations),
            const SizedBox(height: 20), // 添加底部间距
          ],
        );
      case 1: // 音乐库
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.library_title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // TODO: 实现音乐库内容
            const Center(
              child: Text('音乐库内容'),
            ),
          ],
        );
      case 2: // 收藏
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.favorites,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // TODO: 实现收藏内容
            const Center(
              child: Text('收藏内容'),
            ),
          ],
        );
      case 3: // 播放列表
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.playlists,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // TODO: 实现播放列表内容
            const Center(
              child: Text('播放列表内容'),
            ),
          ],
        );
      case 4: // 最近播放
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.recently_played,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // TODO: 实现最近播放内容
            const Center(
              child: Text('最近播放内容'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
        horizontal: isExpanded ? 16.0 : 20.0, // 调整收起时的内边距使图标居中
        vertical: 8.0,
      ),
      horizontalTitleGap: 16.0, // 设置图标和文字之间的间距
      tileColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}