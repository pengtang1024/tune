import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';

/// The ledger of the lyrics a library already has.
///
/// M0 of the smart lyrics plan (docs/smart-lyrics.md §2): the baseline the
/// smart pipeline starts from is the share of tracks that carry lyrics
/// locally — a tag sheet, or a lyrics file next to the audio. The count is
/// one query over the rows; the library never enters memory for it.
void main() {
  group('the lyrics ledger of the database', () {
    test('counts the tracks that carry lyrics and the ones that miss them', () {
      final db = AppDatabase.inMemory();
      db.ingestBatch([
        const Song(id: 1, uri: '/a.mp3', title: 'A', hasLyrics: true),
        const Song(id: 2, uri: '/b.mp3', title: 'B'),
        const Song(id: 3, uri: '/c.mp3', title: 'C', hasLyrics: true),
      ]);

      final ledger = db.lyricsLedgerCounts();

      expect(ledger.$1, 3, reason: 'the whole library is the denominator');
      expect(ledger.$2, 2, reason: 'two of three carry lyrics');
    });

    test('a track that left the library stops counting', () {
      final db = AppDatabase.inMemory();
      db.ingestBatch([
        const Song(id: 1, uri: '/a.mp3', title: 'A', hasLyrics: true),
        const Song(id: 2, uri: '/b.mp3', title: 'B'),
      ]);
      // No enabled source covers any row: the whole library leaves the page.
      db.deactivateUncovered(enabledSourceIds: {}, localPaths: []);

      final ledger = db.lyricsLedgerCounts();

      expect(ledger.$1, 0);
      expect(ledger.$2, 0);
    });

    test('an empty library reads as zero on both counts', () {
      final db = AppDatabase.inMemory();

      final ledger = db.lyricsLedgerCounts();

      expect(ledger.$1, 0);
      expect(ledger.$2, 0);
    });

    test('a sheet that lands while the app runs moves the number', () {
      final db = AppDatabase.inMemory();
      db.ingestBatch([const Song(id: 1, uri: '/a.mp3', title: 'A')]);

      db.markSongHasLyrics(1);

      expect(db.lyricsLedgerCounts(), (1, 1),
          reason: 'the ledger must not wait for the next full scan');
    });

    test('a remote song whose smart task is done counts as having words', () {
      final db = AppDatabase.inMemory();
      db.ingestBatch([
        const Song(id: 1, uri: 'tune://source.test/one', title: 'A'),
      ]);
      db.enqueueMissingTasks(now: 1);
      db.beginTaskRun(1, now: 2);
      db.setTaskOutcome(1, 'done', now: 3);

      expect(db.lyricsLedgerCounts(), (1, 1),
          reason: 'a scan cannot see the sheet of a remote song; the task '
              'row is the fact that it was written');
    });

    test('the lyrics fact survives a row written twice', () {
      final db = AppDatabase.inMemory();
      final song = const Song(id: 1, uri: '/a.mp3', title: 'A');
      db.ingestBatch([song]);

      // A later scan finds a lyrics file next to the audio: the fact
      // changes, so the row is rewritten and the ledger follows.
      db.ingestBatch([const Song(id: 1, uri: '/a.mp3', title: 'A', hasLyrics: true)]);

      expect(db.lyricsLedgerCounts(), (1, 1));
    });
  });
}
