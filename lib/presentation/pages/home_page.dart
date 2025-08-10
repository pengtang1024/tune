import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/widgets/bottom_player_bar.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/get_all_songs.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:auto_route/auto_route.dart';

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
    _getAllSongs = DependencyInjection.get<GetAllSongs>();
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
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 添加一个欢迎标题
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.home_title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // 最近播放和推荐部分标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              localizations.song_list_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          // 显示歌曲列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? Center(
                        child: Text(
                          localizations.song_list_no_songs,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 4 / 5,
                          ),
                          itemCount: _songs.length > 4 ? 4 : _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            return _SongCard(
                              song: song,
                              onTap: () {
                                context
                                    .read<PlayerBloc>()
                                    .add(PlaySongEvent(song.id));
                                context.pushRoute(const PlayerRoute());
                              },
                            );
                          },
                        ),
                      ),
          ),
          // 查看全部歌曲按钮
          if (_songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // 这里可以导航到完整歌曲列表页面
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(localizations.song_list_title),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomPlayerBar(),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SongCard({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 专辑封面占位符
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 歌曲信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SongTitle(title: song.title),
                  const SizedBox(height: 4),
                  _SongArtist(artist: song.artist),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongTitle extends StatelessWidget {
  final String title;

  const _SongTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SongArtist extends StatelessWidget {
  final String artist;

  const _SongArtist({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Text(
      artist,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}