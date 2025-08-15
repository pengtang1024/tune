import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/search_page.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '音乐库',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // 刷新音乐库
                  ref.refresh(songsProvider);
                },
                tooltip: '刷新音乐库',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.push('/music-scan'),
                icon: const Icon(Icons.search),
                label: const Text('扫描音乐'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildLibraryStats(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSongList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索音乐...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      onChanged: (value) {
        setState(() {});
      },
      onSubmitted: (value) {
        // 跳转到搜索页面并传递搜索查询
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchPage(query: value),
          ),
        );
      },
      onTap: () {
        // 点击搜索框时跳转到搜索页面
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchPage(query: _searchController.text),
          ),
        );
      },
    );
  }

  Widget _buildLibraryStats() {
    final songsAsync = ref.watch(songsProvider);

    return songsAsync.when(
      data: (songs) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.music_note, songs.length.toString(), '歌曲'),
                _buildStatItem(
                  Icons.person,
                  songs
                      .map((song) => song.artist)
                      .where((artist) => artist != null)
                      .toSet()
                      .length
                      .toString(),
                  '艺术家',
                ),
                _buildStatItem(
                  Icons.album,
                  songs
                      .map((song) => song.album)
                      .where((album) => album != null)
                      .toSet()
                      .length
                      .toString(),
                  '专辑',
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text('加载统计信息时出错: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSongList() {
    final query = _searchController.text.trim();

    // 如果有搜索查询，使用搜索提供者，否则使用所有歌曲提供者
    final songsAsync = query.isEmpty
        ? ref.watch(songsProvider)
        : ref.watch(searchSongsProvider(query));

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '音乐库为空\n请添加一些音乐文件',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/music-scan'),
                  icon: const Icon(Icons.search),
                  label: const Text('扫描音乐'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _buildSongItem(song);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('加载音乐时出错: $error'),
      ),
    );
  }

  Widget _buildSongItem(Song song) {
    return Card(
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
    );
  }

  String _formatDuration(int durationInMilliseconds) {
    final duration = Duration(milliseconds: durationInMilliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
