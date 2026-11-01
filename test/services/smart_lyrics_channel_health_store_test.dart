import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_channel_health_store.dart';
import 'package:tune/features/smart_lyrics/domain/channel_health.dart';

import 'fake_persistence.dart';

/// The channel health rings of the pipeline (docs/smart-lyrics.md §7.2,
/// M9): the failures count themselves down, the rings outlive a restart,
/// and the oldest answers fall off the ring.
void main() {
  test('a channel that keeps failing is under the threshold', () {
    final store = SmartLyricsChannelHealthStore(FakePersistenceService());

    for (var i = 0; i < 6; i++) {
      store.record('lrclib', ChannelOutcome.failure);
    }

    expect(store.healthOf('lrclib').usable, isFalse,
        reason: 'the pool stops asking a source that keeps failing — '
            'without a reader tending the list');
  });

  test('the rings outlive a restart', () {
    final persistence = FakePersistenceService();
    final first = SmartLyricsChannelHealthStore(persistence);
    for (var i = 0; i < 6; i++) {
      first.record('cloud:whisper-1', ChannelOutcome.failure);
    }

    final afterRestart = SmartLyricsChannelHealthStore(persistence);

    expect(afterRestart.healthOf('cloud:whisper-1').usable, isFalse,
        reason: 'a channel that failed yesterday is still failed today');
  });

  test('a good answer climbs back and the ring keeps the last ten', () {
    final store = SmartLyricsChannelHealthStore(FakePersistenceService());
    for (var i = 0; i < 10; i++) {
      store.record('local:tiny', ChannelOutcome.failure);
    }
    expect(store.healthOf('local:tiny').usable, isFalse);

    for (var i = 0; i < 6; i++) {
      store.record('local:tiny', ChannelOutcome.success);
    }

    expect(store.healthOf('local:tiny').usable, isTrue,
        reason: 'a streak of answers pushes the old failures off the ring');
  });

  test('a channel with no history is trusted', () {
    final store = SmartLyricsChannelHealthStore(FakePersistenceService());

    expect(store.healthOf('never-asked').usable, isTrue);
  });

  test('a broken file reads as no history, not a crash', () {
    final persistence = FakePersistenceService()
      ..values[SmartLyricsChannelHealthStore.healthKey] = 'not json';

    final store = SmartLyricsChannelHealthStore(persistence);

    expect(store.healthOf('lrclib').usable, isTrue);
    store.record('lrclib', ChannelOutcome.success);
    expect(store.healthOf('lrclib').score, greaterThan(0));
  });
}
