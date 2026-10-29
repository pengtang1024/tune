import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_run_lock.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';

import '../services/fake_persistence.dart';

/// The batch of M5 (docs/smart-lyrics.md §7.2): one track at a time, a
/// failure never stops the ones behind it, the cloud budget pauses the run
/// without losing the queue, and an interrupted run resumes where it stood.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const gap = Song(id: 1, uri: '/a.mp3', title: '月亮');
  const second = Song(id: 2, uri: '/b.mp3', title: '太阳');
  const third = Song(id: 3, uri: '/c.mp3', title: '星星');

  ProviderContainer containerWith({
    required _MemoryStore store,
    required _ScriptedService service,
    int? budget,
  }) {
    final persistence = FakePersistenceService();
    if (budget != null) {
      persistence.values['smart_lyrics'] = jsonEncode(
        SmartLyricsConfig(batchCloudBudget: budget).toJson(),
      );
    }
    return ProviderContainer(
      overrides: [
        smartLyricsTaskStoreProvider.overrideWithValue(store),
        smartLyricsServiceProvider.overrideWithValue(service),
        smartLyricsBatchGapProvider.overrideWithValue(Duration.zero),
        settingsControllerProvider.overrideWith(
          (ref) => SettingsController(persistence),
        ),
      ],
    );
  }

  test('the batch runs the gap tracks one at a time and marks each done', () async {
    final store = _MemoryStore([gap, second, third]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
      2: const SmartLyricsOutcome(saved: true, votes: 3),
      3: const SmartLyricsOutcome(saved: true, votes: 2),
    });
    final container = containerWith(store: store, service: service);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, [1, 2, 3], reason: 'the queue order, one at a time');
    expect(service.maxActive, 1, reason: 'the batch never runs two at once');
    expect(store.states[1], SmartLyricsTaskStatus.done);
    expect(store.states[2], SmartLyricsTaskStatus.done);
    expect(store.states[3], SmartLyricsTaskStatus.done);
    expect(
      container.read(smartLyricsBatchControllerProvider).running,
      isFalse,
    );
  });

  test('a single failure does not stop the ones behind it', () async {
    final store = _MemoryStore([gap, second]);
    final service = _ScriptedService({
      1: StateError('the channel did not answer'),
      2: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(store.states[1], SmartLyricsTaskStatus.failed);
    expect(store.states[2], SmartLyricsTaskStatus.done);
    expect(service.asked, [1, 2]);
  });

  test('the cloud budget stops the batch and the tracks stay pending', () async {
    final store = _MemoryStore([gap, second, third]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(
        saved: true,
        votes: 3,
        origins: ['cloud:whisper-1'],
      ),
      2: const SmartLyricsOutcome(
        saved: true,
        votes: 3,
        origins: ['cloud:whisper-1'],
      ),
      3: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service, budget: 1);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, [1], reason: 'the budget stopped it after one '
        'cloud song — the reader pays the next run, not an unattended one');
    expect(store.states[2], isNull, reason: 'the rest waits, still pending');
    expect(store.states[3], isNull);
    expect(container.read(smartLyricsBatchControllerProvider).pausedForBudget,
        isTrue);
  });

  test('a knowledge rebuild spends the budget like a cloud vote', () async {
    final store = _MemoryStore([gap, second]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(
        saved: true,
        votes: 3,
        origins: ['lrclib', 'knowledge:mimo'],
      ),
      2: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service, budget: 1);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, [1], reason: 'a chat rebuild leaves the machine '
        'too — counting only cloud: ASR undercounted the bill');
    expect(store.states[2], isNull);
  });

  test('a human-only song spends no cloud', () async {
    final store = _MemoryStore([gap, second]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3, origins: ['lrclib']),
      2: const SmartLyricsOutcome(
        saved: true,
        votes: 3,
        origins: ['cloud:whisper-1'],
      ),
    });
    final container = containerWith(store: store, service: service, budget: 1);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, [1, 2], reason: 'the free votes of the first song '
        'do not count against the cloud budget');
    expect(store.states[2], SmartLyricsTaskStatus.done);
  });

  test('stop leaves the rest for the next run', () async {
    final store = _MemoryStore([gap, second, third]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
      2: const SmartLyricsOutcome.cancelled(),
      3: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    // Song 2 blocks until the test says otherwise, so the stop lands while
    // the batch is really on its way.
    final gate = Completer<void>();
    service.gates[2] = gate;
    final container = containerWith(store: store, service: service);

    final notifier = container.read(smartLyricsBatchControllerProvider.notifier);
    final run = notifier.start();
    await Future<void>.delayed(Duration.zero);
    notifier.stop();
    gate.complete();
    await run;

    expect(store.states[1], SmartLyricsTaskStatus.done, reason: 'the song '
        'that had finished keeps its result');
    expect(store.states[2], SmartLyricsTaskStatus.pending, reason: 'the '
        'cancelled one is in line again — the batch resumes with the whole '
        'rest');
    expect(store.states[3], isNull);
    expect(container.read(smartLyricsBatchControllerProvider).running, isFalse);
  });

  test('the recheck puts only the failed back in line', () async {
    final store = _MemoryStore([gap, second]);
    store.states[1] = SmartLyricsTaskStatus.failed;
    store.states[2] = SmartLyricsTaskStatus.done;
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service);

    await container
        .read(smartLyricsBatchControllerProvider.notifier)
        .retryFailed();

    expect(service.asked, [1], reason: 'the done ones are never re-run; the '
        'recheck is for the dead accounts a new source may revive');
    expect(store.states[1], SmartLyricsTaskStatus.done);
  });

  test('two presses of the button drain the queue once', () async {
    final store = _MemoryStore([gap, second]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
      2: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    service.gates[1] = Completer<void>();
    final container = containerWith(store: store, service: service);
    final batch = container.read(smartLyricsBatchControllerProvider.notifier);

    final firstPress = batch.start();
    final secondPress = batch.start();
    service.gates[1]!.complete();
    await Future.wait([firstPress, secondPress]);

    expect(service.asked, [1, 2],
        reason: 'the second press must lose the seat before the first '
            'await — the old state.running check left that gap open');
  });

  test('the batch refuses to start while the panel holds the engines',
      () async {
    final store = _MemoryStore([gap]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service);
    final lock = container.read(smartLyricsRunLockProvider);
    lock.claimPanel();

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, isEmpty, reason: 'the panel run owns the engines');
    expect(container.read(smartLyricsBatchControllerProvider).running, isFalse);
    lock.releasePanel();
  });

  test('a task a dead run left running is back in line at start', () async {
    final store = _MemoryStore([gap])
      ..states[1] = SmartLyricsTaskStatus.running;
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, [1],
        reason: 'no run is in flight when the queue starts again');
    expect(store.states[1], SmartLyricsTaskStatus.done);
  });

  test('an automatic pass retries a failed task until its attempts run out',
      () async {
    final store = _MemoryStore([gap])
      ..states[1] = SmartLyricsTaskStatus.failed
      ..attempts[1] = 3;
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3),
    });
    final container = containerWith(store: store, service: service);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, isEmpty,
        reason: 'three failed attempts wait for the reader, not for a '
            'fourth automatic round');
  });

  test('an empty queue is an idle batch, not a spinner forever', () async {
    final store = _MemoryStore([]);
    final service = _ScriptedService({});
    final container = containerWith(store: store, service: service);

    await container.read(smartLyricsBatchControllerProvider.notifier).start();

    expect(service.asked, isEmpty);
    expect(container.read(smartLyricsBatchControllerProvider).running, isFalse);
  });
}

