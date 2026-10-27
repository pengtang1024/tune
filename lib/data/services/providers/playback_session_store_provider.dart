import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The one session store of the app.
///
/// The store is opened once at startup and shared by the player, so the queue
/// lives in one place instead of one per controller build.
final playbackSessionStoreProvider = Provider<PlaybackSessionStore>((ref) {
  return PlaybackSessionStore(ref.watch(persistenceServiceProvider));
});
