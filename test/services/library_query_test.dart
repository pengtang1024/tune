import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/song_facts.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';

/// The filter and facet queries of the library (docs/library-browse.md):
/// sets are OR inside a group and AND across groups, and the counts keep
/// the other options visible.
void main() {
  late AppDatabase db;
  final now = DateTime.now().millisecondsSinceEpoch;

  const alpha = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    album: 'Album X',
    year: 1995,
    genre: 'Jazz',
    genres: ['Jazz'],
    duration: 180000,
    language: 'zh-CN',
    type: 'audio/mpeg',
    uri: '/music/a.mp3',
    dateAdded: 0,
    hasLyrics: true,
  );
  const beta = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    album: 'Album Y',
    year: 2005,
    genre: 'Rock',
    genres: ['Rock', 'Pop'],
    duration: 240000,
    language: 'en-US',
    type: 'audio/flac',
    uri: '/music/b.flac',
    sourceId: 'openverse',
  );
  const gamma = Song(
    id: 3,
    title: 'Gamma',
    artist: 'Artist A',
    album: 'Album Z',
    uri: 'tune://source.test/gamma.m4a',
    sourceId: 'source.test',
  );

  setUp(() {
    db = AppDatabase.inMemory();
    db.ingestBatch([
      alpha.copyWith(dateAdded: now - const Duration(days: 1).inMilliseconds),
      beta.copyWith(dateAdded: now - const Duration(days: 400).inMilliseconds),
      gamma,
    ]);
    db.saveFavorites({alpha.uri});
  });

  List<String> titlesOf(LibraryFilter filter, {LibrarySort? sort}) => db
      .query(
        query: '',
        filter: filter,
        sort: sort ?? LibrarySort.title,
        offset: 0,
        limit: 20,
      )
      .map((song) => song.title)
      .toList();

  test('a genre set is OR inside the group', () {
    expect(
      titlesOf(const LibraryFilter(genres: {'jazz', 'rock'})),
      ['Alpha', 'Beta'],
    );
  });

  test('groups are ANDed together', () {
    expect(
      titlesOf(
        const LibraryFilter(genres: {'jazz', 'rock'}, artists: {'Artist A'}),
      ),
      ['Alpha'],
    );
  });

  test('the decade, artist, source, format and language groups narrow', () {
    expect(titlesOf(const LibraryFilter(decades: {1990})), ['Alpha']);
    expect(titlesOf(const LibraryFilter(artists: {'Artist A'})), [
      'Alpha',
      'Gamma',
    ]);
    expect(titlesOf(const LibraryFilter(sources: {'local'})), ['Alpha']);
    expect(titlesOf(const LibraryFilter(formats: {'flac'})), ['Beta']);
    expect(titlesOf(const LibraryFilter(languages: {'en'})), ['Beta']);
  });

  test('duration buckets and added windows narrow', () {
    expect(
      titlesOf(const LibraryFilter(durations: {LibraryDurationBucket.medium})),
      ['Alpha', 'Beta'],
    );
    expect(
      titlesOf(const LibraryFilter(added: {LibraryAddedWindow.lastWeek})),
      ['Alpha'],
    );
    expect(
      titlesOf(const LibraryFilter(added: {LibraryAddedWindow.older})),
      ['Beta'],
    );
  });

  test('status reads the favorites and the lyrics facts', () {
    expect(
      titlesOf(const LibraryFilter(status: LibraryStatusFilter.liked)),
      ['Alpha'],
    );
    expect(
      titlesOf(const LibraryFilter(status: LibraryStatusFilter.withLyrics)),
      ['Alpha'],
    );
    expect(
      titlesOf(const LibraryFilter(status: LibraryStatusFilter.withoutLyrics)),
      ['Beta', 'Gamma'],
    );
  });

  test('the sort orders by title and by the added time', () {
    expect(titlesOf(LibraryFilter.empty), ['Alpha', 'Beta', 'Gamma']);
    expect(
      titlesOf(LibraryFilter.empty, sort: LibrarySort.recent),
      ['Alpha', 'Beta', 'Gamma'],
      reason: 'the unknown added time stays last',
    );
    expect(
      titlesOf(
        LibraryFilter.empty,
        sort: const LibrarySort(field: LibrarySortField.title, ascending: false),
      ),
      ['Gamma', 'Beta', 'Alpha'],
    );
  });

  test('the count follows the same rule as the window', () {
    expect(
      db.countQuery(
        query: '',
        filter: const LibraryFilter(genres: {'jazz'}),
      ),
      1,
    );
  });

  test('the facets count each group without its own selection', () {
    final facets = db.facets(filter: LibraryFilter.empty);

    expect(facets.genres['jazz'], 1);
    expect(facets.genres['rock'], 1);
    expect(facets.genres['pop'], 1);
    expect(facets.decades[1990], 1);
    expect(facets.decades[2000], 1);
    expect(facets.artists['Artist A'], 2);
    expect(facets.sources['local'], 1);
    expect(facets.languages['zh'], 1);
    expect(facets.languages['en'], 1);
    expect(facets.formats['mp3'], 1);
    expect(facets.formats['flac'], 1);
    expect(facets.durations[LibraryDurationBucket.medium], 2);
    expect(facets.added[LibraryAddedWindow.lastWeek], 1);
    expect(facets.statuses[LibraryStatusFilter.liked], 1);
    expect(facets.statuses[LibraryStatusFilter.withLyrics], 1);
  });

  test('an old database gets the new columns and their facts backfilled',
      () async {
    final root = await Directory.systemTemp.createTemp('tune_library_migrate');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final path = '${root.path}/library.db';
    final raw = sqlite3.open(path);
    raw.execute('''
      CREATE TABLE songs (
        uri TEXT PRIMARY KEY,
        source_id TEXT,
        title TEXT,
        artist TEXT,
        album TEXT,
        date_added INTEGER,
        year INTEGER,
        genre TEXT,
        json TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        last_seen INTEGER NOT NULL DEFAULT 0,
        last_played INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0,
        has_lyrics INTEGER NOT NULL DEFAULT 0
      )
    ''');
    final old = Song(
      id: 7,
      title: 'Old',
      artist: 'A',
      uri: '/music/old.mp3',
      duration: 240000,
      language: 'zh-CN',
      type: 'audio/mpeg',
      dateAdded: now,
    );
    raw.execute(
      'INSERT INTO songs (uri, title, artist, json) VALUES (?, ?, ?, ?)',
      [old.uri, old.title, old.artist, jsonEncode(old.toJson())],
    );
    raw.close();

    final migrated = AppDatabase.open(path);
    final songs = migrated.query(
      query: '',
      filter: const LibraryFilter(formats: {'mp3'}, languages: {'zh'}),
      sort: LibrarySort.recent,
      offset: 0,
      limit: 10,
    );

    expect(songs.map((song) => song.uri), [old.uri]);
    expect(migrated.facets(filter: LibraryFilter.empty).formats['mp3'], 1);
  });

  test('the media facts are normalized from the tag and the path', () {
    expect(languageKeyOf(alpha), 'zh');
    expect(languageKeyOf(gamma), isNull);
    expect(formatOfSong(alpha), 'mp3');
    expect(formatOfSong(beta), 'flac');
    expect(formatOfSong(gamma), 'm4a');
    expect(formatOfPath('tune://source.test/a.opus'), 'ogg');
    expect(formatOfPath('/music/a'), 'other');
  });
}
