import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/utils/device_utils.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/library/states/library_state_notifier.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/providers/app_bar_providers.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _displayedSearchQuery = ''; // 用于显示搜索结果的查询

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

  // 执行搜索的方法
  void _performSearch() {
    setState(() {
      _displayedSearchQuery = _searchQuery;
    });

    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.updateSearchQuery(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    // 添加扫描按钮到全局标题
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

    final state = ref.watch(libraryStateNotifierProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索框和搜索按钮
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.loc.search_songs,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                      _performSearch(); // 实时搜索
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            // 扫描进度条
            if (state.scanStatus == ScanStatus.scanning) ...[
              LinearProgressIndicator(value: state.scanProgress),
              const SizedBox(height: 8),
              Text('${(state.scanProgress * 100).toInt()}%'),
              const SizedBox(height: 16),
            ],

            // 错误信息
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) ...[
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],

            // 歌曲列表标题
            if (state.songs.isNotEmpty) ...[
              Text(
                context.loc.songs,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],

            // 歌曲网格列表
            Expanded(
              child: _buildSongGrid(state.songs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongGrid(List<Song> songs) {
    // 根据搜索查询过滤歌曲
    final filteredSongs = _searchQuery.isEmpty
        ? songs
        : songs.where((song) {
            // 搜索匹配：标题、艺术家或专辑
            return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                song.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                song.album.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    if (filteredSongs.isEmpty) {
      return Center(
        child: Text(context.loc.no_songs_found),
      );
    }

    // 计算列数（根据屏幕宽度动态调整）
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = (screenWidth / 250).floor().clamp(1, 10); // 增加最小宽度以适应新布局

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5, // 调整宽高比以适应新的更大卡片
          ),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return _buildSongCard(song);
          },
        );
      },
    );
  }

  Widget _buildSongCard(Song song) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // 点击歌曲卡片时的处理逻辑
          final notifier = ref.read(playerStateNotifierProvider.notifier);

          // 获取当前歌曲列表
          final libraryNotifier = ref.read(libraryStateNotifierProvider.notifier);
          final allSongs = libraryNotifier.state.songs;

          // 设置播放列表
          notifier.setPlaylist(allSongs, allSongs.indexWhere((s) => s.id == song.id));

          // 播放歌曲
          notifier.playSong(song);
        },
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 专辑封面占位符 (正方形，与卡片等高)
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 32,
                  color: Colors.grey[600],
                ),
              ),
              // 歌曲信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 歌曲标题和时长 (在同一行)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 时长
                          Text(
                            _formatDuration(song.duration),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 艺术家和专辑 (在同一行)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '${song.artist} · ${song.album}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 标签行 (显示歌曲的其他元信息标签)
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          // 年份标签
                          if (song.year != null && song.year != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.year.toString()!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          // 流派标签
                          if (song.genre != null && song.genre!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                song.genre!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          // 比特率标签
                          if (song.bitrate != null && song.bitrate != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${song.bitrate}kbps',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          // 采样率标签
                          if (song.sampleRate != null && song.sampleRate != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${song.sampleRate}Hz',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          // 音轨号标签
                          if (song.trackNumber != null && song.trackNumber != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${song.trackNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          // 光盘号标签
                          if (song.discNumber != null && song.discNumber != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Disc ${song.discNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                          // 文件大小标签
                          if (song.size != null && song.size != 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatFileSize(song.size!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          // 收藏标签
                          if (song.isFavorite)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '♥',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8), // 在标签下方添加间距
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化歌曲时长
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 构建通用标签组件
  Widget _buildTag({required String text, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }

}
