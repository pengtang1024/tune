import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推荐页面组件
/// 显示推荐的音乐内容
class RecommendPage extends ConsumerWidget {
  const RecommendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recommend, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '推荐页面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '这里将显示推荐的音乐内容',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendSection extends StatelessWidget {
  final String title;
  final List<_RecommendItem> items;

  const _RecommendSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
}

class _RecommendItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const _RecommendItem({required this.title, required this.subtitle, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: imageUrl == null
              ? Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.album,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Image.network(
                  imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // 点击推荐项的逻辑：显示SnackBar提示
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('点击了推荐项: $title'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}
