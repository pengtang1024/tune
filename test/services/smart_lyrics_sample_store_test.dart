import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_sample_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_sample.dart';

/// The accuracy sample of the database (docs/smart-lyrics.md §10, M3): a
/// stratified draw lands in its own tables, the human verdicts in another —
/// a redraw never loses a verdict, and a track that left the library stops
/// counting.
void main() {
  late AppDatabase db;
  late SmartLyricsSampleStore store;

  setUp(() {
    db = AppDatabase.inMemory();
    store = SmartLyricsSampleStore(database: () async => db);
  });

  group('the stratified sample of the database', () {
    test('a draw writes one row per drawn track, its layer carried', () async {
      db.ingestBatch([
        for (var index = 0; index < 250; index++)
          Song(
            id: index,
            uri: '/studio-$index.mp3',
            title: '月亮第$index',
            hasLyrics: true,
          ),
      ]);

      final drawn = await store.draw(perLayer: 200, seed: 7);

      expect(drawn, 200);
      final account = await store.read();
      expect(account.layers.single.layer, SmartLyricsLayer.studio);
      expect(account.drawn, 200);
    });

    test('a track that carries no lyrics is not sampled', () async {
      db.ingestBatch([
        const Song(id: 1, uri: '/a.mp3', title: '月亮', hasLyrics: true),
        const Song(id: 2, uri: '/b.mp3', title: '太阳'),
      ]);

      expect(await store.draw(perLayer: 200, seed: 7), 1);
    });

    test('redrawing keeps the verdicts and the tracks already drawn', () async {
      db.ingestBatch([
        for (var index = 0; index < 250; index++)
          Song(
            id: index,
            uri: '/studio-$index.mp3',
            title: '月亮第$index',
            hasLyrics: true,
          ),
      ]);

      await store.draw(perLayer: 200, seed: 7);
      final tracks = await store.tracksOf(SmartLyricsLayer.studio);
      await store.recordVerdict(tracks.first.uri, correct: true);

      final second = await store.draw(perLayer: 200, seed: 7);

      expect(second, 0, reason: 'the set is already drawn: nothing new joins, '
          'the verification round does not jump');
      final account = await store.read();
      expect(account.drawn, 200, reason: 'the drawn set stays');
      expect(account.checked, 1, reason: 'the verdict survives the redraw');
      expect(account.correct, 1);
    });

    test('a verdict can change: the last one counts', () async {
      db.ingestBatch([
        const Song(id: 1, uri: '/a.mp3', title: '月亮', hasLyrics: true),
      ]);
      await store.draw(perLayer: 1, seed: 7);

      await store.recordVerdict('/a.mp3', correct: false);
      await store.recordVerdict('/a.mp3', correct: true);

      expect((await store.read()).correct, 1);
    });

    test('the counts split by layer, the rate counts only checked rows', () async {
      db.ingestBatch([
        for (var index = 0; index < 210; index++)
          Song(
            id: index,
            uri: '/studio-$index.mp3',
            title: '月亮第$index',
            hasLyrics: true,
          ),
        for (var index = 0; index < 220; index++)
          Song(
            id: 1000 + index,
            uri: '/en-$index.mp3',
            title: 'Night $index',
            hasLyrics: true,
          ),
      ]);
      await store.draw(perLayer: 200, seed: 7);
      final english = await store.tracksOf(SmartLyricsLayer.nonChinese);
      await store.recordVerdict(english.first.uri, correct: true);
      await store.recordVerdict(english.last.uri, correct: false);

      final account = await store.read();

      expect(account.drawn, 400);
      expect(account.checked, 2);
      expect(account.correct, 1);
      final englishRow = account.layers.singleWhere(
        (row) => row.layer == SmartLyricsLayer.nonChinese,
      );
      expect(englishRow.drawn, 200);
      expect(englishRow.checked, 2);
      expect(englishRow.correct, 1);
      expect(account.rate, 0.5);
    });

    test('a track that left the library stops counting', () async {
      db.ingestBatch([
        const Song(id: 1, uri: '/a.mp3', title: '月亮', hasLyrics: true),
        const Song(id: 2, uri: '/b.mp3', title: '太阳', hasLyrics: true),
      ]);
      await store.draw(perLayer: 200, seed: 7);
      await store.recordVerdict('/a.mp3', correct: true);

      db.deactivateUncovered(enabledSourceIds: {}, localPaths: []);

      final account = await store.read();
      expect(account.drawn, 0);
      expect(account.checked, 0);
    });

    test('an account of an empty sample reads as zero', () async {
      final account = await store.read();

      expect(account.drawn, 0);
      expect(account.rate, isNull);
    });
  });
}
