import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';

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
            hintText: localizations.search, // 使用本地化字符串
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
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
      body: _buildSearchResults(state, localizations),
    );
  }

  Widget _buildSearchResults(LibraryState state, AppLocalizations localizations) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage?.isNotEmpty ?? false) {
      return Center(
        child: Text('${localizations.search_error}: ${state.errorMessage}'), // 使用本地化字符串
      );
    }

    final songs = state.searchResults;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.search_no_results, // 使用本地化字符串
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongListItem(song, localizations);
      },
    );
  }

  Widget _buildSongListItem(Song song, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.music_note, size: 30),
        ),
        title: Text(song.title),
        subtitle: Text(
          '${song.artist ?? localizations.unknown_artist} - ${song.album ?? localizations.unknown_album}',
        ),
        trailing: Text(
          Duration(milliseconds: song.duration).toString().split('.').first.padLeft(8, '0'),
        ),
        onTap: () {
          // TODO: 播放选中的歌曲
        },
      ),
    );
  }
}
