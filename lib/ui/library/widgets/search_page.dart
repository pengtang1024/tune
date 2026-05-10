import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/library/search_results_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

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
    setState(() => _searchQuery = query);
    if (query.isNotEmpty) {
      ref.read(libraryStateNotifierProvider.notifier).searchSongs(query);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    ref.read(libraryStateNotifierProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: ModernCard(
          padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12),
          child: TextField(
            autofocus: true,
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: context.loc.search_songs,
              hintStyle: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: AppDesignSystem.neutral400),
              border: InputBorder.none,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: AppDesignSystem.iconSize20), onPressed: _clearSearch)
                  : null,
            ),
          ),
        ),
      ),
      body: const SearchResultsWidget(),
    );
  }
}
