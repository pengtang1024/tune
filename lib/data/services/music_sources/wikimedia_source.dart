import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/recent_window.dart';
import 'package:tune/data/services/music_sources/source_retry.dart';
import 'package:tune/data/services/music_sources/source_request_headers.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/shared/utils/plain_text.dart';

/// Wikimedia Commons hosts the media files of the Wikipedia projects.
///
/// The search API of the wiki answers with the metadata of every audio file
/// it finds, including the artist, the licence and the download address, so a
/// single request is enough to build a playable track.
class WikimediaSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(15, 30);

  /// The search endpoint of the Commons API.
  static const _apiHost = 'https://commons.wikimedia.org/w/api.php';

  /// Commons keeps its media files in the file namespace.
  static const _fileNamespace = 6;

  /// The category that names the genre of an audio file.
  static const _genreCategory = 'Audio files of';

  /// The categories a scan may walk, by the name the reader picks.
  ///
  /// Commons files its audio under one category per reach; a scan walks the
  /// one the reader picked, or the whole of the music of the wiki.
  static const _categories = <String, String>{
    'all': 'Category:Audio files of music',
    'classical': 'Category:Audio files of classical music',
    'jazz': 'Category:Audio files of jazz music',
    'electronic': 'Category:Audio files of electronic music',
    'folk': 'Category:Audio files of folk music',
    'piano': 'Category:Audio files of piano music',
    'guitar': 'Category:Audio files of guitar music',
    'rock': 'Category:Audio files of rock music',
    'pop': 'Category:Audio files of pop music',
    'hiphop': 'Category:Audio files of hip hop music',
    'country': 'Category:Audio files of country music',
    'blues': 'Category:Audio files of blues',
    'reggae': 'Category:Audio files of reggae',
    'choral': 'Category:Audio files of choral music',
    'organ': 'Category:Audio files of organ music',
    'speeches': 'Category:Audio files of speeches',
    'effects': 'Category:Audio files of sound effects',
    'interviews': 'Category:Audio files of interviews',
    'poetry': 'Category:Audio files of poetry',
    'spoken': 'Category:Spoken Wikipedia',
    'house': 'Category:Audio files of house music',
    'dnb': 'Category:Audio files of drum and bass',
    'ambient': 'Category:Audio files of ambient music',
    'world': 'Category:Audio files of world music',
  };

  /// The category a scan browses when the reader names no keyword.
  static const _browseCategory = 'Category:Audio files of music';

  final Dio _dio;

  WikimediaSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: sourceRequestHeaders(
                extra: const {'Accept': 'application/json'},
              ),
            ),
          );

  @override
  String get sourceType => 'wikimedia';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// Commons asks for no key and serves its own audio categories, so the
  /// source is ready as it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.wikimediaHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.wikimediaFieldQueryHint,
    ),
    MusicSourceField(
      'category',
      AppStrings.instance.wikimediaFieldCategory,
      AppStrings.instance.wikimediaFieldCategoryHint,
      choices: [
        for (final entry in _categories.keys)
          MusicSourceChoice(entry, _categoryLabel(entry)),
      ],
    ),
    MusicSourceField(
      'since',
      AppStrings.instance.recentWindowField,
      AppStrings.instance.recentWindowFieldHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.recentWindowAll),
        for (final days in RecentWindow.days)
          MusicSourceChoice(
            '$days',
            AppStrings.instance.recentWindowDays('$days'),
          ),
      ],
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitFiles,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  /// The name of a category in the language of the app.
  static String _categoryLabel(String category) {
    final strings = AppStrings.instance;
    return switch (category) {
      'classical' => strings.genreClassical,
      'jazz' => strings.genreJazz,
      'electronic' => strings.genreElectronic,
      'folk' => strings.genreFolk,
      'piano' => strings.wikimediaCategoryPiano,
      'guitar' => strings.wikimediaCategoryGuitar,
      'rock' => strings.wikimediaCategoryRock,
      'pop' => strings.wikimediaCategoryPop,
      'hiphop' => strings.wikimediaCategoryHipHop,
      'country' => strings.wikimediaCategoryCountry,
      'blues' => strings.wikimediaCategoryBlues,
      'reggae' => strings.wikimediaCategoryReggae,
      'choral' => strings.wikimediaCategoryChoral,
      'organ' => strings.wikimediaCategoryOrgan,
      'speeches' => strings.wikimediaCategorySpeeches,
      'effects' => strings.wikimediaCategoryEffects,
      'interviews' => strings.wikimediaCategoryInterviews,
      'poetry' => strings.wikimediaCategoryPoetry,
      'spoken' => strings.wikimediaCategorySpoken,
      'house' => strings.wikimediaCategoryHouse,
      'dnb' => strings.wikimediaCategoryDnb,
      'ambient' => strings.wikimediaCategoryAmbient,
      'world' => strings.wikimediaCategoryWorld,
      _ => strings.wikimediaCategoryAll,
    };
  }

  /// Only the search stream knows where the next window starts; the category
  /// stream walks a list with a continuation token, which an offset cannot
  /// name.
  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 45);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final keyword = request.config.setting('query');
    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      // The wiki answers a request it finds too frequent with a 429 and a
      // note asking the caller to slow down; the read is given a few more
      // tries before the scan counts as failed.
      final response = await retrySourceRead(
        () => _dio.get<Map<String, dynamic>>(
          _apiHost,
        queryParameters: keyword == null
            ? {
                // Without a keyword the scan walks a category of the wiki.
                'action': 'query',
                'format': 'json',
                'generator': 'categorymembers',
                'gcmtitle': _categoryOf(request.config),
                'gcmtype': 'file',
                'gcmnamespace': _fileNamespace,
                'gcmlimit': limit,
                if (request.cursor != null) 'gcmcontinue': request.cursor,
                'prop': 'imageinfo',
                'iiprop': 'url|size|mime|mediatype|metadata|extmetadata|timestamp',
              }
            : {
                'action': 'query',
                'format': 'json',
                'generator': 'search',
                'gsrsearch': searchTerm(keyword),
                'gsrnamespace': _fileNamespace,
                'gsrlimit': limit,
                if (request.offset > 0) 'gsroffset': request.offset,
                'prop': 'imageinfo',
                'iiprop': 'url|size|mime|mediatype|metadata|extmetadata|timestamp',
              },
        ),
        // The wiki answers with an empty page when it could not read the
        // request at all, which is worth one more try as well.
        answered: (answer) => answer.data != null,
        // A scan of the app walks the categories of the commons one after the
        // other, and the wiki counts a caller per minute: the waits are long
        // enough to step outside the window it closes.
        delays: const [Duration(seconds: 2), Duration(seconds: 6)],
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          request.config.id,
          AppStrings.instance.wikimediaEmptyResponse,
        );
      }
      final songs = parseResults(
        data,
        sourceId: request.config.id,
        limit: limit,
        since: RecentWindow.cutoff(request.config.setting('since')),
      );
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.wikimediaNoMatch : null,
        cursor: _nextCursor(data),
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// The category the instance walks.
  static String _categoryOf(MusicSourceConfig config) {
    final chosen = config.setting('category');
    return _categories[chosen] ?? _browseCategory;
  }

  /// The token the next window of the category walk starts at.
  ///
  /// The search stream answers with an offset instead, so only the category
  /// walk carries a cursor.
  static String? _nextCursor(Map<String, dynamic> data) {
    final continuation = data['continue'];
    if (continuation is! Map) return null;
    final token = continuation['gcmcontinue']?.toString().trim() ?? '';
    return token.isEmpty ? null : token;
  }

  /// The search term of the wiki.
  ///
  /// The file type filter keeps images and videos out of the answer, and the
  /// keyword narrows it down when the user typed one.
  static String searchTerm(String? keyword) {
    final query = keyword?.trim() ?? '';
    return query.isEmpty ? 'filetype:audio' : 'filetype:audio $query';
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
    int limit = 15,
    DateTime? since,
  }) {
    final query = data['query'];
    final pages = query is Map ? query['pages'] : null;
    if (pages is! Map) return const [];

    final songs = <Song>[];
    final seen = <String>{};
    for (final page in pages.values) {
      if (songs.length >= limit) break;
      if (page is! Map) continue;
      // The wiki stamps a file with the moment it was uploaded; a file older
      // than the window is left out, one without the stamp is kept.
      if (since != null) {
        final added = RecentWindow.dateTimeOf(_uploadedAt(page));
        if (added != null && added.isBefore(since)) continue;
      }
      final song = _songOf(page, sourceId: sourceId);
      if (song == null || !seen.add(song.externalId ?? '')) continue;
      songs.add(song);
    }
    return songs;
  }


  /// The moment a file was uploaded, from the stamp of its image info.
  static Object? _uploadedAt(Object? page) {
    if (page is! Map) return null;
    final infos = page['imageinfo'];
    if (infos is! List || infos.isEmpty) return null;
    final info = infos.first;
    return info is Map ? info['timestamp'] : null;
  }

  /// Turns one page of the answer into a track.
  ///
  /// Only audio files that carry a download address can be played, so every
  /// other page is dropped.
  static Song? _songOf(Map<dynamic, dynamic> page, {required String sourceId}) {
    final infos = page['imageinfo'];
    if (infos is! List || infos.isEmpty) return null;
    final info = infos.first;
    if (info is! Map) return null;
    if (!_isAudio(info)) return null;

    final streamUrl = _streamUrl(info['url']);
    if (streamUrl == null) return null;

    final raw = info['extmetadata'];
    final meta = raw is Map ? raw : const <dynamic, dynamic>{};
    final file = page['title']?.toString().trim() ?? '';
    final name = _meta(meta, 'ObjectName');
    final title = name.isNotEmpty
        ? name
        : file.replaceFirst('File:', '').trim();
    if (title.isEmpty) return null;

    // A file sits in several categories at once, and more than one of them
    // names a style ("Audio files of jazz", "Audio files of piano"): the
    // track keeps them all and the first stands for its main style.
    final genres = _genresOf(meta);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: file.isNotEmpty ? file : title,
      title: title,
      artist: _meta(meta, 'Artist'),
      duration: _durationOf(info['duration']),
      streamUrl: streamUrl,
      genre: genres.isEmpty ? null : genres.first,
      genres: genres.isEmpty ? null : genres,
      year: _yearOf(_meta(meta, 'DateTimeOriginal')),
      license: _licenseOf(meta),
      description: _emptyToNull(_meta(meta, 'ImageDescription')),
      size: _sizeOf(info['size']),
    );
  }

  /// Whether the file holds audio.
  ///
  /// The media type is the reliable answer, but the mime type still tells the
  /// kind of the file when the answer leaves the media type out.
  static bool _isAudio(Map<dynamic, dynamic> info) {
    final type = info['mediatype']?.toString();
    if (type != null) return type == 'AUDIO';
    return (info['mime']?.toString() ?? '').startsWith('audio/');
  }

  /// The text of a metadata field.
  ///
  /// The API wraps every value in an object that also names its source.
  static String _meta(Map<dynamic, dynamic> meta, String key) {
    final value = meta[key];
    final text = value is Map ? value['value'] : value;
    return stripHtml('${text ?? ''}');
  }

  /// The download address of a file without its tracking parameters.
  static String? _streamUrl(Object? raw) {
    final url = '${raw ?? ''}'.trim();
    if (url.isEmpty) return null;
    final cut = url.indexOf('?');
    final clean = cut < 0 ? url : url.substring(0, cut);
    return SourceSongFactory.normalizeUrl(clean);
  }

  /// The length of a file in milliseconds, the API counts in seconds.
  static int _durationOf(Object? raw) {
    final seconds = raw is num ? raw : double.tryParse('$raw');
    return seconds == null ? 0 : (seconds * 1000).round();
  }

  static int? _sizeOf(Object? raw) {
    final size = SourceSongFactory.parseInt(raw);
    return size > 0 ? size : null;
  }

  /// The licence of a file, falling back to the terms of its use.
  static String? _licenseOf(Map<dynamic, dynamic> meta) {
    final short = _meta(meta, 'LicenseShortName');
    if (short.isNotEmpty) return short;
    return _emptyToNull(_meta(meta, 'UsageTerms'));
  }

  /// The year of a file, taken from the date of the recording.
  static int? _yearOf(String value) =>
      value.length < 4 ? null : int.tryParse(value.substring(0, 4));


  /// The styles a file is filed under, taken from its categories.
  ///
  /// Commons files its audio under one category per reach ("Audio files of
  /// jazz"); a file that sits in more than one of them is filed under all of
  /// them, so the whole list is kept and the reader groups by any of it.
  static List<String> _genresOf(Map<dynamic, dynamic> meta) {
    final categories = _meta(meta, 'Categories');
    final genres = <String>[];
    for (final part in categories.split('|')) {
      final index = part.toLowerCase().indexOf(_genreCategory.toLowerCase());
      if (index < 0) continue;
      final genre = part.substring(index + _genreCategory.length).trim();
      if (genre.isNotEmpty && !genres.contains(genre)) genres.add(genre);
    }
    return genres;
  }

  /// Removes the markup of the wiki markup.
  ///
  /// The metadata is written for the wiki, so the artist and the description
  /// arrive as small HTML fragments that have to be plain text again.
  static String stripHtml(String value) => plainText(value);

  static String? _emptyToNull(String value) => value.isEmpty ? null : value;
}
