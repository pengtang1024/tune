import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_engine.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);

  Song song(
    int id, {
    required String artist,
    String album = '',
    String? genre,
    int? year,
  }) {
    return Song(
      id: id,
      title: 'Track $id',
      artist: artist,
      album: album,
      genre: genre,
      year: year,
      uri: '/music/$id.mp3',
      dateAdded: now.subtract(Duration(days: id % 90)).millisecondsSinceEpoch,
    );
  }

  DiscoveryOutput recommend(
    List<Song> library, {
    Set<String> favorites = const {},
    Map<String, TrackListening> listening = const {},
  }) {
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: favorites,
      listening: listening,
      now: now,
    );
    return const RecommendationEngine().recommend(
      library: library,
      favoriteUris: favorites,
      profile: profile,
      dismissedUris: const {},
      sourceOrder: const [],
      dateKey: '2026-10-24',
      listening: listening,
      allowFresh: true,
      now: now,
    );
  }

  Set<String> urisOf(DiscoveryOutput output) {
    return {
      for (final section in output.sections)
        for (final track in section.tracks) track.song.uri,
    };
  }

  test('held-out favorites are found again', () {
    const genres = ['Rock', 'Jazz', 'Pop', 'Folk', 'Electronic'];
    final library = <Song>[
      for (var artist = 0; artist < 5; artist++) ...[
        song(
          artist * 2,
          artist: 'Artist $artist',
          album: 'Album ${artist * 2}',
          genre: genres[artist],
          year: 1980 + artist * 10,
        ),
        song(
          artist * 2 + 1,
          artist: 'Artist $artist',
          album: 'Album ${artist * 2 + 1}',
          genre: genres[artist],
          year: 1980 + artist * 10,
        ),
      ],
      for (var index = 10; index < 300; index++)
        song(
          index,
          artist: 'Other ${index % 25}',
          album: 'Other Album ${index % 60}',
          genre: genres[index % genres.length],
          year: 1980 + (index % 5) * 10,
        ),
    ];
    final favorites = {
      for (var artist = 0; artist < 5; artist++) '/music/${artist * 2}.mp3',
    };
    final heldOut = {
      for (var artist = 0; artist < 5; artist++) '/music/${artist * 2 + 1}.mp3',
    };

    final output = recommend(library, favorites: favorites);
    final recommended = urisOf(output);
    final found = heldOut.where(recommended.contains).length;

    // A random 50-track page covers about one sixth of this library. The
    // content-based page has to recover most of the held-out favorites.
    expect(found, greaterThanOrEqualTo(4));
    expect(found / heldOut.length, greaterThan(50 / library.length));
  });

  test('a track with a high skip share falls below a finished track', () {
    final library = [
      for (var index = 0; index < 30; index++)
        song(
          index,
          artist: 'Artist $index',
          album: 'Album $index',
          genre: 'Rock',
        ),
    ];
    final listening = {
      '/music/0.mp3': TrackListening(
        skips: 5,
        lastPlayedAt: now.subtract(const Duration(hours: 1)),
      ),
      '/music/1.mp3': TrackListening(
        listens: 5,
        completions: 5,
        lastPlayedAt: now.subtract(const Duration(days: 1)),
      ),
    };

    final output = recommend(library, listening: listening);
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final uris = daily.tracks.map((track) => track.song.uri).toList();

    expect(uris, contains('/music/1.mp3'));
    expect(uris, isNot(contains('/music/0.mp3')));
  });

  test('a recently played track ranks below an older favorite', () {
    final library = [
      for (var index = 0; index < 30; index++)
        song(
          index,
          artist: 'Artist $index',
          album: 'Album $index',
          genre: 'Rock',
        ),
    ];
    final listening = {
      '/music/0.mp3': TrackListening(
        listens: 2,
        completions: 2,
        lastPlayedAt: now.subtract(const Duration(days: 1)),
      ),
      '/music/1.mp3': TrackListening(
        listens: 2,
        completions: 2,
        lastPlayedAt: now.subtract(const Duration(days: 90)),
      ),
    };

    final output = recommend(library, listening: listening);
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final recent = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/0.mp3',
    );
    final older = daily.tracks.firstWhere(
      (track) => track.song.uri == '/music/1.mp3',
    );

    expect(older.score, greaterThan(recent.score));
  });

  test('the daily mix leaves room for an adjacent artist', () {
    final library = [
      for (var index = 0; index < 8; index++)
        song(
          index,
          artist: 'Favorite Artist',
          album: 'Favorite $index',
          genre: 'Rock',
        ),
      for (var index = 8; index < 18; index++)
        song(
          index,
          artist: 'Adjacent Artist',
          album: 'Adjacent $index',
          genre: 'Rock',
        ),
      for (var index = 18; index < 28; index++)
        song(index, artist: 'Far Artist', album: 'Far $index', genre: 'Jazz'),
    ];
    final favorites = {'/music/0.mp3', '/music/1.mp3', '/music/2.mp3'};

    final output = recommend(library, favorites: favorites);
    final daily = output.sections.firstWhere(
      (section) => section.kind == DiscoverySectionKind.dailyMix,
    );
    final adjacent = daily.tracks
        .where((track) => track.song.artist == 'Adjacent Artist')
        .length;

    expect(adjacent, greaterThanOrEqualTo(2));
  });
}
