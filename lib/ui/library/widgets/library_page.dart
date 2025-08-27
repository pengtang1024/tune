import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/route_observer_provider.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
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
    // 监听路由变化，在进入音乐库页面时添加扫描按钮
    ref.listen<RouteObserverState>(routeObserverProvider, (previous, next) {
      if (next.route == '/library') {
        // 延迟执行以确保在widget构建完成后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
          appBarNotifier.clearDynamicActions(); // 清除之前的动态按钮

          final libraryState = ref.read(libraryStateNotifierProvider);
          appBarNotifier.addDynamicAction(
            IconButton(
              icon: const Icon(Icons.music_note),
              onPressed: libraryState.scanStatus == ScanStatus.scanning
                  ? null
                  : () {
                      context.push('/music-scan');
                    },
              tooltip: context.loc.scan_local_music,
            ),
          );
        });
      } else {
        // 当页面被移除时清除动态按钮
        final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
        appBarNotifier.clearDynamicActions();
      }
    });

    final state = ref.watch(libraryStateNotifierProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索框
            _buildSearchBar(),
            const SizedBox(height: 16),

            // 扫描状态显示
            _buildScanStatusDisplay(state),

            // 歌曲列表标题
            if (state.songs.isNotEmpty) ...[Text(context.loc.songs, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8)],

            // 歌曲网格列表
            Expanded(
              child: SongGridWidget(songs: state.songs, searchQuery: _searchQuery, localizedNoSongsFound: context.loc.no_songs_found),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.loc.search,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  _performSearch();
                },
              )
            : null,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
        _performSearch();
      },
    );
  }

  Widget _buildScanStatusDisplay(LibraryState state) {
    if (state.scanStatus == ScanStatus.idle || state.scanStatus == ScanStatus.completed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(color: state.scanStatus == ScanStatus.error ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.0)),
      child: Row(
        children: [
          if (state.scanStatus == ScanStatus.scanning) ...[const CircularProgressIndicator(), const SizedBox(width: 12)] else if (state.scanStatus == ScanStatus.error) ...[const Icon(Icons.error, color: Colors.red), const SizedBox(width: 12)],
          Expanded(
            child: Text(state.statusMessage, style: TextStyle(color: state.scanStatus == ScanStatus.error ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color)),
          ),
        ],
      ),
    );
  }

  // 执行搜索的方法
  void _performSearch() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.updateSearchQuery(_searchQuery);
  }
}