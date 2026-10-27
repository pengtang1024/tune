import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/utils/plain_text.dart';
import 'package:tune/utils/logger.dart';
import 'package:xml/xml.dart';

/// LibriVox records the public-domain audiobooks its volunteers read.
///
/// The catalogue names books, and one book stores whole chapters behind the
/// feed of its recording: a scan of one book becomes a scan of every chapter
/// of it, so an audiobook arrives as one album with one track per chapter.
class LibrivoxSourceAdapter extends MusicSourceAdapter {
  /// How many books a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(8, 20);

  /// The catalogue endpoint of LibriVox.
  static const _apiHost = 'https://librivox.org/api/feed/audiobooks/';

  /// The languages the catalogue lists on its own pages.
  ///
  /// The catalogue API keeps no language filter, so the scan narrows the
  /// books on the spot; these are the names the books carry as values.
  static const _languages = [
    'English',
    'Chinese',
    'French',
    'German',
    'Spanish',
    'Italian',
    'Japanese',
    'Russian',
    'Portuguese',
  ];

  /// The label of one language, written in the language of the app.
  static String _languageLabel(String language, AppLocalizations strings) =>
      switch (language) {
        'English' => strings.fieldLanguageEnglish,
        'Chinese' => strings.fieldLanguageChinese,
        'French' => strings.fieldLanguageFrench,
        'German' => strings.fieldLanguageGerman,
        'Spanish' => strings.fieldLanguageSpanish,
        'Italian' => strings.fieldLanguageItalian,
        'Japanese' => strings.fieldLanguageJapanese,
        'Russian' => strings.fieldLanguageRussian,
        'Portuguese' => strings.fieldLanguagePortuguese,
        _ => language,
      };

  final Dio _dio;

  LibrivoxSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            ),
          );

  @override
  String get sourceType => 'librivox';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// Without a keyword the scan reads the books everybody listens to — the
  /// default list of the catalogue — so the source is ready as it is.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.librivoxHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.librivoxFieldQueryHint,
    ),
    MusicSourceField(
      'language',
      AppStrings.instance.fieldLanguage,
      AppStrings.instance.fieldLanguageHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.fieldLanguageAll),
        for (final language in _languages)
          MusicSourceChoice(
            language,
            _languageLabel(language, AppStrings.instance),
          ),
      ],
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitBooks,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  /// A whole book is fetched for each of its chapters, so a scan runs
  /// longer than the scan of a song catalogue.
  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    try {
      final limit = scanLimit.read(config.setting('limit'));
      final keyword = config.setting('query');
      final raw = await _rawAnswer(keyword, limit);
      final books = parseBookList(raw);
      if (books.isEmpty) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          message: raw is Map
              ? AppStrings.instance.librivoxNoMatch
              : AppStrings.instance.librivoxEmptyResponse,
        );
      }
      final wanted = wantedBooks(books, language: config.setting('language'));
      if (wanted.isEmpty) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.librivoxNoMatch,
        );
      }
      final songs = await _chaptersOf(
        wanted,
        config: config,
        onProgress: request.onProgress,
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.librivoxNoMatch : null,
      );
    } on XmlException catch (error) {
      return failedResult(
        config.id,
        AppStrings.instance.librivoxInvalidFeed(error.message),
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The raw catalogue answer of one scan.
  ///
  /// A keyword asks the catalogue twice, by title and by author; both
  /// answers count. Without a keyword the scan reads the list the
  /// catalogue serves by itself.
  Future<Object?> _rawAnswer(String? keyword, int limit) async {
    if (keyword != null) {
      final pages = await Future.wait([
        _searchPage('title', keyword, limit),
        _searchPage('author', keyword, limit),
      ]);
      return {
        'books': [...pages[0], ...pages[1]],
      };
    }
    final response = await _dio.get(
      _apiHost,
      queryParameters: {'format': 'json', 'limit': limit},
    );
    return response.data;
  }

  /// One page of the catalogue, an empty page when the keyword missed.
  Future<List<Map<dynamic, dynamic>>> _searchPage(
    String field,
    String value,
    int limit,
  ) async {
    final response = await _dio.get(
      _apiHost,
      queryParameters: {'format': 'json', 'limit': limit, field: value},
    );
    return parseBookList(response.data);
  }

  /// Turns every book into its chapters, read in small batches.
  Future<List<Song>> _chaptersOf(
    List<Map<dynamic, dynamic>> books, {
    required MusicSourceConfig config,
    void Function(double progress)? onProgress,
  }) async {
    final songs = <Song>[];
    const batchSize = 4;
    for (var start = 0; start < books.length; start += batchSize) {
      final batch = books.skip(start).take(batchSize).toList(growable: false);
      final feeds = await Future.wait([
        for (final book in batch) _chapterFeed(book),
      ]);
      for (var i = 0; i < batch.length; i++) {
        final feed = feeds[i];
        if (feed == null || feed.trim().isEmpty) continue;
        songs.addAll(
          parseChapterFeed(feed, sourceId: config.id, book: batch[i]),
        );
      }
      onProgress?.call(((start + batch.length) / books.length).clamp(0, 1));
    }
    return songs;
  }

  /// The chapter feed of one book, or nothing when it cannot be read.
  Future<String?> _chapterFeed(Map<dynamic, dynamic> book) async {
    final rss = SourceSongFactory.normalizeUrl(book['url_rss']);
    if (rss == null) return null;
    try {
      final response = await _dio.get<String>(rss);
      return response.data;
    } catch (error) {
      Log.error('LibriVox 章节列表读取失败: $error');
      return null;
    }
  }

  /// The books of a catalogue page.
  ///
  /// The catalogue wraps its list in `books`; a keyword that finds no book
  /// is answered with a note about the miss, and the note parses into an
  /// empty page. The books are unique by their id.
  static List<Map<dynamic, dynamic>> parseBookList(Object? data) {
    final wrapped = data is Map ? data['books'] : null;
    if (wrapped is! List) return const [];
    final books = <Map<dynamic, dynamic>>[];
    final seen = <String>{};
    for (final item in wrapped) {
      if (item is! Map) continue;
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty || !seen.add(id)) continue;
      books.add(item);
    }
    return books;
  }

  /// The books the language of the scan asks for.
  ///
  /// The catalogue keeps no language filter, so the scan narrows the books
  /// itself; a configuration without a language keeps them all.
  static List<Map<dynamic, dynamic>> wantedBooks(
    List<Map<dynamic, dynamic>> books, {
    String? language,
  }) {
    final wanted = language?.trim() ?? '';
    if (wanted.isEmpty) return books;
    return books
        .where(
          (book) =>
              '${book['language'] ?? ''}'.trim().toLowerCase() ==
              wanted.toLowerCase(),
        )
        .toList(growable: false);
  }

  /// The name of the author of a book.
  ///
  /// The catalogue names the authors as a list of people; the names are
  /// joined into the one line a track list shows.
  static String bookAuthorOf(Map<dynamic, dynamic> book) {
    final authors = book['authors'];
    if (authors is! List) return '';

    final names = <String>[];
    for (final author in authors) {
      if (author is! Map) continue;
      final name = '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'
          .trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names.join(' / ');
  }

  /// Turns the feed of one book into the chapters of the whole recording.
  ///
  /// The feed carries no guid, so a chapter is identified by the address of
  /// its audio file, which the recording does not move.
  static List<Song> parseChapterFeed(
    String xml, {
    required String sourceId,
    required Map<dynamic, dynamic> book,
  }) {
    final document = XmlDocument.parse(xml);
    final channel = _first(document.findAllElements('channel'));
    final bookTitle = '${book['title'] ?? ''}'.trim();
    final catalogueTitle = _text(
      channel == null ? const <XmlElement>[] : [channel],
      'title',
    );
    final album = bookTitle.isNotEmpty ? bookTitle : catalogueTitle;
    final author = bookAuthorOf(book);

    final songs = <Song>[];
    final seen = <String>{};
    for (final item in document.findAllElements('item')) {
      final title = _text([item], 'title');
      if (title.isEmpty) continue;

      final streamUrl = SourceSongFactory.normalizeUrl(_enclosureUrl(item));
      if (streamUrl == null || !seen.add(streamUrl)) continue;

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: streamUrl,
          title: title,
          artist: author,
          album: album,
          duration: _parseDuration(_text([item], 'duration')),
          streamUrl: streamUrl,
          artworkUrl: _artworkOf(item, channel),
          genre: 'Audiobook',
          year: _releaseYear(book),
          trackNumber: _episodeOf(item),
          trackTotal: _sectionsOf(book),
          language: '${book['language'] ?? ''}'.trim(),
          license: 'Public domain',
          description: plainText('${book['description'] ?? ''}'),
        ),
      );
    }
    return songs;
  }

  /// The audio file of a chapter.
  ///
  /// The `enclosure` element is the standard one; the feed also repeats the
  /// address in a media element.
  static String? _enclosureUrl(XmlElement item) {
    final enclosure = _first(item.findElements('enclosure'));
    final url = SourceSongFactory.normalizeUrl(enclosure?.getAttribute('url'));
    if (url != null) return url;

    final media = _first(item.findElements('content', namespace: '*'));
    return SourceSongFactory.normalizeUrl(media?.getAttribute('url'));
  }

  /// The cover of a chapter, which is the cover of the book it belongs to.
  static String? _artworkOf(XmlElement item, XmlElement? channel) {
    final image = _first(item.findElements('image', namespace: '*'));
    final href = SourceSongFactory.normalizeUrl(image?.getAttribute('href'));
    if (href != null) return href;

    return _channelArtwork(channel);
  }

  /// The cover of the whole feed.
  static String? _channelArtwork(XmlElement? channel) {
    if (channel == null) return null;

    final image = _first(channel.findElements('image', namespace: '*'));
    final href = SourceSongFactory.normalizeUrl(image?.getAttribute('href'));
    if (href != null) return href;

    final cover = _first(channel.findElements('image'));
    final url = _first(cover?.findElements('url') ?? const <XmlElement>[]);
    return SourceSongFactory.normalizeUrl(url?.innerText.trim());
  }

  /// The number of the chapter in the book.
  static int? _episodeOf(XmlElement item) {
    final episode = int.tryParse(_text([item], 'episode'));
    return episode == null || episode <= 0 ? null : episode;
  }

  /// The number of chapters the catalogue counts in the book.
  static int? _sectionsOf(Map<dynamic, dynamic> book) {
    final sections = SourceSongFactory.parseInt(book['num_sections']);
    return sections > 0 ? sections : null;
  }

  /// The year the catalogue keeps as the copyright year of the book.
  static int? _releaseYear(Map<dynamic, dynamic> book) {
    final year = SourceSongFactory.parseInt(book['copyright_year']);
    return year > 0 ? year : null;
  }

  /// The length of a chapter, read as `HH:MM:SS`.
  static int _parseDuration(String text) {
    if (text.isEmpty) return 0;

    final parts = text.split(':').map(int.tryParse).toList(growable: false);
    if (parts.isEmpty || parts.any((part) => part == null)) return 0;

    var seconds = 0;
    for (final part in parts) {
      seconds = seconds * 60 + part!;
    }
    return seconds * 1000;
  }

  /// Reads the first matching text of a list of elements.
  static String _text(
    Iterable<XmlElement> elements,
    String name, {
    String fallback = '',
  }) {
    for (final element in elements) {
      final match = _first(element.findElements(name, namespace: '*'));
      final text = match?.innerText.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static XmlElement? _first(Iterable<XmlElement> elements) {
    for (final element in elements) {
      return element;
    }
    return null;
  }
}
