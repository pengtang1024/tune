import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_engine.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);
  final freshStamp = now.millisecondsSinceEpoch;
  final oldStamp = now
      .subtract(const Duration(days: 90))
      .millisecondsSinceEpoch;

  Song song(
    int id, {
    String artist = 'Artist',
    String album = 'Album',
    String? genre,
    List<String>? genres,
    int? year,
    String? sourceId,
    int dateAdded = 0,
  }) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      album: album,
      genre: genre,
      genres: genres,
      year: year,
      uri: sourceId == null ? '/music/$id.mp3' : 'tune://$sourceId/$id',
      sourceId: sourceId,
      externalId: sourceId == null ? null : '$id',
      streamUrl: sourceId == null ? null : 'https://example.com/$id.mp3',
      dateAdded: dateAdded,
    );
  }

  DiscoveryOutput recommend({
    required List<Song> library,
    Set<String> favorites = const {},
    Set<String> dismissed = const {},
    Set<String> dismissedArtists = const {},
    Set<String> queued = const {},
    Map<String, TrackListening> listening = const {},
    Map<String, double> sourceHealth = const {},
    List<String> sourceOrder = const [],
    bool allowFresh = false,
    int salt = 0,
  }) {
    return const RecommendationEngine().recommend(
      library: library,
      favoriteUris: favorites,
      profile: TasteProfile.from(
        library: library,
        favoriteUris: favorites,
        listening: listening,
        now: now,
      ),
      dismissedUris: dismissed,
      dismissedArtists: dismissedArtists,
      queuedUris: queued,
      sourceHealth: sourceHealth,
      listening: listening,
      sourceOrder: sourceOrder,
      dateKey: '2026-10-24',
      refreshSalt: salt,
      allowFresh: allowFresh,
      now: now,
    );
  }

  test('an empty library has no sections', () {
    final output = recommend(library: const []);
    expect(output.sections, isEmpty);
  });

  test('a library without hearts has a mix but no artist shelf', () {
    final library = [
      for (var index = 0; index < 30; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
    ];
    final output = recommend(library: library);

    expect(output.sections.first.kind, DiscoverySectionKind.dailyMix);
    expect(
      output.sections.any(
        (section) => section.kind == DiscoverySectionKind.artist,
      ),
      isFalse,
    );
    expect(
      output.sections.any(
        (section) => section.kind == DiscoverySectionKind.explore,
      ),
      isTrue,
    );
  });

  test('a strong artist gets a shelf of their own', () {
    final library = [
      for (var index = 0; index < 2; index++)
        song(index, artist: 'Nujabes', album: 'Favorite $index'),
      for (var index = 2; index < 7; index++)
        song(index, artist: 'Nujabes', album: 'Album $index'),
    ];
    final output = recommend(
      library: library,
      favorites: {'/music/0.mp3', '/music/1.mp3'},
    );

    final artistSection = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.artist,
    );
    expect(artistSection.reason.kind, RecommendationReasonKind.artist);
    expect(artistSection.reason.artist, 'Nujabes');
    expect(artistSection.tracks.length, greaterThanOrEqualTo(3));
    expect(
      artistSection.tracks.every((track) => track.song.artist == 'Nujabes'),
      isTrue,
    );
    expect(artistSection.tracks.any((track) => track.fromFavorites), isFalse);
  });

  test('a library of only hearts still gives a mix', () {
    final library = [
      for (var index = 0; index < 6; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
    ];
    final favorites = {for (final item in library) item.uri};
    final output = recommend(library: library, favorites: favorites);

    final daily = output.sections.first;
    expect(daily.kind, DiscoverySectionKind.dailyMix);
    expect(daily.reason.kind, RecommendationReasonKind.favorite);
    expect(daily.tracks.every((track) => track.fromFavorites), isTrue);
  });

  test('dismissed and live tracks are left out', () {
    final library = [
      for (var index = 0; index < 6; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
      const Song(
        id: 99,
        title: 'Live',
        artist: 'Live Artist',
        uri: '/music/live.mp3',
        isLiveStream: true,
      ),
    ];
    final output = recommend(library: library, dismissed: {'/music/0.mp3'});
    final uris = {
      for (final section in output.sections)
        for (final track in section.tracks) track.song.uri,
    };

    expect(uris, isNot(contains('/music/0.mp3')));
    expect(uris, isNot(contains('/music/live.mp3')));
  });

  test('the same day and the same input keep the order', () {
    final library = [
      for (var index = 0; index < 10; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
    ];
    final first = recommend(library: library);
    final second = recommend(library: library);

    expect(
      first.sections.first.tracks.map((track) => track.song.uri),
      second.sections.first.tracks.map((track) => track.song.uri),
    );

    final refreshed = recommend(library: library, salt: 1);
    expect(
      first.sections.first.tracks.map((track) => track.song.uri),
      isNot(refreshed.sections.first.tracks.map((track) => track.song.uri)),
    );
  });

  test('a fresh shelf uses the first-seen time', () {
    final library = [
      for (var index = 0; index < 30; index++)
        song(
          index,
          artist: index < 6 ? 'Fresh Artist' : 'Artist $index',
          album: 'Album $index',
          dateAdded: index < 6 ? freshStamp : oldStamp,
        ),
    ];
    final output = recommend(library: library, allowFresh: true);

    final fresh = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.fresh,
    );
    expect(fresh.tracks, isNotEmpty);
    expect(
      fresh.tracks.every(
        (track) => DateTime.fromMillisecondsSinceEpoch(
          track.song.dateAdded,
        ).isAfter(now.subtract(const Duration(days: 30))),
      ),
      isTrue,
    );
  });

  test('genres and decades can explain a pick', () {
    final library = [
      for (var index = 0; index < 3; index++)
        song(
          index,
          artist: 'Jazz Artist',
          album: 'Jazz $index',
          genre: 'Jazz',
          year: 1990,
        ),
      for (var index = 3; index < 8; index++)
        song(
          index,
          artist: 'Other $index',
          album: 'Other $index',
          genre: 'Jazz',
          year: 1990,
        ),
    ];
    final output = recommend(library: library, favorites: {'/music/0.mp3'});
    final reasons = {
      for (final section in output.sections)
        for (final track in section.tracks) track.reason.kind,
    };

    expect(
      reasons.any(
        (kind) =>
            kind == RecommendationReasonKind.artist ||
            kind == RecommendationReasonKind.genre ||
            kind == RecommendationReasonKind.era,
      ),
      isTrue,
    );
  });

  test('every track appears at most once on the page', () {
    final library = [
      for (var index = 0; index < 40; index++)
        song(
          index,
          artist: 'Artist ${index % 6}',
          album: 'Album ${index % 12}',
          sourceId: index >= 30 ? 'openverse' : null,
        ),
    ];
    final output = recommend(
      library: library,
      favorites: {'/music/0.mp3'},
      sourceOrder: ['openverse'],
      allowFresh: true,
    );
    final uris = <String>[];
    for (final section in output.sections) {
      for (final track in section.tracks) {
        uris.add(track.song.uri);
      }
    }

    expect(uris.length, uris.toSet().length);
  });

  test('an artist never fills a whole mix', () {
    final library = [
      for (var index = 0; index < 10; index++)
        song(index, artist: 'Same Artist', album: 'Album $index'),
    ];
    final output = recommend(library: library);
    final uris = {
      for (final section in output.sections)
        for (final track in section.tracks) track.song.uri,
    };

    expect(uris.length, lessThanOrEqualTo(3));
  });

  test('a dismissed artist leaves the local page', () {
    final library = [
      for (var index = 0; index < 6; index++)
        song(
          index,
          artist: index < 3 ? 'Nujabes' : 'Other $index',
          album: 'Album $index',
        ),
    ];
    final output = recommend(library: library, dismissedArtists: {'nujabes'});
    final artists = {
      for (final section in output.sections)
        for (final track in section.tracks) track.song.artist,
    };

    expect(artists, isNot(contains('Nujabes')));
    expect(artists, contains('Other 3'));
  });

  test('tracks already in the queue rank below the others', () {
    final library = [
      for (var index = 0; index < 10; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
    ];
    final output = recommend(library: library, queued: {'/music/0.mp3'});
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final queued = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/0.mp3',
    );
    final fresh = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/2.mp3',
    );

    expect(queued.score, lessThan(fresh.score));
  });

  test('a queue that holds the whole library still leaves a page', () {
    final library = [
      for (var index = 0; index < 6; index++)
        song(index, artist: 'Artist $index', album: 'Album $index'),
    ];
    final output = recommend(
      library: library,
      queued: {for (final item in library) item.uri},
    );

    expect(output.sections, isNotEmpty);
  });

  test('the daily mix does not put one artist next to itself', () {
    final library = [
      for (var index = 0; index < 9; index++)
        song(index, artist: 'Artist ${index % 3}', album: 'Album $index'),
    ];
    final output = recommend(library: library);
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );

    for (var index = 1; index < daily.tracks.length; index++) {
      expect(
        daily.tracks[index].song.artist,
        isNot(daily.tracks[index - 1].song.artist),
      );
    }
  });

  test('an old skip matters less than a recent one', () {
    final library = [
      for (var index = 0; index < 10; index++)
        song(
          index,
          artist: index < 2 ? 'Same Artist' : 'Artist $index',
          album: 'Album $index',
        ),
    ];
    final listening = {
      '/music/0.mp3': TrackListening(
        listens: 1,
        skips: 1,
        lastPlayedAt: now.subtract(const Duration(days: 180)),
      ),
      '/music/1.mp3': TrackListening(
        listens: 1,
        skips: 1,
        lastPlayedAt: now.subtract(const Duration(days: 1)),
      ),
    };
    final output = recommend(library: library, listening: listening);
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final old = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/0.mp3',
    );
    final recent = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/1.mp3',
    );

    expect(old.score, greaterThan(recent.score));
  });

  test('an unhealthy source loses recommendation weight', () {
    final library = [
      for (var index = 0; index < 10; index++)
        song(
          index,
          artist: 'Artist $index',
          album: 'Album $index',
          sourceId: index < 5 ? 'healthy' : 'broken',
        ),
    ];
    final output = recommend(
      library: library,
      sourceHealth: {'healthy': 1.0, 'broken': 0.0},
      sourceOrder: ['healthy', 'broken'],
    );
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final healthy = daily.tracks.firstWhere(
      (track) => track.song.sourceId == 'healthy',
    );
    final broken = daily.tracks.firstWhere(
      (track) => track.song.sourceId == 'broken',
    );

    expect(healthy.score, greaterThan(broken.score));
    final sourceSections = output.sections.where(
      (section) => section.kind == DiscoverySectionKind.source,
    );
    expect(
      sourceSections.every((section) => section.reason.sourceId == 'healthy'),
      isTrue,
    );
  });

  test('one album does not starve the explore shelf', () {
    final library = [
      for (var index = 0; index < 40; index++)
        song(index, artist: 'Artist $index', album: 'One Album', genre: 'Rock'),
    ];
    final output = recommend(library: library, favorites: {'/music/0.mp3'});
    final explore = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.explore,
    );

    expect(explore.tracks.length, greaterThanOrEqualTo(3));
  });
}
