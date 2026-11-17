import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/album_summary.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/domain/library_album.dart';

void main() {
  Song songOf(
    String album,
    String artist, {
    required String uri,
    String source = 'community_music',
  }) {
    return Song(
      id: uri.hashCode,
      uri: 'tune://$source/$uri',
      title: 'Track $uri',
      artist: artist,
      album: album,
      duration: 180000,
      sourceId: source,
    );
  }

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

  group('the album column finds the card of a track', () {
    test('a music track lands on its own album', () {
      const song = Song(
        id: 1,
        title: 'One',
        artist: 'Artist',
        album: 'Record',
        uri: '/music/1.mp3',
      );
      const card = AlbumSummary(
        key: 'record\u0000artist',
        name: 'Record',
        artist: 'Artist',
        trackCount: 1,
      );

      expect(albumSummaryOf([card], song)?.key, card.key);
      expect(albumSummaryOf(const [], song), isNull);
    });

    test('an episode lands on the show merged from two sources', () {
      const song = Song(
        id: 1,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'archive_podcasts',
        uri: 'tune://archive/1',
      );
      const card = AlbumSummary(
        key: 'the show\u0000show\u0000podcast_rss-1\u0001archive_podcasts',
        name: 'The Show',
        artist: '',
        trackCount: 2,
        kind: ContentKind.podcast,
      );

      expect(albumSummaryOf([card], song)?.key, card.key);
    });

    test('an episode of another source stays off the card', () {
      const song = Song(
        id: 1,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'podcast_rss-2',
        uri: 'tune://podcast/1',
      );
      const card = AlbumSummary(
        key: 'the show\u0000show\u0000podcast_rss-1\u0001archive_podcasts',
        name: 'The Show',
        artist: '',
        trackCount: 2,
        kind: ContentKind.podcast,
      );

      expect(albumSummaryOf([card], song), isNull);
    });

    test('a music track does not fall back to a show card', () {
      const song = Song(
        id: 1,
        title: 'Track',
        artist: 'Artist',
        album: 'The Show',
        uri: '/music/1.mp3',
      );
      const card = AlbumSummary(
        key: 'the show\u0000show\u0000podcast_rss-1',
        name: 'The Show',
        artist: '',
        trackCount: 2,
        kind: ContentKind.podcast,
      );

      expect(albumSummaryOf([card], song), isNull);
    });
  });

  test('one album name from one source is one row, whatever the artists', () {
    // A compilation names a different performer on every track. Grouping by
    // artist would print the album title once per composer.
    final songs = [
      songOf('100 Masterpieces Vol. 2', 'Bach', uri: 'a'),
      songOf('100 Masterpieces Vol. 2', 'Vivaldi', uri: 'b'),
      songOf('100 Masterpieces Vol. 2', '', uri: 'c'),
    ];

    final groups = libraryAlbumGroupsOf(songs);

    expect(groups, hasLength(1));
    expect(groups.single.name, '100 Masterpieces Vol. 2');
    expect(groups.single.trackCount, 3);
    expect(groups.single.hasMultipleArtists, isTrue);
    expect(groups.single.artist, isEmpty);
  });

  test('the same album name from two sources stays two rows', () {
    final songs = [
      songOf('Nocturnes', 'A', uri: 'a', source: 'community_music'),
      songOf('Nocturnes', 'B', uri: 'b', source: 'netlabels'),
    ];

    final groups = libraryAlbumGroupsOf(songs);

    expect(groups, hasLength(2));
  });

  group('the rows of the group list', () {
    // A is one track, Alpha is two, D is one: one of each row, in an order
    // the name sort would not give.
    final songs = [
      rowSong(
        title: 'A song',
        album: 'Omega',
        artist: 'Ann',
        duration: 1000,
        addedAt: 10,
        uri: 'a',
      ),
      rowSong(
        title: 'B song',
        album: 'Alpha',
        artist: 'Bob',
        duration: 2000,
        addedAt: 300,
        uri: 'b',
      ),
      rowSong(
        title: 'C song',
        album: 'Alpha',
        artist: 'Bob',
        duration: 3000,
        addedAt: 100,
        uri: 'c',
      ),
      rowSong(
        title: 'D song',
        album: 'Zeta',
        artist: 'Ann',
        duration: 4000,
        addedAt: 500,
        uri: 'd',
      ),
    ];

    List<String> namesOf(LibrarySort sort) => [
      for (final row in libraryRowsOf(songs, sort: sort))
        switch (row) {
          LibraryAlbumRow(:final album) => album.name,
          LibrarySingleRow(:final song) => song.title,
        },
    ];

    test('a group of one track is that track row, a group of two stays', () {
      final rows = libraryRowsOf(songs, sort: LibrarySort.title);

      expect(rows.whereType<LibraryAlbumRow>(), hasLength(1));
      expect(rows.whereType<LibraryAlbumRow>().single.album.name, 'Alpha');
      expect(
        [for (final row in rows.whereType<LibrarySingleRow>()) row.song.title],
        ['A song', 'D song'],
      );
      for (final row in rows) {
        expect(
          row is LibraryAlbumRow && isSingleTrackGroup(row.album),
          isFalse,
        );
      }
    });

    test('the single row carries the track position of the list', () {
      final rows = libraryRowsOf(songs, sort: LibrarySort.title);

      expect(
        [
          for (final row in rows.whereType<LibrarySingleRow>())
            (row.song.title, row.index),
        ],
        [('A song', 0), ('D song', 3)],
      );
    });

    test('the mixed rows follow the sort field', () {
      expect(namesOf(LibrarySort.title), ['A song', 'Alpha', 'D song']);
      expect(namesOf(LibrarySort.title.flipped()), [
        'D song',
        'Alpha',
        'A song',
      ]);
      expect(namesOf(LibrarySort.recent), ['D song', 'Alpha', 'A song']);
      expect(namesOf(const LibrarySort(field: LibrarySortField.duration)), [
        'A song',
        'D song',
        'Alpha',
      ]);
      expect(namesOf(const LibrarySort(field: LibrarySortField.artist)), [
        'A song',
        'D song',
        'Alpha',
      ]);
      expect(namesOf(const LibrarySort(field: LibrarySortField.album)), [
        'Alpha',
        'A song',
        'D song',
      ]);
    });

    test('a show of one episode keeps its group row', () {
      final songs = [
        Song(
          id: 1,
          uri: 'tune://podcast_rss/1',
          title: 'An episode',
          artist: 'Host',
          album: 'The Show',
          duration: 200000,
          sourceId: 'podcast_rss',
        ),
      ];

      final rows = libraryRowsOf(songs, sort: LibrarySort.title);

      expect(rows.single, isA<LibraryAlbumRow>());
      final album = (rows.single as LibraryAlbumRow).album;
      expect(album.songs, hasLength(1));
      expect(isSingleTrackGroup(album), isFalse);
    });
  });
  test('a station favicon never becomes an album cover', () {
    final songs = [
      Song(
        id: 1,
        title: 'Smooth jazz',
        artist: '',
        album: '',
        uri: 'tune://radio/one',
        sourceId: 'radio',
        artworkUrl: 'http://101smoothjazz.com/favicon.ico',
        duration: 0,
      ),
      Song(
        id: 2,
        title: 'Late night',
        artist: '',
        album: '',
        uri: 'tune://radio/two',
        sourceId: 'radio',
        duration: 0,
      ),
    ];
    final album = libraryAlbumGroupsOf(songs).single;
    expect(album.coverUrl, isNull);
  });

  test('a cached site icon does not cover its group either', () {
    final songs = [
      Song(
        id: 1,
        title: 'Smooth jazz',
        artist: '',
        album: 'Late night radio',
        uri: 'tune://radio/one',
        sourceId: 'radio',
        artworkUrl: 'http://101smoothjazz.com/favicon.ico',
        albumArtPath: '/tmp/artwork/favicon-1.png',
        duration: 0,
      ),
      Song(
        id: 2,
        title: 'Late night',
        artist: '',
        album: 'Late night radio',
        uri: 'tune://radio/two',
        sourceId: 'radio',
        artworkUrl: 'https://cdn.example.com/cover.jpg',
        duration: 0,
      ),
    ];
    final album = libraryAlbumGroupsOf(songs).single;
    expect(album.coverUrl, 'https://cdn.example.com/cover.jpg');
  });

  test('a group without an album name shows no cover', () {
    final songs = [
      rowSong(
        title: 'One',
        album: '',
        artist: 'A',
        duration: 1000,
        addedAt: 1,
        uri: 'noname-1',
      ).copyWith(artworkUrl: 'https://cdn.example.com/cyan.png'),
      rowSong(
        title: 'Two',
        album: '',
        artist: 'B',
        duration: 1000,
        addedAt: 2,
        uri: 'noname-2',
      ),
    ];

    final groups = libraryAlbumGroupsOf(songs);

    expect(groups, hasLength(1));
    expect(groups.single.name, isEmpty);
    expect(groups.single.coverUrl, isNull);
    expect(groups.single.coverPath, isNull);
  });
}

/// A track with the facts the row order reads.
Song rowSong({
  required String title,
  required String album,
  required String artist,
  required int duration,
  required int addedAt,
  required String uri,
}) {
  return Song(
    id: uri.hashCode,
    uri: 'tune://community_music/$uri',
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    dateAdded: addedAt,
  );


}
