import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/features/home/presentation/widgets/bottom_player_bar.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/di/injector.dart';
import 'package:tune/features/home/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/home/presentation/bloc/player/player_event.dart';
import 'package:tune/features/home/presentation/bloc/player/player_state.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/features/home/presentation/widgets/section_title.dart';
import 'package:tune/features/home/presentation/widgets/music/song_card.dart';
import 'package:tune/features/home/presentation/widgets/music/playlist_grid.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GetAllSongs _getAllSongs;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllSongs = Injector.get<GetAllSongs>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _getAllSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformDetector.isDesktop;
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.home_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  context.router.push(const SearchRoute());
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.router.push(const SettingsRoute());
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadSongs,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 最近播放
                            SectionTitle(
                              title: 'Recently Played', // 使用固定字符串，因为没有对应的本地化字符串
                              onSeeAll: () {
                                // TODO: 跳转到最近播放页面
                              },
                            ),
                            SizedBox(
                              height: 200,
                              child: _songs.isEmpty
                                  ? Center(
                                      child: Text('No recently played songs'), // 使用固定字符串
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _songs.length,
                                      itemBuilder: (context, index) {
                                        final song = _songs[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: SongCard(
                                            song: song,
                                            onTap: () {
                                              context
                                                  .read<PlayerBloc>()
                                                  .add(PlaySongEvent(song.id));
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 24),

                            // 推荐歌单
                            SectionTitle(
                              title: 'Recommended Playlists', // 使用固定字符串
                              onSeeAll: () {
                                // TODO: 跳转到推荐歌单页面
                              },
                            ),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3, // 示例数据
                                itemBuilder: (context, index) {
                                  return const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: PlaylistGrid(
                                      title: 'Recommended Playlist',
                                      subtitle: '50 songs',
                                      imageUrl:
                                          'https://via.placeholder.com/150',
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 我的歌单
                            SectionTitle(
                              title: 'My Playlists', // 使用固定字符串
                              onSeeAll: () {
                                // TODO: 跳转到我的歌单页面
                              },
                            ),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 2, // 示例数据
                                itemBuilder: (context, index) {
                                  return const Padding(
                                    padding: EdgeInsets.only(right: 12.0),
                                    child: PlaylistGrid(
                                      title: 'My Playlist',
                                      subtitle: '25 songs',
                                      imageUrl:
                                          'https://via.placeholder.com/150',
                                    ),
                                  );
                                },
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: isDesktop ? null : const BottomPlayerBar(),
        );
      },
    );
  }
}

/// 歌曲卡片组件
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
