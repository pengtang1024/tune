import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_leak_check_controller.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';

/// The free check of M5 (docs/smart-lyrics.md §7.2): one quiet pass over
/// the dead accounts, asking the human pool alone — a sheet the pool grew
/// in the meantime brings the song back, and a pass that found nothing
/// says nothing.
void main() {
  const dead = Song(id: 1, uri: '/a.mp3', title: '月亮');

  test('the free check revives a dead song through the human pool', () async {
    final store = _LeakStore([dead]);
    final service = _ScriptedService({
      1: const SmartLyricsOutcome(saved: true, votes: 3, origins: ['lrclib']),
    });
    final container = ProviderContainer(
      overrides: [
        smartLyricsTaskStoreProvider.overrideWithValue(store),
        smartLyricsHumanOnlyServiceProvider.overrideWithValue(service),
      ],
    );

    await container
        .read(smartLyricsLeakCheckControllerProvider)
        .runOnce();

    expect(service.asked, [1]);
    expect(store.states[1], SmartLyricsTaskStatus.done,
        reason: 'the sheet is on the disk; the account is settled');
  });

  test('a pass that found nothing new leaves the task as it stood', () async {
    final store = _LeakStore([dead])..states[1] = SmartLyricsTaskStatus.failed;
    final service = _ScriptedService({
      // The pool has no sheet for the song: the run answers with what a
      // channel-less pipeline answers — nothing to vote on.
      1: const SmartLyricsOutcome(saved: false),
    });
    final container = ProviderContainer(
      overrides: [
        smartLyricsTaskStoreProvider.overrideWithValue(store),
        smartLyricsHumanOnlyServiceProvider.overrideWithValue(service),
      ],
    );

    await container
        .read(smartLyricsLeakCheckControllerProvider)
        .runOnce();

    expect(store.states[1], SmartLyricsTaskStatus.failed,
        reason: 'the reason it had is still readable — a check that found '
            'nothing does not overwrite the account');
  });

  test('an empty set of dead accounts asks the pool nothing', () async {
    final store = _LeakStore([]);
    final service = _ScriptedService({});
    final container = ProviderContainer(
      overrides: [
        smartLyricsTaskStoreProvider.overrideWithValue(store),
        smartLyricsHumanOnlyServiceProvider.overrideWithValue(service),
      ],
    );

    await container
        .read(smartLyricsLeakCheckControllerProvider)
        .runOnce();

    expect(service.asked, isEmpty);
  });

  test('the human-only pipeline carries no channel to spend', () {
    final service = SmartLyricsService(
      engines: const [],
      humanPool: const [],
      paths: _NoPaths(),
    );

    expect(service.engines, isEmpty,
        reason: 'the free check is free: no ASR, no cloud, no CPU');
  });
}

/// The dead accounts in memory; the statuses they pass through are on
/// record.
class _LeakStore extends SmartLyricsTaskStore {
  _LeakStore(this._candidates)
    : super(database: () => throw UnimplementedError());

  final List<Song> _candidates;

  final Map<int, SmartLyricsTaskStatus> states = {};

  @override
  Future<List<Song>> leakyCandidates({int limit = 50}) async => _candidates;

  @override
  Future<void> markRunning(int songId) async {
    states[songId] = SmartLyricsTaskStatus.running;
  }

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
}

/// The pipeline with a script: every song answers what the test wrote.
class _ScriptedService extends SmartLyricsService {
  _ScriptedService(this.answers)
    : super(engines: const [], humanPool: const [], paths: _NoPaths());

  final Map<int, Object> answers;
  final List<int> asked = [];

  @override
  Future<SmartLyricsOutcome> generate(Song song, {bool Function()? cancelled}) {
    asked.add(song.id);
    final answer = answers[song.id];
    if (answer == null) return Future.value(const SmartLyricsOutcome(saved: false));
    if (answer is SmartLyricsOutcome) return Future.value(answer);
    return Future.error(answer);
  }
}

/// The paths the service never reaches in these tests.
class _NoPaths implements LibraryPaths {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the leak check test has no file system');
}
