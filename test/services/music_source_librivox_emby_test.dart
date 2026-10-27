import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/emby_source.dart';
import 'package:tune/data/services/music_sources/librivox_source.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// LibriVox reads its books in one catalogue and Emby speaks the shape of a
/// media library.
///
/// The tests below read the answers both sources give: what one book of the
/// catalogue becomes, and which address a self-hosted server is asked at.
void main() {
  group('LibriVox adapter', () {
    test('parses the list the catalogue wraps its books in', () {
      final books = LibrivoxSourceAdapter.parseBookList({
        'books': [_book()],
      });

      expect(books, hasLength(1));
      expect(books.single['title'], 'Bleak House');
    });

    test('a keyword that finds no book reads as an empty page', () {
      expect(
        LibrivoxSourceAdapter.parseBookList({
          'error': 'Audiobooks could not be found',
        }),
        isEmpty,
      );
      expect(LibrivoxSourceAdapter.parseBookList(null), isEmpty);
      expect(
        LibrivoxSourceAdapter.parseBookList({'books': <dynamic>[]}),
        isEmpty,
      );
    });

    test('a book of the catalogue is kept only once', () {
      final answer = {
        'books': [_book(), _book()],
      };

      expect(LibrivoxSourceAdapter.parseBookList(answer), hasLength(1));
    });

    test('the authors of a book are joined into one line', () {
      const twice = {
        'authors': [
          {'first_name': 'Charles', 'last_name': 'Dickens'},
          {'first_name': 'Wilkie', 'last_name': 'Collins'},
        ],
      };

      expect(
        LibrivoxSourceAdapter.bookAuthorOf(twice),
        'Charles Dickens / Wilkie Collins',
      );
      expect(LibrivoxSourceAdapter.bookAuthorOf(_book()), 'Charles Dickens');
      expect(LibrivoxSourceAdapter.bookAuthorOf(const {}), isEmpty);
    });

    test('keeps only the books of the language the scan asks for', () {
      final books = [
        _book(),
        {..._book(), 'id': '99', 'language': 'French'},
      ];

      expect(
        LibrivoxSourceAdapter.wantedBooks(books, language: 'french'),
        hasLength(1),
      );
      expect(
        LibrivoxSourceAdapter.wantedBooks(books, language: null),
        hasLength(2),
      );
      expect(
        LibrivoxSourceAdapter.wantedBooks(books, language: '  '),
        hasLength(2),
      );
    });

    test('one item of the feed becomes one chapter of the book', () {
      final songs = LibrivoxSourceAdapter.parseChapterFeed(
        _feedXml(),
        sourceId: 'librivox',
        book: _book(),
      );

      expect(songs, hasLength(2));

      final first = songs.first;
      expect(first.title, 'Chapter 01');
      expect(first.artist, 'Charles Dickens');
      expect(first.album, 'Bleak House');
      expect(first.duration, 26 * 60 * 1000 + 22 * 1000);
      expect(first.trackNumber, 1);
      expect(first.trackTotal, 67);
      expect(first.language, 'English');
      expect(first.year, 1853);
      expect(first.license, 'Public domain');
      expect(
        first.description,
        'Bleak House is a novel The court of Chancery.',
      );
      expect(first.streamUrl, _chapterOne);
      expect(first.externalId, _chapterOne);
      expect(first.uri, 'tune://librivox/${Uri.encodeComponent(_chapterOne)}');
    });

    test('the cover of a book covers its chapters', () {
      final songs = LibrivoxSourceAdapter.parseChapterFeed(
        _feedXml(),
        sourceId: 'librivox',
        book: _book(),
      );

      expect(
        songs.first.artworkUrl,
        'https://archive.org/download/book/cover.jpg',
      );
    });

    test('a chapter without an audio file is not kept', () {
      final feed = _feedXml()
          .replaceFirst(_chapterOne, 'not-a-playable-address')
          .replaceFirst(
            '<media:content url="https://media.example/01.mp3" type="audio/mpeg" />',
            '',
          );

      expect(
        LibrivoxSourceAdapter.parseChapterFeed(
          feed,
          sourceId: 'librivox',
          book: _book(),
        ),
        hasLength(1),
      );
    });

    test('a scan without a keyword reads the list of the catalogue', () async {
      final answers = _Replies([
        {
          'books': [_book()],
        },
        _feedXml(),
      ]);

      final result = await LibrivoxSourceAdapter(
        dio: answers.dio,
      ).scan(_request('librivox', const {}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));
      expect(answers.uris.first.host, 'librivox.org');
      expect(answers.uris.first.path, '/api/feed/audiobooks/');
      expect(answers.uris.first.queryParameters['limit'], '8');
      expect(answers.uris.first.queryParameters.containsKey('title'), isFalse);
    });

    test('a scan with a keyword asks twice, by title and by author', () async {
      final answers = _Replies([
        {
          'books': [_book()],
        },
        {'error': 'Audiobooks could not be found'},
        _feedXml(),
      ]);

      final result = await LibrivoxSourceAdapter(
        dio: answers.dio,
      ).scan(_request('librivox', const {'query': 'Dickens'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, hasLength(2));
      expect(answers.uris, hasLength(3));
      final searched = answers.uris.take(2);
      expect(
        searched.any((uri) => uri.queryParameters['title'] == 'Dickens'),
        isTrue,
      );
      expect(
        searched.any((uri) => uri.queryParameters['author'] == 'Dickens'),
        isTrue,
      );
      expect(
        searched.every((uri) => uri.queryParameters['limit'] == '8'),
        isTrue,
      );
    });

    test('a keyword that answers nothing reads as no book found', () async {
      final answers = _Replies([
        {'error': 'Audiobooks could not be found'},
        {'error': 'Audiobooks could not be found'},
      ]);

      final result = await LibrivoxSourceAdapter(
        dio: answers.dio,
      ).scan(_request('librivox', const {'query': 'nothing'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.librivoxNoMatch);
    });

    test('a language that keeps no book reads as no book found', () async {
      final answers = _Replies([
        {
          'books': [
            _book(),
            _book('French book', 'https://librivox.org/rss/999'),
          ],
        },
      ]);

      final result = await LibrivoxSourceAdapter(
        dio: answers.dio,
      ).scan(_request('librivox', const {'language': 'Japanese'}));

      expect(result.status, SourceScanStatus.success);
      expect(result.songs, isEmpty);
      expect(result.message, AppStrings.instance.librivoxNoMatch);
    });
  });

  group('Emby adapter', () {
    test('the address of a server keeps its prefix out of the way', () {
      expect(
        EmbySourceAdapter.normalizeServer('192.168.1.10:8095/emby/'),
        'http://192.168.1.10:8095',
      );
      expect(
        EmbySourceAdapter.normalizeServer(' http://host.example:8095/ '),
        'http://host.example:8095',
      );
      expect(EmbySourceAdapter.normalizeServer('  '), isNull);
      expect(EmbySourceAdapter.normalizeServer(null), isNull);
    });

    test('the addresses of the tracks carry the prefix of the server', () {
      expect(
        EmbySourceAdapter.streamUrlFor('http://localhost:8095', '42'),
        'http://localhost:8095/emby/Audio/42/stream?static=true',
      );
      expect(
        EmbySourceAdapter.artworkUrlFor('http://localhost:8095', '42'),
        'http://localhost:8095/emby/Items/42/Images/Primary',
      );
    });

    test('maps the items of the library behind the prefix', () {
      final songs = EmbySourceAdapter.parseItems(
        _embyAnswer(),
        sourceId: 'emby',
        server: 'http://localhost:8095',
        token: 'access',
      );

      expect(songs, hasLength(1));
      final song = songs.single;
      expect(song.title, 'In Chancery');
      expect(song.artist, 'Charles Dickens');
      expect(song.duration, 26 * 60 * 1000 + 22 * 1000);
      expect(
        song.streamUrl,
        'http://localhost:8095/emby/Audio/1/stream?static=true',
      );
      expect(
        song.artworkUrl,
        'http://localhost:8095/emby/Items/1/Images/Primary?api_key=access',
      );
      expect(song.httpHeaders?['X-Emby-Token'], 'access');
    });

    test('the token of a login is read out of the answer', () {
      expect(
        EmbySourceAdapter.parseToken({'AccessToken': 'a token'}),
        'a token',
      );
      expect(EmbySourceAdapter.parseToken({'AccessToken': '  '}), isNull);
      expect(EmbySourceAdapter.parseToken(null), isNull);
    });

    test('the app names itself to the server', () {
      expect(
        EmbySourceAdapter.authorizationHeader,
        contains('MediaBrowser Client="Tune"'),
      );
      expect(
        EmbySourceAdapter.authorizationHeader,
        contains('DeviceId="tune"'),
      );
    });

    test('a tick of the server is a hundredth of a millisecond', () {
      expect(
        EmbySourceAdapter.durationFromTicks('15820000000'),
        26 * 60 * 1000 + 22 * 1000,
      );
      expect(EmbySourceAdapter.durationFromTicks(null), 0);
    });
  });
}

/// One book of the LibriVox catalogue.
Map<String, dynamic> _book([String title = 'Bleak House', String? rss]) => {
  'id': '53',
  'title': title,
  'description': '<i>Bleak House</i> is a novel<br />The court of Chancery.',
  'language': 'English',
  'copyright_year': '1853',
  'num_sections': '67',
  'url_rss': rss ?? 'https://librivox.org/rss/53',
  'authors': [
    {
      'id': '1',
      'first_name': 'Charles',
      'last_name': 'Dickens',
      'dob': '1812',
      'dod': '1870',
    },
  ],
};

const _chapterOne =
    'https://archive.org/download/bleak_house/bleak_house_01_dickens_64kb.mp3';

/// The feed of one book, with two chapters and the cover of the book.
String _feedXml() =>
    '''
<?xml version="1.0" ?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
    xmlns:media="http://search.yahoo.com/mrss/" version="2.0">
<channel>
  <title><![CDATA[Bleak House by Charles Dickens (1812 - 1870)]]></title>
  <itunes:image href="https://archive.org/download/book/cover.jpg" />
  <itunes:author>LibriVox</itunes:author>
  <item>
    <title><![CDATA[Chapter 01]]></title>
    <itunes:episode><![CDATA[1]]></itunes:episode>
    <enclosure url="$_chapterOne" length="0" type="audio/mpeg" />
    <itunes:duration><![CDATA[00:26:22]]></itunes:duration>
    <media:content url="https://media.example/01.mp3" type="audio/mpeg" />
  </item>
  <item>
    <title><![CDATA[Chapter 02]]></title>
    <itunes:episode><![CDATA[2]]></itunes:episode>
    <enclosure url="https://archive.org/download/bleak_house/bleak_house_02_dickens_64kb.mp3" length="0" type="audio/mpeg" />
    <itunes:duration><![CDATA[00:30:05]]></itunes:duration>
  </item>
</channel>
</rss>
''';

/// The page of items an Emby server hands back.
Map<String, dynamic> _embyAnswer() => {
  'Items': [
    {
      'Id': '1',
      'Name': 'In Chancery',
      'Album': 'Bleak House',
      'Artists': ['Charles Dickens'],
      'RunTimeTicks': '15820000000',
      'IndexNumber': 1,
      'Genres': ['Fiction'],
      'MediaSources': [
        {'Bitrate': 64000, 'SampleRate': 44100},
      ],
    },
  ],
};

/// One scan of one source.
MusicSourceScanRequest _request(String id, Map<String, String> settings) {
  return MusicSourceScanRequest(
    config: MusicSourceConfig(
      id: id,
      type: id,
      name: id,
      kind: MusicSourceKind.openCatalog,
      settings: settings,
    ),
  );
}

/// A Dio that answers every request with its replies in a loop.
///
/// The adapter of a scan asks the catalogue for books and then the feed of
/// one book per batch, so the replies tell where a request belongs and the
/// requests that were asked are kept for the test to read.
class _Replies {
  _Replies(List<Object> bodies) : _bodies = bodies;

  final List<Object> _bodies;
  var _next = 0;
  final uris = <Uri>[];

  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          uris.add(options.uri);
          final body = _bodies[_next % _bodies.length];
          _next++;
          handler.resolve(
            Response(requestOptions: options, data: body, statusCode: 200),
          );
        },
      ),
    );
    return client;
  }
}
