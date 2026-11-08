import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The catalogue of the iTunes store.
///
/// The store answers a keyword with the songs of its whole catalogue. What it
/// hands out is a thirty-second preview of each song rather than the song, so
/// the tracks of this source are previews: the duration of a track is the
/// length of the preview, and the album and the full length ride along in the
/// details of the track.
class ItunesSourceAdapter extends MusicSourceAdapter {
  /// How many songs one scan reads, and the most it may read.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(10, 50);

  /// The length of a preview, in milliseconds.
  static const _previewLength = 30000;

  /// How many albums the album mode reads in one scan.
  ///
  /// An album is read whole, so a scan that walked many of them would fill the
  /// library with one reader's keyword; three albums keep the scan readable
  /// while still handing over complete records.
  static const _albumsPerScan = 3;

  /// The keyword of the album mode, kept next to the mode it belongs to.
  static const _modeAlbums = 'albums';

  static const _searchUrl = 'https://itunes.apple.com/search';
  static const _lookupUrl = 'https://itunes.apple.com/lookup';

  final Dio _dio;

  ItunesSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  @override
  String get sourceType => 'itunes';

  /// The store has no list of its own: the interface asks for a keyword.
  @override
  List<String> get browseModes => const [];

  /// The store answers only a keyword, so the source is ready once one is
  /// written.
  @override
  bool isConfigured(MusicSourceConfig config) =>
      (config.setting('query')?.trim() ?? '').isNotEmpty;

  @override
  String get configurationHint => AppStrings.instance.itunesHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQuery,
      AppStrings.instance.itunesFieldQueryHint,
      required: true,
    ),
    MusicSourceField(
      'mode',
      AppStrings.instance.itunesFieldMode,
      AppStrings.instance.itunesFieldModeHint,
      choices: [
        MusicSourceChoice(
          'songs',
          AppStrings.instance.itunesModeSongs,
        ),
        MusicSourceChoice(
          _modeAlbums,
          AppStrings.instance.itunesModeAlbums,
        ),
      ],
    ),
    MusicSourceField(
      'country',
      AppStrings.instance.itunesFieldCountry,
      AppStrings.instance.itunesFieldCountryHint,
      defaultValue: 'US',
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final query = config.setting('query')?.trim() ?? '';
    if (query.isEmpty) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = scanLimit.read(config.setting('limit'));
      final country = _countryOf(config);
      final albums = config.setting('mode') == _modeAlbums;

      final decoded = albums
          ? await _albumSongs(
              query: query,
              country: country,
              sourceId: config.id,
              limit: limit,
            )
          : await _songSearch(
              query: query,
              country: country,
              offset: request.offset,
              limit: limit,
            );
      if (decoded == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.itunesEmptyResponse,
        );
      }

      final songs = <Song>[];
      for (final raw in decoded) {
        final song = songOf(raw, sourceId: config.id);
        if (song != null) songs.add(song);
      }

      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.itunesNoMatch : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The songs of the keyword, one entry each.
  Future<List<Map>?> _songSearch({
    required String query,
    required String country,
    required int offset,
    required int limit,
  }) async {
    final response = await _dio.get<String>(
      _searchUrl,
      queryParameters: {
        'media': 'music',
        'entity': 'song',
        'term': query,
        'limit': '$limit',
        'offset': '$offset',
        'country': country,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return _resultsOf(response.data);
  }

  /// The songs of the albums the keyword names.
  ///
  /// The search answers with albums rather than songs, so the albums are
  /// looked up together: one request carries every chosen album id and returns
  /// the tracks of all of them, which keeps a whole record together.
  Future<List<Map>?> _albumSongs({
    required String query,
    required String country,
    required String sourceId,
    required int limit,
  }) async {
    final search = await _dio.get<String>(
      _searchUrl,
      queryParameters: {
        'media': 'music',
        'entity': 'album',
        'term': query,
        'limit': '${limit.clamp(1, _albumsPerScan)}',
        'country': country,
      },
      options: Options(responseType: ResponseType.plain),
    );
    final albums = _resultsOf(search.data);
    if (albums == null) return null;

    final ids = <String>[];
    for (final album in albums) {
      final id = album['collectionId']?.toString();
      if (id != null && id.isNotEmpty && !ids.contains(id)) ids.add(id);
    }
    if (ids.isEmpty) return const [];

    final lookup = await _dio.get<String>(
      _lookupUrl,
      queryParameters: {
        'id': ids.join(','),
        'entity': 'song',
        'limit': '${limit * _albumsPerScan}',
        'country': country,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return _resultsOf(lookup.data);
  }

  /// The entries of the answer, when the answer holds a list.
  static List<Map>? _resultsOf(String? body) {
    final decoded = _decode(body);
    final results = decoded?['results'];
    if (results is! List) return null;
    return results.whereType<Map>().toList(growable: false);
  }

  /// One song of the store, or null when it has no preview to play.
  ///
  /// Kept static so the mapping can be tested without network access.
  static Song? songOf(Map raw, {required String sourceId}) {
    final title = _text(raw['trackName']) ?? _text(raw['collectionName']);
    final preview = SourceSongFactory.normalizeUrl(
      _text(raw['previewUrl']),
    );
    if (title == null || preview == null) return null;

    final id = raw['trackId']?.toString() ?? preview;
    final year = _yearOf(_text(raw['releaseDate']));
    final track = SourceSongFactory.parseInt(raw['trackNumber']);
    final total = SourceSongFactory.parseInt(raw['trackCount']);
    final disc = SourceSongFactory.parseInt(raw['discNumber']);
    final discs = SourceSongFactory.parseInt(raw['discCount']);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id,
      title: title,
      artist: _text(raw['artistName']) ?? '',
      album: _text(raw['collectionName']) ?? '',
      // The playable file is a preview, so the track lasts as long as one.
      duration: _previewLength,
      streamUrl: preview,
      artworkUrl: _artworkOf(_text(raw['artworkUrl100'])),
      genre: _text(raw['primaryGenreName']),
      year: year,
      trackNumber: track > 0 ? track : null,
      trackTotal: total > 0 ? total : null,
      discNumber: disc > 0 ? disc : null,
      totalDisc: discs > 0 ? discs : null,
      description: AppStrings.instance.itunesPreviewNote,
      sourceData: {
        'isPreview': true,
        'fullDurationMs': SourceSongFactory.parseInt(raw['trackTimeMillis']),
        'collectionId': raw['collectionId'],
        'trackViewUrl': _text(raw['trackViewUrl']),
      },
    );
  }

  /// The artwork of a song at a size a player shows.
  ///
  /// The store names the picture at a hundred pixels; the same picture is
  /// served at six hundred when the size in its address is changed.
  static String? _artworkOf(String? raw) {
    final url = SourceSongFactory.normalizeUrl(raw);
    if (url == null) return null;
    return url.replaceAll('100x100bb', '600x600bb');
  }

  static int? _yearOf(String? releaseDate) {
    if (releaseDate == null || releaseDate.length < 4) return null;
    final year = int.tryParse(releaseDate.substring(0, 4));
    return year == null || year <= 0 ? null : year;
  }

  /// The storefront the reader picked, US when none was picked.
  static String _countryOf(MusicSourceConfig config) {
    final value = config.setting('country')?.trim().toUpperCase() ?? '';
    return value.isEmpty ? 'US' : value;
  }

  static Map<String, dynamic>? _decode(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
