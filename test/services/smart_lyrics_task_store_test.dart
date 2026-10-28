import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_task.dart';

/// The batch tasks of the library (docs/smart-lyrics.md §7.2, M5): the
/// queue only ever holds the tracks the three segments brought no words
/// for, its order does not jump between runs, and a done task is never
/// handed out again.
void main() {
  late AppDatabase db;
  late SmartLyricsTaskStore store;

  setUp(() {
    db = AppDatabase.inMemory();
    store = SmartLyricsTaskStore(database: () async => db);
  });

  /// The library the batch starts from: three tracks, two of them without
  /// lyrics, one already sung in a file.
  void ingestLibrary() {
    db.ingestBatch([
      const Song(id: 1, uri: '/a.mp3', title: '月亮', hasLyrics: true),
      const Song(id: 2, uri: '/b.mp3', title: '太阳'),
      const Song(id: 3, uri: '/c.mp3', title: '星星'),
    ]);
  }

  test('only the tracks that carry no lyrics are enqueued', () async {
    ingestLibrary();

    expect(await store.enqueueMissing(), 2);
    expect(await store.newMissing(), 0, reason: 'the whole gap is queued');
    expect(await store.enqueueMissing(), 0, reason: 'the press is idempotent');
  });

  test('the song a task names is read back whole', () async {
    ingestLibrary();
    await store.enqueueMissing();

    final song = await store.nextPending();

    expect(song?.id, 2);
    expect(song?.title, '太阳');
    expect(song?.uri, '/b.mp3');
  });

  test('a marked track goes first, whatever else is in the way', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.recordMark(3);

    expect((await store.nextPending())?.id, 3);
  });

  test('the order does not jump between runs', () async {
    ingestLibrary();
    await store.enqueueMissing();

    final first = await store.nextPending();
    await store.markRunning(first!.id);
    await store.markDone(first.id, votes: 3);

    // The run was interrupted: the restart picks up what is left, in the
    // same order the first run had, and never the done ones.
    expect((await store.nextPending())?.id, 3);
    await store.markRunning(3);
    await store.markDone(3, votes: 2);
    expect(await store.nextPending(), isNull);
  });

  test('a failed task stays for the retry, it does not loop by itself', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'the channel did not answer');

    expect(
      (await store.nextPending())?.id,
      3,
      reason: 'failed is not handed out again',
    );
    expect((await store.counts())[SmartLyricsTaskStatus.failed], 1);
    await store.markRunning(3);
    await store.markDone(3, votes: 2);
    expect(await store.nextPending(), isNull, reason: 'failed is not pending '
        '— the retry is an explicit action, not a spin');
  });

  test('the recheck puts the failed tasks back in line', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');

    expect(await store.requeueFailed(), 1);
    expect((await store.nextPending())?.id, 2);
  });

  test('a track that carries no voice is not a gap any more', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markInstrumental(2);

    expect((await store.counts())[SmartLyricsTaskStatus.instrumental], 1);
    expect(await store.enqueueMissing(), 0, reason: 'the task row stands, '
        'the track is not enqueued again');
  });

  test('a scan that finds a new gap song does not enqueue it itself', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markDone(2, votes: 3);
    await store.markRunning(3);
    await store.markDone(3, votes: 2);

    // A later scan brings a track the three segments have no words for.
    db.ingestBatch([const Song(id: 9, uri: '/z.mp3', title: '远方')]);

    expect(
      await store.newMissing(),
      1,
      reason: 'the card says「新增 N 首待补」; the queue only moves when the '
          'reader presses the button',
    );
    expect(await store.nextPending(), isNull, reason: 'nothing joined by '
        'itself');
  });

  test('a marked task also wins when it failed before', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');
    await store.requeueFailed();
    await store.recordMark(3);

    expect((await store.nextPending())?.id, 3);
  });
}
