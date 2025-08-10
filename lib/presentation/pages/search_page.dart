import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/presentation/bloc/player/player_bloc.dart';
import 'package:tune/presentation/bloc/player/player_event.dart';
import 'package:tune/presentation/widgets/song_list.dart';
import 'package:tune/core/di/dependency_injection.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tune/core/routes/app_router.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/presentation/widgets/section_title.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchSongs _searchSongs;
  List<Song> _songs = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchSongs = DependencyInjection.get<SearchSongs>();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _searchSongs(query);
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search songs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final useMobileLayout = PlatformDetector.shouldUseMobileLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations.search_page_hint,
            border: InputBorder.none,
            hintStyle: _SearchHintStyle(context: context),
          ),
          style: _SearchTextStyle(context: context),
          onSubmitted: _performSearch,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _searchController.clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? localizations.search_page_empty
                        : localizations.search_page_no_results,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : useMobileLayout
                  ? _buildMobileLayout(localizations) // 移动端布局
                  : _buildDesktopLayout(localizations), // 桌面端布局
    );
  }

  Widget _buildMobileLayout(AppLocalizations localizations) {
    return SongList(
      songs: _songs,
      onSongSelected: (song) {
        context.read<PlayerBloc>().add(PlaySongEvent(song.id));
        context.pushRoute(const PlayerRoute());
      },
    );
  }

  Widget _buildDesktopLayout(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: localizations.search_title),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: PlatformDetector.getGridCrossAxisCount(context),
                crossAxisSpacing: PlatformDetector.getGridSpacing(context),
                mainAxisSpacing: PlatformDetector.getGridSpacing(context),
                childAspectRatio: PlatformDetector.getCardAspectRatio(context),
              ),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return _SearchResultCard(
                  song: song,
                  onTap: () {
                    context.read<PlayerBloc>().add(PlaySongEvent(song.id));
                    context.pushRoute(const PlayerRoute());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SearchResultCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
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
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHintStyle extends TextStyle {
  final BuildContext context;

  _SearchHintStyle({required this.context})
      : super(
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color
              ?.withValues(alpha: 0.7),
        );
}

class _SearchTextStyle extends TextStyle {
  final BuildContext context;

  _SearchTextStyle({required this.context})
      : super(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
}