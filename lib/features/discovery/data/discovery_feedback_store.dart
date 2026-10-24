import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/features/discovery/data/timed_feedback_store.dart';

/// The tracks the reader asked the discover page to recommend less.
///
/// The store keeps one mark per track for 30 days. It is not a black list and
/// it never reaches the library: a dismissed track still plays, still shows
/// in the library and keeps its heart.
class DiscoveryFeedbackStore {
  DiscoveryFeedbackStore(PersistenceService persistence)
    : _store = TimedFeedbackStore(
        persistence: persistence,
        key: key,
        field: 'tracks',
        version: version,
        ttl: ttl,
      );

  static const String key = 'discovery_feedback_v1';
  static const int version = 1;
  static const Duration ttl = Duration(days: 30);

  final TimedFeedbackStore _store;

  Map<String, DateTime> read({DateTime? now}) => _store.read(now: now);

  Future<void> dismiss(String uri, {DateTime? now}) =>
      _store.mark(uri, now: now);

  Future<void> remove(String uri) => _store.remove(uri);

  Future<void> write(Map<String, DateTime> entries) => _store.write(entries);

  Future<void> clear() => _store.clear();
}

/// The artists the reader asked the discover page to show less often.
///
/// It is separate from the track marks because it speaks about a whole
/// artist: one click removes every local recommendation of that name for the
/// same 30 days.
class DiscoveryArtistFeedbackStore {
  DiscoveryArtistFeedbackStore(PersistenceService persistence)
    : _store = TimedFeedbackStore(
        persistence: persistence,
        key: key,
        field: 'artists',
        version: version,
        ttl: ttl,
      );

  static const String key = 'discovery_artist_feedback_v1';
  static const int version = 1;
  static const Duration ttl = Duration(days: 30);

  final TimedFeedbackStore _store;

  Map<String, DateTime> read({DateTime? now}) => _store.read(now: now);

  Future<void> dismiss(String artistKey, {DateTime? now}) =>
      _store.mark(artistKey, now: now);

  Future<void> remove(String artistKey) => _store.remove(artistKey);

  Future<void> clear() => _store.clear();
}
