import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

void main() {
  Song song(
    int id, {
    String artist = 'Artist',
    String album = '',
    String? genre,
    List<String>? genres,
    int? year,
  }) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      album: album,
      genre: genre,
      genres: genres,
      year: year,
      uri: '/music/$id.mp3',
    );
  }

  test('an empty library has an empty profile', () {
    final profile = TasteProfile.from(
      library: const [],
      favoriteUris: const {},
    );

    expect(profile.isEmpty, isTrue);
    expect(profile.favoriteCount, 0);
  });

  test('hearts become normalized artist, genre and decade weights', () {
    final library = [
      song(1, artist: 'Nujabes', genre: 'Jazz', year: 2005),
      song(2, artist: 'Nujabes', genres: ['Jazz', 'Hip-Hop'], year: 2001),
      song(3, artist: 'Etta James', genre: 'Soul', year: 1962),
      song(4, artist: 'Not Liked', genre: 'Rock', year: 1990),
    ];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3', '/music/2.mp3', '/music/3.mp3'},
    );

    expect(profile.favoriteCount, 3);
    expect(profile.artistWeight('Nujabes'), 1);
    expect(profile.artistWeight('Etta James'), closeTo(0.5, 0.001));
    expect(profile.artistWeight('Not Liked'), 0);
    expect(profile.genreWeight('Jazz'), 1);
    expect(profile.genreWeight('Hip-Hop'), closeTo(0.5, 0.001));
    expect(profile.genreWeight('Soul'), closeTo(0.5, 0.001));
    expect(profile.decadeWeight(2000), 1);
    expect(profile.decadeWeight(1960), closeTo(0.5, 0.001));
    expect(profile.decadeWeight(1990), 0);
    expect(profile.topArtists(), ['nujabes', 'etta james']);
  });

  test('a heart outside the library does not shape the profile', () {
    final library = [song(1, artist: 'In Library', genre: 'Jazz')];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/2.mp3'},
    );

    expect(profile.isEmpty, isTrue);
    expect(profile.favoriteCount, 0);
  });

  test('a genre written on one line is split into keys', () {
    final library = [song(1, artist: 'Artist', genre: 'Rock / Jazz, Soul')];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3'},
    );

    expect(profile.genreWeight('Rock'), 1);
    expect(profile.genreWeight('Jazz'), 1);
    expect(profile.genreWeight('Soul'), 1);
  });

  test('an unusable year is left out of the decades', () {
    final library = [
      song(1, artist: 'Artist', year: 0),
      song(2, artist: 'Artist', year: 2026),
    ];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3', '/music/2.mp3'},
    );

    expect(profile.decades, {2020: 1});
  });

  test('the signature changes when a heart changes the taste', () {
    final library = [
      song(1, artist: 'A', genre: 'Jazz'),
      song(2, artist: 'B', genre: 'Rock'),
    ];
    final first = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3'},
    );
    final second = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/2.mp3'},
    );

    expect(first.signature, isNot(second.signature));
  });

  test('listening signals shape the profile and decay with age', () {
    final now = DateTime(2026, 10, 24, 12);
    final library = [
      song(1, artist: 'Recent', genre: 'Jazz', year: 2000),
      song(2, artist: 'Old', genre: 'Jazz', year: 2000),
    ];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: const {},
      listening: {
        '/music/1.mp3': TrackListening(listens: 2, lastPlayedAt: now),
        '/music/2.mp3': TrackListening(
          listens: 2,
          lastPlayedAt: now.subtract(const Duration(days: 90)),
        ),
      },
      now: now,
    );

    expect(profile.listenCount, 4);
    expect(profile.artistWeight('Recent'), 1);
    expect(profile.artistWeight('Old'), closeTo(0.25, 0.001));
    expect(profile.genreWeight('Jazz'), 1);
  });

  test('enough skips cancel the listens of a track', () {
    final now = DateTime(2026, 10, 24, 12);
    final library = [song(1, artist: 'Skipped', genre: 'Rock')];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: const {},
      listening: {
        '/music/1.mp3': TrackListening(listens: 1, skips: 2, lastPlayedAt: now),
      },
      now: now,
    );

    expect(profile.isEmpty, isTrue);
  });

  test('albums and decades are part of the profile', () {
    final library = [
      song(1, artist: 'A', album: 'Shared', year: 1999),
      song(2, artist: 'A', album: 'Shared', year: 2001),
      song(3, artist: 'B', album: 'Other', year: 2020),
    ];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3'},
    );

    expect(profile.albumWeightKey('shared'), 1);
    expect(profile.albumWeightKey('other'), 0);
    expect(profile.topDecades(), [1990]);
  });

  test('confidence grows with the evidence', () {
    final one = TasteProfile.from(
      library: [song(1, artist: 'A')],
      favoriteUris: {'/music/1.mp3'},
    );
    final many = TasteProfile.from(
      library: [
        for (var index = 1; index <= 10; index++) song(index, artist: 'A'),
      ],
      favoriteUris: {
        for (var index = 1; index <= 10; index++) '/music/$index.mp3',
      },
    );

    expect(one.confidence, closeTo(0.1, 0.001));
    expect(many.confidence, 1);
  });

  test('container genres and placeholder artists say nothing about taste', () {
    final library = [
      song(1, artist: 'Various Artists', genre: 'music'),
      song(2, artist: 'Unknown Artist', genre: 'unknown'),
      song(3, artist: 'Real Artist', genre: 'Jazz'),
    ];
    final profile = TasteProfile.from(
      library: library,
      favoriteUris: {'/music/1.mp3', '/music/2.mp3', '/music/3.mp3'},
    );

    expect(profile.artists.keys, ['real artist']);
    expect(profile.genres.keys, ['jazz']);
  });
}
