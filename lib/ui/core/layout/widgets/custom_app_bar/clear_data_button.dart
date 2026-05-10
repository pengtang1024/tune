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
      tooltip: 'Clear all data',
      onPressed: () async {
        try {
          final shouldClear = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Confirm Clear'),
              content: const Text('Are you sure you want to clear all app data? '
                  'This will reset all settings and scan records, but will not delete your music files.'),
              actions: [
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
                TextButton(child: const Text('Confirm'), onPressed: () => Navigator.of(context).pop(true)),
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
                const SnackBar(content: Text('Data cleared')),
              );
            }
          }
        } catch (e, stackTrace) {
          Log.error('Error clearing data: $e', stackTrace);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to clear data')),
            );
          }
        }
      },
    );
  }
}
