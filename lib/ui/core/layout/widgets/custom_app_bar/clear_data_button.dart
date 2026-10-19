import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/utils/logger.dart';

class ClearDataButton extends ConsumerWidget {
  const ClearDataButton({super.key});

  /// 显示清理数据确认对话框（可被外部调用）
  static Future<void> showClearDialog(BuildContext context, WidgetRef ref) async {
    try {
      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(context.loc.clear_data_confirm),
          content: Text(context.loc.clear_data_description),
          actions: [
            TextButton(child: Text(context.loc.cancel), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: Text(context.loc.confirm), onPressed: () => Navigator.of(context).pop(true)),
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
            SnackBar(content: Text(context.loc.data_cleared)),
          );
        }
      }
    } catch (e, stackTrace) {
      Log.error('Error clearing data: $e', stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.data_clear_failed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.cleaning_services),
      tooltip: context.loc.clear_all_data,
      onPressed: () => showClearDialog(context, ref),
    );
  }
}
