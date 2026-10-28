import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_sample.dart';

/// The accuracy audit of the smart lyrics pipeline (docs/smart-lyrics.md
/// §10, M3): the stratified draw over the resolved rows, and the human
/// verdicts the double number「正确率」is read from.
///
/// The store orchestrates only — the classification and the draw are pure
/// functions of the domain, the rows live in the database, and nothing is
/// copied into memory between the two.
class SmartLyricsSampleStore {
  SmartLyricsSampleStore({Future<AppDatabase> Function()? database})
    : _databaseFactory = database;

  final Future<AppDatabase> Function()? _databaseFactory;

  AppDatabase? _database;

  Future<AppDatabase> _db() async {
    final existing = _database;
    if (existing != null) return existing;

    final factory = _databaseFactory;
    final database = factory != null ? await factory() : await _openDefault();
    _database = database;
    return database;
  }

  Future<AppDatabase> _openDefault() async {
    // The same file the library and the ledger read: one database holds the
    // app's index, and the sample is one more set of rows in it.
    final base = await getApplicationSupportDirectory();
    final directory = Directory(path.join(base.path, 'library'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return AppDatabase.open(path.join(directory.path, 'library.db'));
  }

  /// Draws the stratified sample over the tracks that carry lyrics, and
  /// answers how many rows the draw added. The tracks of earlier draws and
  /// the verdicts they carry stay — a redraw extends, never restarts.
  Future<int> draw({int perLayer = 200, int seed = defaultSampleSeed}) async {
    final database = await _db();
    final candidates = [
      for (final row in database.resolvedCandidateRows())
        SmartLyricsCandidate(
          uri: row.uri,
          title: row.title,
          artist: row.artist,
          album: row.album,
          genre: row.genre,
          language: row.language,
        ),
    ];
    final drawn = drawStratified(candidates, perLayer: perLayer, seed: seed);
    return database.saveSampleDrawn([
      for (final entry in drawn) (uri: entry.uri, layer: entry.layer.id),
    ]);
  }

  /// The account of the sample as it stands: what was drawn, what was
  /// checked, what a human judged right.
  Future<SmartLyricsSampleAccount> read() async {
    final database = await _db();
    return SmartLyricsSampleAccount(
      layers: [
        for (final row in database.sampleCountRows())
          SmartLyricsSampleRow(
            layer: SmartLyricsLayer.values.byName(row.layer),
            drawn: row.drawn,
            checked: row.checked,
            correct: row.correct,
          ),
      ],
    );
  }

  /// The drawn tracks of [layer], with the facts the verification round
  /// shows.
  Future<List<SmartLyricsSampleEntry>> tracksOf(SmartLyricsLayer layer) async {
    final database = await _db();
    return [
      for (final row in database.sampleTracksOf(layer.id))
        SmartLyricsSampleEntry(
          uri: row.uri,
          layer: layer,
          title: row.title,
          artist: row.artist,
        ),
    ];
  }

  /// Records — or changes — the human verdict of one drawn track.
  Future<void> recordVerdict(String uri, {required bool correct}) async {
    final database = await _db();
    database.recordSampleVerdict(uri, correct: correct);
  }
}

/// The seed every draw starts from unless one is named: the sample of a
/// library is a fact, not a dice roll — the same rows draw the same set,
/// today and next month.
const int defaultSampleSeed = 20261028;
