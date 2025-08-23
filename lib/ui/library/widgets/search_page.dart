import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
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
      _searchQuery = widget.initialQuery!;
      _searchController.text = _searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // 执行搜索
    if (query.isNotEmpty) {
      final notifier = ref.read(libraryStateNotifierProvider.notifier);
      notifier.searchSongs(query);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    
    // 清空搜索结果
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: localizations.search_songs,
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (_searchQuery.isNotEmpty) {
                  final notifier = ref.read(libraryStateNotifierProvider.notifier);
                  notifier.searchSongs(_searchQuery);
                }
              },
            ),
        ],
      ),
      body: const SearchResultsWidget(),
    );
  }

}