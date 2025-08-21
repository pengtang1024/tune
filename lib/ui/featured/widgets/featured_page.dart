import 'package:flutter/material.dart';

class FeaturedPage extends StatelessWidget {
  const FeaturedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.featured_play_list, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('精选内容', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('这里将展示精选的音乐内容', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
