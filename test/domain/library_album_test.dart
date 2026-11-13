import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/music_source.dart';
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

  test('the episodes of a show are one album, whatever artist they name', () {
    const songs = [
      Song(
        id: 1,
        title: 'Episode 1',
        artist: 'Host A',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 2,
        title: 'Episode 2',
        artist: 'Host B',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        uri: 'tune://podcast/2',
      ),
    ];

    final album = libraryAlbumsOf(songs).single;

    expect(album.name, 'The Show');
    expect(album.trackCount, 2);
    expect(album.key, contains('src'));
    expect(album.key, contains('podcast_rss-1'));
    expect(album.kind, ContentKind.podcast);
  });

  test('an album says whether it holds episodes or chapters', () {
    const book = Song(
      id: 1,
      title: 'Chapter 1',
      album: 'A Book',
      sourceId: 'librivox',
      uri: 'tune://librivox/1',
    );

    expect(libraryAlbumsOf([book]).single.kind, ContentKind.audiobook);
    expect(
      libraryAlbumsOf([
        const Song(
          id: 2,
          title: 'Song',
          artist: 'Artist',
          album: 'Record',
          uri: '/music/2.mp3',
        ),
      ]).single.kind,
      ContentKind.music,
    );
  });

  test('two sources of the same show are two albums', () {
    const songs = [
      Song(
        id: 1,
        title: 'One',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 2,
        title: 'Two',
        album: 'The Show',
        sourceId: 'podcast_rss-2',
        uri: 'tune://podcast/2',
      ),
    ];

    expect(libraryAlbumsOf(songs), hasLength(2));
  });

  test('two sources of one show are one album when two episodes agree', () {
    const songs = [
      Song(
        id: 1,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        duration: 600000,
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 2,
        title: 'Episode 2',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        duration: 700000,
        uri: 'tune://podcast/2',
      ),
      Song(
        id: 3,
        title: 'episode 1 ',
        album: 'the show',
        sourceId: 'archive_podcasts',
        duration: 601000,
        uri: 'tune://archive/1',
      ),
      Song(
        id: 4,
        title: 'Episode 2',
        album: 'The Show',
        sourceId: 'archive_podcasts',
        duration: 700500,
        uri: 'tune://archive/2',
      ),
    ];

    final album = libraryAlbumsOf(songs).single;

    expect(album.key, contains('show'));
    expect(album.trackCount, 2);
    // The feed the reader added plays before the archive copy.
    expect(album.songs.map((song) => song.uri), [
      'tune://podcast/1',
      'tune://podcast/2',
    ]);
    expect(album.kind, ContentKind.podcast);
  });

  test('two same-named shows stay apart without a second shared episode', () {
    const songs = [
      Song(
        id: 1,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        duration: 600000,
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 2,
        title: 'Only here',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        duration: 700000,
        uri: 'tune://podcast/2',
      ),
      Song(
        id: 3,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'podcast_rss-2',
        duration: 600000,
        uri: 'tune://podcast/3',
      ),
      Song(
        id: 4,
        title: 'Only there',
        album: 'The Show',
        sourceId: 'podcast_rss-2',
        duration: 800000,
        uri: 'tune://podcast/4',
      ),
    ];

    expect(libraryAlbumsOf(songs), hasLength(2));
  });

  test('two shows that share episodes but not a name stay apart', () {
    const songs = [
      Song(
        id: 1,
        title: 'Episode 1',
        album: 'One Show',
        sourceId: 'podcast_rss-1',
        duration: 600000,
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 2,
        title: 'Episode 2',
        album: 'One Show',
        sourceId: 'podcast_rss-1',
        duration: 700000,
        uri: 'tune://podcast/2',
      ),
      Song(
        id: 3,
        title: 'Episode 1',
        album: 'Another Show',
        sourceId: 'podcast_rss-2',
        duration: 600000,
        uri: 'tune://podcast/3',
      ),
      Song(
        id: 4,
        title: 'Episode 2',
        album: 'Another Show',
        sourceId: 'podcast_rss-2',
        duration: 700000,
        uri: 'tune://podcast/4',
      ),
    ];

    expect(libraryAlbumsOf(songs), hasLength(2));
  });

  test('a book on this machine is an audiobook album', () {
    const songs = [
      Song(
        id: 1,
        title: 'Chapter 1',
        artist: 'Reader',
        album: 'A Book',
        uri: '/books/A Book/01.m4b',
        sourceId: 'local',
      ),
    ];

    final album = libraryAlbumsOf(songs).single;

    expect(album.kind, ContentKind.audiobook);
  });

  test('a station is not an album', () {
    const songs = [
      Song(
        id: 1,
        title: 'Station',
        artist: 'On air artist',
        album: 'On air song',
        sourceId: 'radio',
        isLiveStream: true,
        uri: 'tune://radio/1',
      ),
    ];

    expect(libraryAlbumsOf(songs), isEmpty);
  });

  test('a source instance id names the type of the source', () {
    expect(sourceTypeOfId('podcast_rss-2'), 'podcast_rss');
    expect(sourceTypeOfId('librivox'), 'librivox');
    expect(isSpokenWordSource('podcast_rss-2'), isTrue);
    expect(isSpokenWordSource('audiobookshelf-1'), isTrue);
    expect(isSpokenWordSource('local'), isFalse);
    expect(isSpokenWordSource(null), isFalse);
  });

  test('a track is classified by what it is', () {
    expect(
      contentKindOf(
        const Song(id: 1, isLiveStream: true, uri: 'tune://radio/1'),
      ),
      ContentKind.radio,
    );
    expect(
      contentKindOf(
        const Song(id: 2, sourceId: 'audiobookshelf-1', uri: 'tune://book/1'),
      ),
      ContentKind.audiobook,
    );
    expect(
      contentKindOf(const Song(id: 3, sourceId: 'local', uri: '/music/3.mp3')),
      ContentKind.music,
    );
  });
}
