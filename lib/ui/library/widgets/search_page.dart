import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/library/search_results_widget.dart';
import 'package:tune/ui/player/providers/player_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.updateSearchQuery(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);
    final localizations = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations.search,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha:0.7),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _performSearch();
          },
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _performSearch();
              },
            ),
        ],
      ),
      body: SearchResultsWidget(
        state: state,
        localizations: localizations,
        onPlaySong: _playSong,
      ),
    );
  }

  void _playSong(Song song) {
    // 播放选中的歌曲
    final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
    final libraryState = ref.read(libraryStateNotifierProvider);
    
    // 设置播放列表
    playerNotifier.setPlaylist(libraryState.songs, libraryState.songs.indexWhere((s) => s.id == song.id));
    
    // 播放歌曲
    playerNotifier.playSong(song);
  }
}