import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/library/components/library_app_bar.dart';
import 'package:tune/ui/library/widgets/library/components/library_search_bar.dart';
import 'package:tune/ui/library/widgets/library/components/library_scan_status.dart';
import 'package:tune/ui/library/widgets/library/library_categories_panel.dart';
import 'package:tune/ui/library/widgets/library/library_stats_panel.dart';
import 'package:tune/ui/library/widgets/library/song_grid_widget.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // 初始化时加载音乐库
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(libraryStateNotifierProvider.notifier);
      notifier.loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows || 
                     defaultTargetPlatform == TargetPlatform.macOS || 
                     defaultTargetPlatform == TargetPlatform.linux;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用栏组件（处理动态按钮）
            const LibraryAppBar(),

            // 搜索框
            LibrarySearchBar(
              controller: _searchController,
              onSearchChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // 扫描状态显示
            LibraryScanStatus(state: state),
            const SizedBox(height: 16),

            // 统计面板
            SizedBox(
              height: isDesktop ? 200 : 150,
              child: LibraryStatsPanel(songs: state.songs),
            ),
            const SizedBox(height: 16),

            // 分类面板
            SizedBox(
              height: 200,
              child: LibraryCategoriesPanel(songs: state.songs),
            ),

            const SizedBox(height: 16),

            // 歌曲列表标题
            if (state.songs.isNotEmpty) ...[
              Text(context.loc.songs,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8)
            ],

            // 歌曲网格列表 - 使用剩余空间
            Expanded(
              child: SongGridWidget(
                  songs: state.songs,
                  searchQuery: _searchQuery,
                  localizedNoSongsFound: context.loc.no_songs_found),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.updateSearchQuery(_searchQuery);
  }
}

class LibrarySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;

  const LibrarySearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: context.loc.search,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onSearchChanged('');
                },
              )
            : null,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
      ),
      onChanged: onSearchChanged,
    );
  }
}
