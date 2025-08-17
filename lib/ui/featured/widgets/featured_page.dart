import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 精选页面组件
/// 显示精选的音乐内容
class FeaturedPage extends ConsumerWidget {
  const FeaturedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '精选页面',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '这里将显示精选的音乐内容',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ArtistItem extends StatelessWidget {
  final String name;
  final String genre;

  const _ArtistItem({
    required this.name,
    required this.genre,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(name),
          subtitle: Text(genre),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}

class _AlbumItem extends StatelessWidget {
  final String title;
  final String artist;

  const _AlbumItem({
    required this.title,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.album,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(title),
          subtitle: Text(artist),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}

class _PlaylistItem extends StatelessWidget {
  final String title;
  final int songCount;

  const _PlaylistItem({
    required this.title,
    required this.songCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.queue_music,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(title),
          subtitle: Text('$songCount 首歌曲'),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
