import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/impl/media_store_music_scanner.dart';

/// The scanner the library reads its local files through.
///
/// A desktop walks the folders it is given; a phone cannot see other apps'
/// files under scoped storage and asks the system media library instead.
final crossPlatformMusicScannerProvider = Provider<CrossPlatformMusicScanner>((
  ref,
) {
  if (PlatformConstants.isAndroid) return MediaStoreMusicScanner();
  return CrossPlatformMusicScannerImpl();
});
