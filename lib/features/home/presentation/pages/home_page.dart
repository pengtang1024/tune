import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_event.dart';
import 'package:tune/features/home/presentation/bloc/home_state.dart';
import 'package:tune/l10n/app_localizations.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PlayerBloc _playerBloc;
  late HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    // 初始化播放器Bloc
    _playerBloc = context.read<PlayerBloc>();
    _homeBloc = context.read<HomeBloc>();

    // 加载首页数据
    _homeBloc.add(LoadHomeData());

    // 加载歌曲列表
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      await _playerBloc.getAllSongs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failed_to_load_songs),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.home_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.pushRoute(const SearchRoute());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.pushRoute(const SettingsRoute());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎信息
              Text(
                localizations.home_title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // 快捷功能
              Text(
                localizations.quick_actions,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              // 快捷操作网格
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.music_note,
                    title: localizations.library_title,
                    onTap: () {
                      context.pushRoute(const LibraryRoute());
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.favorite,
                    title: localizations.favorites,
                    onTap: () {
                      // TODO: 导航到收藏页面
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.playlist_play,
                    title: localizations.playlists,
                    onTap: () {
                      // TODO: 导航到播放列表页面
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.history,
                    title: localizations.recently_played,
                    onTap: () {
                      // TODO: 导航到最近播放页面
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 最近播放
              Text(
                localizations.recently_played,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              // 最近播放列表
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, homeState) {
                  return _buildRecentlyPlayedSection(homeState, localizations);
                },
              ),

              const SizedBox(height: 30),

              // 推荐内容
              Text(
                localizations.recommendations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),

              // 推荐内容
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, homeState) {
                  return _buildRecommendationsSection(homeState, localizations);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushRoute(const MusicPlayerRoute());
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  /// 构建最近播放部分
  Widget _buildRecentlyPlayedSection(HomeState homeState, AppLocalizations localizations) {
    if (homeState is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeState is HomeLoaded) {
      if (homeState.recentlyPlayedSongs.isEmpty) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            localizations.no_recent_songs,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: homeState.recentlyPlayedSongs.length,
          itemBuilder: (context, index) {
            final song = homeState.recentlyPlayedSongs[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // 错误或初始状态
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        localizations.no_recent_songs,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// 构建推荐内容部分
  Widget _buildRecommendationsSection(HomeState homeState, AppLocalizations localizations) {
    if (homeState is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeState is HomeLoaded) {
      if (homeState.recommendedSongs.isEmpty) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            localizations.no_recommendations,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: homeState.recommendedSongs.length,
          itemBuilder: (context, index) {
            final song = homeState.recommendedSongs[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // 错误或初始状态
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        localizations.no_recommendations,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// 构建快捷操作卡片
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
