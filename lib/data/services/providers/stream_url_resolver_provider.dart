import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/data/services/stream_url_resolver.dart';

/// Gives the player a way to rebuild expired remote addresses.
///
/// The wiring stays in the data layer so the player feature never imports the
/// music source feature.
final streamUrlResolverProvider = Provider<StreamUrlResolver>((ref) {
  return ref.watch(musicSourceServiceProvider);
});
