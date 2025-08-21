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

  // 显示清空音乐库确认对话框
  void _showClearLibraryDialog(BuildContext context) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.confirm_clear_library),
          content: Text(context.loc.confirm_clear_library_message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.clearLibrary();
              },
              child: Text(context.loc.clear_library),
            ),
          ],
        );
      },
    );
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

    return PopScope(
      canPop: !state.isMultiSelectMode, // 在批量选择模式下阻止返回操作
      onPopInvoked: (bool didPop) {
        // 当用户按下返回键时，清除搜索状态或退出批量选择模式
        if (state.isMultiSelectMode) {
          // 退出批量选择模式
          final notifier = ref.read(libraryStateNotifierProvider.notifier);
          notifier.toggleMultiSelectMode();
        } else if (_searchQuery.isNotEmpty) {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
            _displayedSearchQuery = '';
          });
          final notifier = ref.read(libraryStateNotifierProvider.notifier);
          notifier.updateSearchQuery('');
        }
      },
      child: Scaffold(
        appBar: state.isMultiSelectMode 
          ? _buildMultiSelectAppBar(state) // 批量选择模式下的AppBar
          : _buildNormalAppBar(state), // 正常模式下的AppBar
        body: _buildBody(state),
      ),
    );
  }

  /// 构建正常模式下的AppBar
  AppBar _buildNormalAppBar(LibraryState state) {
    final isDesktop = DeviceUtils.isDesktop(context);
    
    return AppBar(
      title: Text(context.loc.library),
      actions: [
        // 搜索框 (移动端显示)
        if (!isDesktop)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _SongSearchDelegate(ref),
              );
            },
          ),
        // 搜索框 (桌面端显示)
        if (isDesktop)
          SizedBox(
            width: 300,
            child: TextField(
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
                            _displayedSearchQuery = '';
                          });
                          final notifier =
                              ref.read(libraryStateNotifierProvider.notifier);
                          notifier.updateSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // 实时搜索
                final notifier = ref.read(libraryStateNotifierProvider.notifier);
                notifier.updateSearchQuery(value);
              },
            ),
          ),
        // 管理菜单按钮
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String result) {
            switch (result) {
              case 'clear':
                _showClearLibraryDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'clear',
              child: Text(context.loc.clear_library),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建批量选择模式下的AppBar
  AppBar _buildMultiSelectAppBar(LibraryState state) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    final selectedCount = state.selectedSongs.length;
    final allSongs = state.songs; // 使用所有歌曲而不是搜索结果
    final isAllSelected = selectedCount == allSongs.length && selectedCount > 0;
    
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          notifier.toggleMultiSelectMode();
        },
      ),
      title: Text('$selectedCount 项已选择'),
      actions: [
        // 全选/取消全选按钮
        IconButton(
          icon: Icon(isAllSelected ? Icons.check_box : Icons.check_box_outline_blank),
          onPressed: () {
            if (isAllSelected) {
              notifier.deselectAllSongs();
            } else {
              notifier.selectAllSongs();
            }
          },
        ),
        // 批量操作菜单
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String result) {
            switch (result) {
              case 'favorite':
                notifier.toggleFavoriteForSelectedSongs();
                break;
              case 'delete':
                _showDeleteSelectedSongsDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'favorite',
              child: Text(state.selectedSongs.any((song) => song.isFavorite) 
                  ? context.loc.unfavorite 
                  : context.loc.favorite),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(context.loc.delete_song),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建页面主体内容
  Widget _buildBody(LibraryState state) {
    return Padding(
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
    );
  }

  /// 显示删除多首歌曲确认对话框
  void _showDeleteMultipleSongsDialog(BuildContext context) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    final state = ref.read(libraryStateNotifierProvider);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.confirm_delete_song),
          content: Text('${context.loc.confirm_delete_song_message}\n\n您确定要删除选中的 ${state.selectedSongs.length} 首歌曲吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.removeSelectedSongs();
              },
              child: Text(context.loc.delete_song),
            ),
          ],
        );
      },
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
    final state = ref.watch(libraryStateNotifierProvider);
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    final isSelected = state.selectedSongs.contains(song);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: state.isMultiSelectMode && isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (state.isMultiSelectMode) {
            // 在批量选择模式下，点击切换歌曲选择状态
            notifier.toggleSongSelection(song);
          } else {
            // 正常模式下，点击播放歌曲
            final playerNotifier = ref.read(playerStateNotifierProvider.notifier);
            playerNotifier.playSong(song);
          }
        },
        onLongPress: () {
          // 长按进入批量选择模式
          if (!state.isMultiSelectMode) {
            notifier.toggleMultiSelectMode();
            notifier.toggleSongSelection(song);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 批量选择模式下的复选框
                if (state.isMultiSelectMode)
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                      onPressed: () {
                        notifier.toggleSongSelection(song);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                // 专辑封面
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
                const SizedBox(width: 12),
                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 歌曲标题和时长
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 歌曲时长
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(song.duration),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 艺术家和专辑
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              song.artist,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              song.album,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                song.year.toString(),
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
                      const SizedBox(height: 8),
                      // 歌曲操作按钮 (仅在非批量选择模式下显示)
                      if (!state.isMultiSelectMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 收藏/取消收藏按钮
                            IconButton(
                              icon: Icon(
                                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: song.isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                notifier.toggleFavorite(song);
                              },
                              tooltip: song.isFavorite ? context.loc.unfavorite : context.loc.favorite,
                            ),
                            // 删除歌曲按钮
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteSongDialog(context, song),
                              tooltip: context.loc.delete_song,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
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

  // 显示删除歌曲确认对话框
  void _showDeleteSongDialog(BuildContext context, Song song) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.confirm_delete_song),
          content: Text('${context.loc.confirm_delete_song_message}\n\n"${song.title}"'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.removeSong(song);
              },
              child: Text(context.loc.delete_song),
            ),
          ],
        );
      },
    );
  }

  // 显示批量删除歌曲确认对话框
  void _showDeleteSelectedSongsDialog(BuildContext context) {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    final state = ref.read(libraryStateNotifierProvider);
    final selectedCount = state.selectedSongs.length;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.confirm_delete_song),
          content: Text('${context.loc.confirm_delete_song_message}\n\n您确定要删除选中的 $selectedCount 首歌曲吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.loc.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.removeSelectedSongs();
              },
              child: Text(context.loc.delete_song),
            ),
          ],
        );
      },
    );
  }

}

class _SongSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _SongSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);
    final filteredSongs = state.songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text('${song.artist} · ${song.album}'),
          onTap: () {
            close(context, song.title);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final state = ref.watch(libraryStateNotifierProvider);
    final filteredSongs = state.songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text('${song.artist} · ${song.album}'),
          onTap: () {
            close(context, song.title);
          },
        );
      },
    );
  }
}
