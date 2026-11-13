import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/impl/saf_music_scanner.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The tree the reader picked on Android, read from the preferences.
final safTreeStoreProvider = Provider<SafTreeStore>((ref) {
  return SafTreeStore(ref.watch(persistenceServiceProvider));
});

/// The scanner the library reads its local files through.
///
/// A desktop walks the folders it is given. A phone cannot see other apps'
/// files under scoped storage: it reads the system library, or the one folder
/// the reader picked through the system directory picker. The choice is read
/// on every scan, so picking a folder takes effect without a restart.
final crossPlatformMusicScannerProvider = Provider<CrossPlatformMusicScanner>((
  ref,
) {
  if (PlatformConstants.isAndroid) {
    return SafMusicScanner(tree: ref.watch(safTreeStoreProvider));
  }
  return CrossPlatformMusicScannerImpl();
});
