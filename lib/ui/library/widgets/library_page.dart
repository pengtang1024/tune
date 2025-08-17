import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/theme_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/core/layout/providers/app_bar_providers.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/widgets/music_card_widget.dart';
import 'package:tune/utils/device_utils.dart';

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '我的音乐',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/music-scan');
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('扫描音乐'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            const Text(
              '最近添加',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildSongList(),
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
        hintText: '搜索音乐...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      onSubmitted: (value) {
        // TODO: 实现搜索功能
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
    final songsAsync = ref.watch(songsProvider);
    
    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('音乐库为空，请点击"扫描音乐"按钮添加音乐'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('加载音乐库失败'),
            const SizedBox(height: 8),
            Text(error.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(songsProvider),
              child: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song) {
    final iconSize = DeviceUtils.getIconSize(context);
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: iconSize * 2,
            height: iconSize * 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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