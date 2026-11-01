import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
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

  test('the shortest track runs first, long podcasts last', () async {
    db.ingestBatch([
      const Song(id: 1, uri: '/long.mp3', title: 'Long', duration: 300000),
      const Song(id: 2, uri: '/short.mp3', title: 'Short', duration: 60000),
      const Song(id: 3, uri: '/medium.mp3', title: 'Medium', duration: 180000),
    ]);
    await store.enqueueMissing();

    expect((await store.nextPending())?.id, 2);
    await store.markRunning(2);
    await store.markDone(2, votes: 1);
    expect((await store.nextPending())?.id, 3);
  });

  test('a local file goes before a stream of the same length', () async {
    db.ingestBatch([
      const Song(id: 1, uri: 'tune://source.test/one', title: 'Remote', duration: 60000),
      const Song(
        id: 2,
        uri: '/local.mp3',
        title: 'Local',
        duration: 60000,
        localPath: '/local.mp3',
      ),
    ]);
    await store.enqueueMissing();

    expect((await store.nextPending())?.id, 2,
        reason: 'a local file needs no network and is the healthy first try');
  });

  test('a never-tried track goes before a retry of the same length', () async {
    db.ingestBatch([
      const Song(id: 1, uri: '/fresh.mp3', title: 'Fresh', duration: 60000),
      const Song(id: 2, uri: '/retry.mp3', title: 'Retry', duration: 60000),
    ]);
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');
    await store.requeueFailed(maxAttempts: 5);

    expect((await store.nextPending())?.id, 1,
        reason: 'the fresh track is the healthier first try; the retry waits');
  });

  test('a marked track goes first, whatever else is in the way', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markSong(3);

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

  test('a run the app died under is back in line, not stuck running',
      () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);

    expect(await store.requeueInterrupted(), 1);
    expect((await store.nextPending())?.id, 3,
        reason: 'the fresh task is the healthier first try');
    await store.markRunning(3);
    await store.markDone(3, votes: 1);
    expect((await store.nextPending())?.id, 2,
        reason: 'the interrupted task is back in line, not stuck running');
  });

  test('an automatic pass only revives the attempts it has left', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');

    expect(await store.requeueFailed(maxAttempts: 3), 1,
        reason: 'two attempts burned, one left');
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');

    expect(await store.requeueFailed(maxAttempts: 3), 0,
        reason: 'three attempts is where the automatic pass stops');
    expect(await store.requeueFailed(), 1,
        reason: 'the reader pressing retry is not capped');
  });

  test('a spoken-word track over ten minutes is not queued', () async {
    db.ingestBatch([
      const Song(id: 1, uri: '/audiobook.mp3', title: 'Book', duration: 900000),
      const Song(id: 2, uri: '/song.mp3', title: 'Song', duration: 300000),
    ]);

    expect(await store.enqueueMissing(), 1);
    expect((await store.nextPending())?.id, 2,
        reason: 'an audiobook is not a song; the panel can still run it');
  });

  test('a long task an older queue left is dropped', () async {
    db.ingestBatch([
      const Song(id: 1, uri: '/book.mp3', title: 'Book'),
    ]);
    await store.enqueueMissing();

    db.ingestBatch([
      const Song(id: 1, uri: '/book.mp3', title: 'Book', duration: 900000),
    ]);
    await store.enqueueMissing();

    expect(await store.nextPending(), isNull);
    expect((await store.counts()).values.fold<int>(0, (a, b) => a + b), 0);
  });

  test('a live stream is not a gap: no task, no ledger entry', () async {
    db.ingestBatch([
      const Song(
        id: 1,
        uri: 'tune://radio/a',
        title: 'Radio',
        isLiveStream: true,
      ),
      const Song(id: 2, uri: '/b.mp3', title: '太阳'),
    ]);

    expect(await store.enqueueMissing(), 1);
    expect((await store.nextPending())?.id, 2);
    expect(db.lyricsLedgerCounts(), (1, 0),
        reason: 'a station has no fixed recording to put words on');
  });

  test('a task an older queue left for a live stream is dropped', () async {
    const station = Song(id: 1, uri: 'tune://radio/a', title: 'Radio');
    db.ingestBatch([station]);
    await store.enqueueMissing();

    db.ingestBatch([
      const Song(
        id: 1,
        uri: 'tune://radio/a',
        title: 'Radio',
        isLiveStream: true,
      ),
    ]);
    await store.enqueueMissing();

    expect(await store.nextPending(), isNull);
    expect((await store.counts()).values.fold<int>(0, (a, b) => a + b), 0);
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
    await store.markSong(3);

    expect((await store.nextPending())?.id, 3);
  });

  test('the free check only sees the dead accounts', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');
    await store.markRunning(3);
    await store.markDisputed(3, votes: 2);

    final candidates = await store.leakyCandidates();

    expect(candidates.map((song) => song.id), [2, 3]);
  });

  test('a track the free check revived is done, its rivals are not asked', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markFailed(2, error: 'gone');
    await store.markRunning(3);
    await store.markDisputed(3, votes: 2);

    final candidates = await store.leakyCandidates();
    await store.applyOutcome(
      candidates.first,
      const SmartLyricsOutcome(saved: true, votes: 3, origins: ['lrclib']),
    );

    expect((await store.counts())[SmartLyricsTaskStatus.done], 1);
    expect(
      (await store.leakyCandidates()).map((song) => song.id),
      [3],
      reason: 'the revived one is done; the rivals are still dead accounts',
    );
  });

  test('a run that failed twice says so where the reader can read it', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);

    final song = await store.nextPending();
    await store.applyOutcome(
      song!,
      const SmartLyricsOutcome(saved: false),
    );

    final counts = await store.counts();
    expect(counts[SmartLyricsTaskStatus.failed], 1);
  });

  test('a mark puts the track back in line for a re-solve', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markRunning(2);
    await store.markDone(2, votes: 3);

    await store.markSong(2);

    expect((await store.nextPending())?.id, 2, reason: 'a mark is the '
        'reader telling the pool where to look again');
    expect((await store.flagsOf(2)).song, isTrue);
  });

  test('a track that carried words gets a place in line from its mark', () async {
    ingestLibrary();

    await store.markSong(1);

    expect((await store.nextPending())?.id, 1, reason: 'the song had words '
        'on the scan, but the reader says they are wrong');
  });

  test('a line mark flags that line and only that line', () async {
    ingestLibrary();
    await store.markLine(2, 5);
    await store.markLine(2, 9);

    final flags = await store.flagsOf(2);

    expect(flags.lines, {5, 9});
    expect(flags.song, isFalse);
    expect(flags.isEmpty, isFalse);
  });

  test('taking a mark back leaves the account empty and the track in line', () async {
    ingestLibrary();
    await store.enqueueMissing();
    await store.markLine(2, 5);
    await store.unmarkLine(2, 5);

    expect((await store.flagsOf(2)).isEmpty, isTrue);
    expect((await store.nextPending())?.id, 2);
  });

  test('naming a track not-sung keeps it out of the queue', () async {
    ingestLibrary();
    await store.enqueueMissing();

    await store.markNotSung(2);

    final counts = await store.counts();
    expect(counts[SmartLyricsTaskStatus.instrumental], 1);
    expect((await store.flagsOf(2)).instrumental, isTrue);
    expect((await store.nextPending())?.id, 3, reason: 'not sung is a name, '
        'not a debt — nothing waits for it');
  });

  test('a re-solve settles the marks; new disputes are system marks', () async {
    ingestLibrary();
    await store.markLine(2, 5);
    await store.markSong(2);

    final song = await store.nextPending();
    await store.applyOutcome(
      song!,
      const SmartLyricsOutcome(saved: true, votes: 3, disputedLines: [2]),
    );

    final flags = await store.flagsOf(2);
    expect(flags.lines, {2}, reason: 'the fresh dispute, and nothing else');
    expect(flags.song, isFalse, reason: 'the whole-song mark was answered '
        'by the new sheet');
    final mark = (await store.openMarks(2)).single;
    expect(mark.source, 'system');
    expect(
      (await store.counts())[SmartLyricsTaskStatus.disputed],
      1,
      reason: 'the lines left in dispute keep the track on the account',
    );
  });

  test('the management sees the marks grouped by track, open ones first', () async {
    ingestLibrary();
    await store.markSong(1); // track 1: open
    await store.markLine(3, 2); // track 3: open
    await store.markLine(2, 0); // track 2: open
    await store.unmarkLine(2, 0); // track 2: answered

    final groups = await store.markGroups();

    expect(groups.map((group) => group.song.id), [1, 3, 2],
        reason: 'the tracks with something open come first, the answered '
            'ones behind — and each track holds its marks together');
    expect(groups.last.marks.single.state, SmartLyricsMarkState.revoked);
  });

  test('an explicit reword answers the line mark and nothing else', () async {
    ingestLibrary();
    await store.markLine(2, 5);
    await store.markSong(2);

    await store.rewordMark(2, 5);

    final flags = await store.flagsOf(2);
    expect(flags.lines, isEmpty, reason: 'the reader wrote the words; the '
        'line mark is answered that way');
    expect(flags.song, isTrue, reason: 'the other mark stands — it has its '
        'own way out');
  });

  test('taking back one kind never touches the marks next to it', () async {
    ingestLibrary();
    await store.markLine(2, 5);
    await store.markSong(2);
    await store.markNotSung(2);

    await store.unmarkSong(2);

    var flags = await store.flagsOf(2);
    expect(flags.song, isFalse, reason: 'the whole-track mark is taken back');
    expect(flags.lines, {5}, reason: 'the flag on the line stands');
    expect(flags.instrumental, isTrue, reason: 'the not-sung name stands');

    await store.unmarkNotSung(2);
    flags = await store.flagsOf(2);
    expect(flags.instrumental, isFalse);
    expect(flags.lines, {5}, reason: 'still only what was pressed away');
    expect(
      (await store.nextPending())?.id,
      2,
      reason: 'the name taken back puts the track in line again',
    );
  });
}
