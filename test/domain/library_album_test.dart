import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_album.dart';

void main() {
  test('the tracks of an album are grouped and ordered by the album', () {
    const songs = [
      Song(
        id: 1,
        title: 'Second',
        artist: 'Artist',
        album: 'Record',
        trackNumber: 2,
        duration: 2000,
        uri: '/music/2.mp3',
      ),
      Song(
        id: 2,
        title: 'First',
        artist: 'Artist',
        album: 'Record',
        trackNumber: 1,
        duration: 1000,
        uri: '/music/1.mp3',
        albumArtPath: '/music/cover.jpg',
      ),
      Song(
        id: 3,
        title: 'Single',
        artist: 'Another',
        duration: 3000,
        uri: '/music/3.mp3',
      ),
    ];

    final albums = libraryAlbumsOf(songs);

    expect(albums, hasLength(2));
    final record = albums.first;
    expect(record.name, 'Record');
    expect(record.artist, 'Artist');
    expect(record.trackCount, 2);
    expect(record.durationInMillis, 3000);
    expect(record.coverPath, '/music/cover.jpg');
    expect(record.coverUrl, isNull);
    expect(record.songs.map((song) => song.title), ['First', 'Second']);

    final singles = albums.last;
    expect(singles.name, isEmpty);
    expect(singles.songs.single.title, 'Single');
  });

  test('the same album name by two artists is two albums', () {
    const songs = [
      Song(
        id: 1,
        title: 'Left',
        artist: 'Left Artist',
        album: 'Greatest Hits',
        uri: '/music/l.mp3',
      ),
      Song(
        id: 2,
        title: 'Right',
        artist: 'Right Artist',
        album: 'Greatest Hits',
        uri: '/music/r.mp3',
      ),
    ];

    final albums = libraryAlbumsOf(songs);

    expect(albums, hasLength(2));
    expect(albums.map((album) => album.artist), [
      'Left Artist',
      'Right Artist',
    ]);
    expect(albums.map((album) => album.key).toSet(), hasLength(2));
  });

  test('the group without an album knows when it names many artists', () {
    const songs = [
      Song(id: 1, title: 'One', artist: 'First', uri: '/music/1.mp3'),
      Song(id: 2, title: 'Two', artist: 'Second', uri: '/music/2.mp3'),
    ];

    final album = libraryAlbumsOf(songs).single;

    expect(album.isUnknown, isTrue);
    expect(album.hasMultipleArtists, isTrue);
  });

  test('an album takes the cover of the first track that has one', () {
    const songs = [
      Song(
        id: 1,
        title: 'No cover',
        artist: 'Artist',
        album: 'Record',
        trackNumber: 1,
        uri: '/music/1.mp3',
      ),
      Song(
        id: 2,
        title: 'Remote cover',
        artist: 'Artist',
        album: 'Record',
        trackNumber: 2,
        uri: '/music/2.mp3',
        artworkUrl: 'https://example.com/cover.jpg',
      ),
    ];

    final album = libraryAlbumsOf(songs).single;

    expect(album.coverPath, isNull);
    expect(album.coverUrl, 'https://example.com/cover.jpg');
  });
}
