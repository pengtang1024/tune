import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/search_state.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? query;

  const SearchPage({super.key, this.query});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // 如果提供了查询参数，设置到控制器中
    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchController.text = widget.query!;
      // 延迟执行搜索，确保在构建完成后执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.query!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final searchNotifier = ref.read(searchStateNotifierProvider.notifier);
    searchNotifier.searchSongs(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateNotifierProvider);
    final searchNotifier = ref.read(searchStateNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索音乐...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              searchNotifier.updateQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    searchNotifier.updateQuery(value);
                  },
                  onSubmitted: (value) {
                    searchNotifier.searchSongs(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (searchState.query.isEmpty) ...[
            const Center(
              child: Text(
                '请输入关键词搜索音乐',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildSearchResults(searchState),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage.isNotEmpty) {
      return Center(
        child: Text('搜索出错: ${state.errorMessage}'),
      );
    }

    if (state.songs.isEmpty) {
      return const Center(
        child: Text(
          '未找到匹配的音乐',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.songs.length,
      itemBuilder: (context, index) {
        final song = state.songs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(Song song) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(song.title),
          subtitle: Text('${song.artist ?? '未知艺术家'} · ${song.album ?? '未知专辑'}'),
          trailing: Text(_formatDuration(song.duration)),
          onTap: () {
            // TODO: 实现播放功能
          },
        ),
      ),
    );
  }

  String _formatDuration(int durationInMilliseconds) {
    final duration = Duration(milliseconds: durationInMilliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}