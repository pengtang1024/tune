import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/features/home/presentation/bloc/music_library/music_library_bloc.dart';
import 'package:tune/features/home/presentation/widgets/music_library/music_library_list.dart';
import 'package:tune/features/home/presentation/widgets/music_library/music_library_grid.dart';
import 'package:tune/l10n/app_localizations.dart';

@RoutePage()
class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  late MusicLibraryBloc _musicLibraryBloc;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _musicLibraryBloc = context.read<MusicLibraryBloc>();
    _musicLibraryBloc.add(LoadMusicLibrary());
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _musicLibraryBloc.add(SearchSongsEvent(query));
    });
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      _musicLibraryBloc.add(SortSongs(value));
    }
  }

  void _onGroupChanged(String? value) {
    if (value != null) {
      _musicLibraryBloc.add(GroupSongs(value));
    }
  }

  void _onRefresh() {
    _musicLibraryBloc.add(RefreshLibrary());
  }

  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int secs = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.library_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _onSortChanged,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'title',
                  child: Text(localizations.sort_by_title),
                ),
                PopupMenuItem(
                  value: 'artist',
                  child: Text(localizations.sort_by_artist),
                ),
                PopupMenuItem(
                  value: 'album',
                  child: Text(localizations.sort_by_album),
                ),
                PopupMenuItem(
                  value: 'dateAdded',
                  child: Text(localizations.sort_by_date_added),
                ),
                PopupMenuItem(
                  value: 'duration',
                  child: Text(localizations.sort_by_duration),
                ),
              ];
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.group),
            onSelected: _onGroupChanged,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'none',
                  child: Text(localizations.group_by_none),
                ),
                PopupMenuItem(
                  value: 'artist',
                  child: Text(localizations.library_artists),
                ),
                PopupMenuItem(
                  value: 'album',
                  child: Text(localizations.library_albums),
                ),
                PopupMenuItem(
                  value: 'genre',
                  child: Text(localizations.library_genres),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: localizations.search_songs,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: BlocBuilder<MusicLibraryBloc, MusicLibraryState>(
              builder: (context, state) {
                if (state is MusicLibraryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MusicLibraryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _onRefresh,
                          child: Text(localizations.try_again),
                        ),
                      ],
                    ),
                  );
                } else if (state is MusicLibraryLoaded) {
                  // 显示统计信息
                  final int songCount = state.songs.length;
                  final int totalDuration = state.songs.fold(0, (sum, song) => sum + song.duration);
                  
                  return Column(
                    children: [
                      if (_searchQuery.isEmpty) // 只在非搜索状态下显示统计信息
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$songCount ${localizations.song_list_title.toLowerCase()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                _formatDuration(totalDuration),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _isGridView 
                          ? MusicLibraryGrid(
                              songs: state.songs,
                              groupedSongs: state.groupedSongs,
                              groupBy: state.groupBy,
                            )
                          : MusicLibraryList(
                              songs: state.songs,
                              groupedSongs: state.groupedSongs,
                              groupBy: state.groupBy,
                            ),
                      ),
                    ],
                  );
                } else if (state is MusicLibrarySearchResult) {
                  // 显示搜索结果统计
                  final int resultCount = state.songs.length;
                  
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '${localizations.search_songs}: $resultCount ${localizations.song_list_title.toLowerCase()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _isGridView 
                          ? MusicLibraryGrid(
                              songs: state.songs,
                              groupedSongs: state.groupedSongs,
                              groupBy: state.groupBy,
                            )
                          : MusicLibraryList(
                              songs: state.songs,
                              groupedSongs: state.groupedSongs,
                              groupBy: state.groupBy,
                            ),
                      ),
                    ],
                  );
                }
                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),
    );
  }
}