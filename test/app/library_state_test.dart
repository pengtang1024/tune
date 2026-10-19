import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_state.dart';

void main() {
  const songs = [
    Song(
      id: 1,
      title: 'Night Flight',
      artist: 'Forest Radio',
      album: 'City Echoes',
      uri: '/music/a.mp3',
    ),
    Song(
      id: 2,
      title: 'Beta',
      artist: 'Artist B',
      album: 'Second Album',
      uri: '/music/b.mp3',
    ),
  ];

  test('empty query returns all songs', () {
    const state = LibraryState(songs: songs, query: '   ');
    expect(state.filteredSongs, songs);
  });

  test('query matches title, artist and album case-insensitively', () {
    const state = LibraryState(songs: songs);

    expect(state.copyWith(query: 'night').filteredSongs, [songs[0]]);
    expect(state.copyWith(query: 'FOREST').filteredSongs, [songs[0]]);
    expect(state.copyWith(query: 'echoes').filteredSongs, [songs[0]]);
    expect(state.copyWith(query: 'album').filteredSongs, [songs[1]]);
  });

  test('query with no match returns an empty list', () {
    const state = LibraryState(songs: songs, query: 'missing');
    expect(state.filteredSongs, isEmpty);
  });

  test('source filter narrows before the text query', () {
    const remote = Song(
      id: 3,
      title: 'Piano Melody',
      artist: 'Open Artist',
      duration: 10000,
      uri: 'tune://openverse/abc',
      sourceId: 'openverse',
    );
    const state = LibraryState(songs: [...songs, remote]);

    expect(state.copyWith(sourceFilter: 'openverse').filteredSongs, [remote]);
    expect(state.copyWith(sourceFilter: 'local').filteredSongs, songs);
    expect(
      state.copyWith(sourceFilter: 'openverse', query: 'night').filteredSongs,
      isEmpty,
    );
    expect(
      state
          .copyWith(sourceFilter: 'openverse')
          .copyWith(sourceFilter: null)
          .filteredSongs,
      hasLength(3),
    );
  });
}