/// The queue in memory: the controller sees the store's contract, the test
/// sees the states it left behind.
class _MemoryStore extends SmartLyricsTaskStore {
  _MemoryStore(List<Song> gap)
    : _gap = List.of(gap),
      super(database: () => throw UnimplementedError());

  final List<Song> _gap;

  /// The state each song's task stands at; a song that was never touched
  /// has no entry and reads as pending.
  final Map<int, SmartLyricsTaskStatus> states = {};

  /// The songs a recheck brought back into line.
  final List<int> requeued = [];

  /// How many times each song was started.
  final Map<int, int> attempts = {};

  @override
  Future<int> enqueueMissing() async {
    var added = 0;
    for (final song in _gap) {
      if (!states.containsKey(song.id)) added++;
    }
    return added;
  }

  @override
  Future<int> newMissing() async => 0;

  @override
  Future<Song?> nextPending() async {
    for (final song in _gap) {
      final state = states[song.id];
      if (state == null || state == SmartLyricsTaskStatus.pending) {
        return song;
      }
    }
    return null;
  }

  @override
  Future<void> markRunning(int songId) async {
    attempts[songId] = (attempts[songId] ?? 0) + 1;
    states[songId] = SmartLyricsTaskStatus.running;
  }

  @override
  Future<void> markPending(int songId) async {
    states[songId] = SmartLyricsTaskStatus.pending;
  }

