import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/providers/persistence_providers.dart';

/// How many tracks one remote source may keep in the library.
///
/// Zero keeps everything. The value lives here instead of the settings state
/// because the library reads it while it merges a scan, and the settings
/// controller pulls in services the library does not need.
final libraryCacheLimitProvider =
    NotifierProvider<LibraryCacheLimitController, int>(
      LibraryCacheLimitController.new,
    );

class LibraryCacheLimitController extends Notifier<int> {
  static const String key = 'source_cache_limit';

  @override
  int build() {
    final persistence = ref.watch(persistenceServiceProvider);
    return persistence.getInt(key) ?? 0;
  }

  Future<void> set(int value) async {
    final limit = value < 0 ? 0 : value;
    if (state == limit) return;
    state = limit;
    await ref.read(persistenceServiceProvider).setInt(key, limit);
  }
}
