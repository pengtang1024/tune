import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_bloc.dart';
import 'package:tune/features/home/presentation/bloc/home_event.dart';
import 'package:tune/features/home/presentation/bloc/home_state.dart';
import 'package:tune/features/home/presentation/widgets/desktop/desktop_home_content.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/core/widgets/layout/responsive_layout.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PlayerBloc _playerBloc;
  late HomeBloc _homeBloc;
  List<Song> _localSongs = [];
  bool _isLoadingSongs = false;

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

  Future<void> _scanLocalSongs() async {
    setState(() {
      _isLoadingSongs = true;
    });

    try {
      final songs = await _playerBloc.getAllSongs();
      setState(() {
        _localSongs = songs;
        _isLoadingSongs = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.library_title}: ${songs.length} ${AppLocalizations.of(context)!.song_list_title}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingSongs = false;
      });

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
    final isDesktop = PlatformDetector.isDesktop;
    final useMobileLayout = PlatformDetector.shouldUseMobileLayout(context);

    return ResponsiveLayout(
      mobile: _buildMobileLayout(localizations, isDesktop, useMobileLayout),
      tablet: _buildTabletLayout(localizations, isDesktop, useMobileLayout),
      desktop: _buildDesktopLayout(localizations, isDesktop, useMobileLayout),
    );
  }

  Widget _buildMobileLayout(AppLocalizations localizations, bool isDesktop, bool useMobileLayout) {
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

              // 快捷功能标题
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.quick_actions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: _scanLocalSongs,
                    child: Text(localizations.library_title),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 快捷操作网格 - 使用更现代的设计
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 32) / 2;
                  return SizedBox(
                    height: cardWidth * 0.8, // 减少高度比例，从1.2降到0.8
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildModernQuickActionCard(
                          context,
                          icon: Icons.music_note,
                          title: localizations.library_title,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          onTap: () {
                            context.pushRoute(const LibraryRoute());
                          },
                        ),
                        _buildModernQuickActionCard(
                          context,
                          icon: Icons.favorite,
                          title: localizations.favorites,
                          color: Theme.of(context).colorScheme.errorContainer,
                          onTap: () {
                            // TODO: 导航到收藏页面
                          },
                        ),
                        _buildModernQuickActionCard(
                          context,
                          icon: Icons.playlist_play,
                          title: localizations.playlists,
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          onTap: () {
                            // TODO: 导航到播放列表页面
                          },
                        ),
                        _buildModernQuickActionCard(
                          context,
                          icon: Icons.history,
                          title: localizations.recently_played,
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          onTap: () {
                            // TODO: 导航到最近播放页面
                          },
                        ),
                        _buildModernQuickActionCard(
                          context,
                          icon: Icons.find_in_page,
                          title: localizations.scan_local_music,
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          onTap: () {
                            context.pushRoute(const MusicScanRoute());
                          },
                        ),
                      ],
                    ),
                  );
                }
              ),

              const SizedBox(height: 30),

              // 本地音乐列表
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.library_title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _scanLocalSongs,
                    child: _isLoadingSongs
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(localizations.library_title),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 本地音乐列表
              _buildModernSongsSection(),

              const SizedBox(height: 30),

              // 最近播放
              Text(
                localizations.recently_played,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 最近播放列表
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, homeState) {
                  return _buildModernRecentlyPlayedSection(homeState, localizations);
                },
              ),

              const SizedBox(height: 30),

              // 推荐内容
              Text(
                localizations.recommendations,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 推荐内容
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, homeState) {
                  return _buildModernRecommendationsSection(homeState, localizations);
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

  Widget _buildTabletLayout(AppLocalizations localizations, bool isDesktop, bool useMobileLayout) {
    return _buildDesktopLayout(localizations, isDesktop, useMobileLayout);
  }

  Widget _buildDesktopLayout(
      AppLocalizations localizations, bool isDesktop, bool useMobileLayout) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.home_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.pushRoute(const SettingsRoute());
            },
          ),
        ],
      ),
      body: const DesktopHomeContent(),
    );
  }

  Widget _buildQuickActionCard(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
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
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建现代化的快捷操作卡片
  Widget _buildModernQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  /// 构建现代化的歌曲列表部分
  Widget _buildModernSongsSection() {
    if (_isLoadingSongs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_localSongs.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.no_songs_found,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _localSongs.length,
        itemBuilder: (context, index) {
          final song = _localSongs[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernRecentlyPlayedSection(
      HomeState homeState, AppLocalizations localizations) {
    // 加载最近播放列表
    if (homeState is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeState is HomeLoaded) {
      if (homeState.recentlyPlayedSongs.isEmpty) {
        return Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(25), // 10% opacity
            ),
          ),
          child: Text(
            localizations.no_songs_found, // 使用已存在的本地化字符串
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      return SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: homeState.recentlyPlayedSongs.length,
          itemBuilder: (context, index) {
            final song = homeState.recentlyPlayedSongs[index];
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      size: 30,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      song.artist,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(75), // 30% opacity
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(25), // 10% opacity
        ),
      ),
      child: Text(
        localizations.no_songs_found, // 使用已存在的本地化字符串
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildModernRecommendationsSection(
      HomeState homeState, AppLocalizations localizations) {
    // 加载推荐内容
    if (homeState is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeState is HomeLoaded) {
      if (homeState.recommendedSongs.isEmpty) {
        return Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Text(
            localizations.no_songs_found, // 使用已存在的本地化字符串
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      return SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: homeState.recommendedSongs.length,
          itemBuilder: (context, index) {
            final song = homeState.recommendedSongs[index];
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.recommend,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      song.artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Text(
        localizations.no_songs_found, // 使用已存在的本地化字符串
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}