  @override
  Future<void> settleMarks(Song song, SmartLyricsOutcome outcome) async {}

  @override
  Future<void> markDone(int songId, {required int votes, int disputed = 0}) async {
    states[songId] = SmartLyricsTaskStatus.done;
  }

  @override
  Future<void> markDisputed(int songId, {required int votes}) async {
    states[songId] = SmartLyricsTaskStatus.disputed;
  }

  @override
  Future<void> markInstrumental(int songId) async {
    states[songId] = SmartLyricsTaskStatus.instrumental;
  }

  @override
  Future<void> markFailed(int songId, {required String error}) async {
    states[songId] = SmartLyricsTaskStatus.failed;
  }

  @override
  Future<Map<SmartLyricsTaskStatus, int>> counts() async {
    final counts = <SmartLyricsTaskStatus, int>{};
    for (final state in states.values) {
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<int> requeueInterrupted() async {
    var moved = 0;
    for (final entry in states.entries.toList()) {
      if (entry.value == SmartLyricsTaskStatus.running) {
        states[entry.key] = SmartLyricsTaskStatus.pending;
        moved++;
      }
    }
    return moved;
  }

  @override
  Future<int> requeueFailed({int? maxAttempts}) async {
    var moved = 0;
    for (final entry in states.entries.toList()) {
      if (entry.value != SmartLyricsTaskStatus.failed) continue;
      if (maxAttempts != null && (attempts[entry.key] ?? 0) >= maxAttempts) {
        continue;
      }
      states[entry.key] = SmartLyricsTaskStatus.pending;
      if (maxAttempts == null) attempts[entry.key] = 0;
      requeued.add(entry.key);
      moved++;
    }
    return moved;
  }

}

/// The pipeline with a script: every song answers what the test wrote,
/// and the concurrency it was asked under is on record.
class _ScriptedService extends SmartLyricsService {
  _ScriptedService(this.answers)
    : super(engines: const [], humanPool: const [], paths: _NoPaths());

  /// What each song answers: an outcome, or the error it throws.
  final Map<int, Object> answers;

  /// Songs that wait for the test before they answer.
  final Map<int, Completer<void>> gates = {};

  /// The songs in the order they were asked.
  final List<int> asked = [];

  /// The most songs that were ever in flight at once.
  int maxActive = 0;

  var _active = 0;

  @override
  Future<SmartLyricsOutcome> generate(Song song, {bool Function()? cancelled}) {
    asked.add(song.id);
    _active++;
    if (_active > maxActive) maxActive = _active;
    return Future<SmartLyricsOutcome>.sync(() async {
      try {
        final gate = gates[song.id];
        if (gate != null) await gate.future;
        final answer = answers[song.id];
        if (answer == null) return const SmartLyricsOutcome(saved: false);
        if (answer is SmartLyricsOutcome) return answer;
        throw answer;
      } finally {
        _active--;
      }
    });
  }
}

/// The paths the service never reaches in these tests.
class _NoPaths implements LibraryPaths {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the batch test has no file system');
}
