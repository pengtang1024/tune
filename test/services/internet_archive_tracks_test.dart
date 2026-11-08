import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/internet_archive_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// An archive item is often a record, not a track.
///
/// The metadata of an item lists every audio file it holds: a 78 rpm disc has
/// two sides, a netlabel release has an album. The source reads those files as
/// the tracks of the item, once per track, so the music is not hidden behind
/// the cover.
void main() {
  group('the tracks of an archive item', () {
    test('a record becomes its tracks, one copy of each', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-record', 'title': 'The Record'},
            ],
          },
        },
        '/metadata/the-record': {
          'metadata': {
            'title': 'The Record',
            'creator': 'The Band',
            'album': 'The Record',
            'date': '1954-01-01',
            'genre': 'Jazz',
          },
          'files': [
            {
              'name': 'side-a.mp3',
              'format': 'VBR MP3',
              'title': 'First Song',
              'artist': 'The Band',
              'album': 'The Record',
              'track': '1/2',
              'length': '181.5',
            },
            {
              'name': 'side-a.ogg',
              'format': 'Ogg Vorbis',
              'title': 'First Song',
              'artist': 'The Band',
              'track': '1/2',
            },
            {
              'name': 'side-b_64kb.mp3',
              'format': '64Kbps MP3',
              'title': 'Second Song',
              'artist': 'The Band',
              'track': '2/2',
              'length': '200',
            },
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));

      final first = result.songs.first;
      expect(first.title, 'First Song');
      expect(first.artist, 'The Band');
      expect(first.album, 'The Record');
      expect(first.trackNumber, 1);
      expect(first.trackTotal, 2);
      expect(first.year, 1954);
      expect(first.genre, 'Jazz');
      expect(first.duration, 181500);
      expect(first.externalId, 'the-record/side-a.mp3');
      expect(
        first.streamUrl,
        'https://archive.org/download/the-record/side-a.mp3',
      );
      expect(
        first.artworkUrl,
        'https://archive.org/services/img/the-record',
      );

      // The smaller copy of the second side is the one that plays.
      expect(result.songs.last.title, 'Second Song');
      expect(
        result.songs.last.streamUrl,
        endsWith('side-b_64kb.mp3'),
      );
    });

    test('a disc that writes the performer into the title keeps one name', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-disc', 'title': 'The Disc'},
            ],
          },
        },
        '/metadata/the-disc': {
          'metadata': {'title': 'The Disc', 'creator': 'Barbie Gaye'},
          'files': [
            {
              'name': 'a.mp3',
              'format': 'VBR MP3',
              'title': 'My Boy Lollypop - Barbie Gaye',
              'track': '1',
            },
            {
              'name': 'b.mp3',
              'format': 'VBR MP3',
              'title': 'Say You Understand - Barbie Gaye',
              'track': '2',
            },
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs, hasLength(2));
      expect(result.songs.first.title, 'My Boy Lollypop');
      expect(result.songs.first.artist, 'Barbie Gaye');
      expect(result.songs.last.title, 'Say You Understand');
    });

    test('a tongue narrows the query of the archive', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {'docs': <dynamic>[]},
        },
      });

      await InternetArchiveSourceAdapter(dio: adapter.dio).scan(
        _request({'language': 'German'}),
      );

      // The archive files a tongue as a clause of the query, so a scan of one
      // tongue asks the same search with that clause added.
      expect(
        adapter.uris.first.queryParameters['q'],
        'mediatype:audio AND language:(German)',
      );
    });

    test('every tongue asks the query as it is', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {'docs': <dynamic>[]},
        },
      });

      await InternetArchiveSourceAdapter(dio: adapter.dio).scan(_request({}));

      expect(adapter.uris.first.queryParameters['q'], 'mediatype:audio');
    });
    test('a record of several files is named after its item', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-show', 'title': 'The Show'},
            ],
          },
        },
        '/metadata/the-show': {
          'metadata': {'title': 'The Show', 'creator': 'The Host'},
          'files': [
            {'name': 'one.mp3', 'format': 'VBR MP3', 'title': 'Episode One'},
            {'name': 'two.mp3', 'format': 'VBR MP3', 'title': 'Episode Two'},
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      // The item is the record: neither file names an album, so the tracks
      // are grouped under the name of the item they belong to.
      expect(
        result.songs.map((song) => song.album).toSet(),
        {'The Show'},
      );
    });
    test('a one-track item is named after the item', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-single', 'title': 'The Single'},
            ],
          },
        },
        '/metadata/the-single': {
          'metadata': {'title': 'The Single', 'creator': 'The Band'},
          'files': [
            {'name': 'track_01.mp3', 'format': 'VBR MP3'},
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs.single.title, 'The Single');
      expect(result.songs.single.trackNumber, 1);
      expect(result.songs.single.trackTotal, 1);
    });

    test('the position orders an item whose track number repeats', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-set', 'title': 'The Set'},
            ],
          },
        },
        '/metadata/the-set': {
          'metadata': {'title': 'The Set', 'creator': 'The Conet Project'},
          'files': [
            {'name': 'd1.mp3', 'format': 'VBR MP3', 'title': 'One', 'track': '1'},
            {'name': 'd2.mp3', 'format': 'VBR MP3', 'title': 'Two', 'track': '1'},
            {'name': 'd3.mp3', 'format': 'VBR MP3', 'title': 'Three', 'track': '2'},
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs, hasLength(3));
      expect(
        result.songs.map((song) => song.trackNumber),
        [1, 2, 3],
      );
      expect(
        result.songs.map((song) => song.trackTotal),
        [3, 3, 3],
      );
    });

    test('one item keeps at most thirty tracks', () async {
      final files = [
        for (var index = 1; index <= 40; index++)
          {
            'name': 'part$index.mp3',
            'format': 'VBR MP3',
            'title': 'Part $index',
          },
      ];
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-long-item', 'title': 'The Long Item'},
            ],
          },
        },
        '/metadata/the-long-item': {
          'metadata': {'title': 'The Long Item'},
          'files': files,
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs, hasLength(30));
      expect(result.songs.first.title, 'Part 1');
      expect(result.songs.last.title, 'Part 30');
    });

    test('a long book hands over as many chapters as asked for', () async {
      final files = [
        for (var index = 1; index <= 40; index++)
          {
            'name': 'part$index.mp3',
            'format': 'VBR MP3',
            'title': 'Part $index',
          },
      ];
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-book', 'title': 'The Book'},
            ],
          },
        },
        '/metadata/the-book': {
          'metadata': {'title': 'The Book'},
          'files': files,
        },
      });

      final result = await InternetArchiveSourceAdapter(dio: adapter.dio).scan(
        _request({'limit': '10', 'perItem': '40'}),
      );

      // A book of forty chapters is read whole when the reader raises the
      // limit; the default keeps an item from filling the library.
      expect(result.songs, hasLength(40));
      expect(result.songs.last.title, 'Part 40');
    });

    test('an item without playable audio adds nothing', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'the-scan', 'title': 'The Scan'},
            ],
          },
        },
        '/metadata/the-scan': {
          'metadata': {'title': 'The Scan'},
          'files': [
            {'name': 'cover.jpg', 'format': 'JPEG'},
            {'name': 'notes.txt', 'format': 'Text'},
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs, isEmpty);
      expect(result.message, isNotNull);
    });

    test('an empty date is not a year', () async {
      final adapter = _ArchiveAdapter({
        '/advancedsearch.php': {
          'response': {
            'docs': [
              {'identifier': 'undated', 'title': 'Undated'},
            ],
          },
        },
        '/metadata/undated': {
          'metadata': {'title': 'Undated', 'date': '0000-00-00'},
          'files': [
            {'name': 'a.mp3', 'format': 'VBR MP3', 'title': 'A'},
          ],
        },
      });

      final result = await InternetArchiveSourceAdapter(
        dio: adapter.dio,
      ).scan(_request({'limit': '10'}));

      expect(result.songs.single.year, isNull);
    });
  });
}

MusicSourceScanRequest _request(Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: 'great78',
      type: 'internet_archive',
      name: 'Great 78 Project',
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// Answers the archive search and the metadata of each item.
class _ArchiveAdapter implements HttpClientAdapter {
  _ArchiveAdapter(this.answers);

  final Map<String, Object?> answers;
  final List<Uri> uris = [];

  Dio get dio {
    final client = Dio();
    client.httpClientAdapter = this;
    return client;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uris.add(options.uri);

    final answer = answers[options.uri.path];
    if (answer == null) {
      return _body('{}', 404);
    }
    return _body(jsonEncode(answer), 200);
  }

  ResponseBody _body(String text, int statusCode) {
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        Headers.contentLengthHeader: [bytes.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
