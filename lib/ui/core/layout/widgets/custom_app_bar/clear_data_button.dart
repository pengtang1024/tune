import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/utils/logger.dart';

class ClearDataButton extends ConsumerWidget {
  const ClearDataButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.cleaning_services),
      tooltip: '清理所有数据',
      onPressed: () async {
        try {
          final shouldClear = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('确认清理'),
              content: const Text('确定要清理所有应用数据吗？此操作将清除所有设置和扫描记录，但不会删除您的音乐文件。'),
              actions: [
                TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop(false)),
                TextButton(child: const Text('确定'), onPressed: () => Navigator.of(context).pop(true)),
              ],
            ),
          );

          if (shouldClear == true) {
            final persistenceService = ref.read(sharedPreferencesServiceProvider);
            await persistenceService.clear();
            final libraryNotifier = ref.read(libraryStateNotifierProvider.notifier);
            libraryNotifier.clearAllData();
            Log.info('All app data cleared');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('应用数据清理完成')),
              );
            }
          }
        } catch (e, stackTrace) {
          Log.error('Error clearing data: $e', stackTrace);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('数据清理失败')),
            );
          }
        }
      },
    );
  }
}
