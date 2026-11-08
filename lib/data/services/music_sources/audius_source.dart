import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_request_headers.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Audius is an open music network where artists publish their own tracks.
///
/// The public discovery API needs no key and returns complete recordings
/// together with the metadata a listener wants to see: artist, album, genre,
/// mood, release date, licence and the cover of the release.
class AudiusSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 50);

  /// The discovery node that answers searches and hands out stream addresses.
  static const _discoveryHost = 'https://discoveryprovider.audius.co';

  /// The public discovery API asks every caller to name itself.
  static const _appName = 'tune';

  /// The reaches of the trending list, in the names the network uses.
  ///
  /// The name is matched by the network itself, so only the reaches that were
  /// read from it are offered; an unknown name answers with the whole list.
  static const _genres = [
    'Electronic',
    'Hip-Hop/Rap',
    'Jazz',
    'Rock',
    'Pop',
    'R&B/Soul',
    'Classical',
    'Ambient',
    'Techno',
    'House',
    'Dubstep',
    'Folk',
  ];

  /// The windows the trending list may be read over.
  static const _windows = ['week', 'month', 'allTime'];

  final Dio _dio;

  AudiusSourceAdapter({Dio? dio})
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
  String get sourceType => 'audius';

  /// The source asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// Audius serves the tracks everybody plays, so the source is ready as it
  /// is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.audiusHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.audiusFieldQueryHint,
    ),
    MusicSourceField(
      'mode',
      AppStrings.instance.audiusFieldMode,
      AppStrings.instance.audiusFieldModeHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.audiusModeSongs),
        MusicSourceChoice(_modePlaylists, AppStrings.instance.audiusModePlaylists),
      ],
    ),
    MusicSourceField(
      'genre',
      AppStrings.instance.audiusFieldGenre,
      AppStrings.instance.audiusFieldGenreHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.audiusGenreAll),
        for (final genre in _genres)
          MusicSourceChoice(genre, _genreLabel(genre)),
      ],
    ),
    MusicSourceField(
      'window',
      AppStrings.instance.audiusFieldWindow,
      AppStrings.instance.audiusFieldWindowHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.audiusWindowDefault),
        for (final window in _windows)
          MusicSourceChoice(window, _windowLabel(window)),
      ],
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];


  /// The name of the mode that reads playlists instead of single tracks.
  static const _modePlaylists = 'playlists';

  /// How many playlists one scan of the playlist mode reads.
  static const _playlistsPerScan = 3;

  /// The songs of the playlists the site ranks highest, or of the playlists a
  /// keyword is found in.
  ///
  /// A playlist holds dozens of tracks, so the scan keeps the window of the
  /// limit from each of them instead of handing the whole list over.
  Future<SourceScanResult> _playlistsScan(
    MusicSourceScanRequest request, {
    required String? query,
    required int limit,
  }) async {
    final config = request.config;
    try {
      final window = config.setting('window')?.trim() ?? '';
      final catalogues = await _dio.get<Map<String, dynamic>>(
        query == null
            ? '$_discoveryHost/v1/playlists/trending'
            : '$_discoveryHost/v1/playlists/search',
        queryParameters: {
          'app_name': _appName,
          'limit': '$_playlistsPerScan',
          'query': ?query,
          if (query == null && window.isNotEmpty) 'time': window,
        },
      );
      final playlists = catalogues.data?['data'];
      if (playlists is! List) {
        return failedResult(
          config.id,
          AppStrings.instance.audiusEmptyResponse,
        );
      }

      final songs = <Song>[];
      for (final playlist in playlists) {
        if (playlist is! Map) continue;
        final id = playlist['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final tracks = await _dio.get<Map<String, dynamic>>(
          '$_discoveryHost/v1/playlists/$id/tracks',
          queryParameters: {'app_name': _appName},
        );
        final entries = tracks.data?['data'];
        if (entries is! List) continue;
        final fromPlaylist = parseResults(
          {'data': entries},
          sourceId: config.id,
          limit: limit,
        );
        songs.addAll(fromPlaylist);
      }

      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.audiusNoMatch : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The name of a reach in the language of the app.
  static String _genreLabel(String genre) {
    final strings = AppStrings.instance;
    return switch (genre) {
      'Electronic' => strings.audiusGenreElectronic,
      'Hip-Hop/Rap' => strings.audiusGenreHipHop,
      'Jazz' => strings.genreJazz,
      'Rock' => strings.genreRock,
      'Pop' => strings.genrePop,
      'R&B/Soul' => strings.audiusGenreSoul,
      'Classical' => strings.genreClassical,
      'Ambient' => strings.audiusGenreAmbient,
      'Techno' => strings.audiusGenreTechno,
      'House' => strings.audiusGenreHouse,
      'Dubstep' => strings.audiusGenreDubstep,
      'Folk' => strings.genreFolk,
      _ => genre,
    };
  }

  /// The name of a window in the language of the app.
  static String _windowLabel(String window) {
    final strings = AppStrings.instance;
    return switch (window) {
      'week' => strings.audiusWindowWeek,
      'month' => strings.audiusWindowMonth,
      'allTime' => strings.audiusWindowAllTime,
      _ => window,
    };
  }

  @override
  bool get supportsPaging => true;

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 35);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');
    final limit = scanLimit.read(request.config.setting('limit'));

    if (request.config.setting('mode') == _modePlaylists) {
      return _playlistsScan(request, query: query, limit: limit);
    }

    try {
      // Without a keyword the scan pulls the tracks everybody plays; with
      // one it searches for it.
      final browsing = query == null;
      final genre = request.config.setting('genre')?.trim() ?? '';
      final window = request.config.setting('window')?.trim() ?? '';
      final response = await _dio.get<Map<String, dynamic>>(
        browsing
            ? '$_discoveryHost/v1/tracks/trending'
            : '$_discoveryHost/v1/tracks/search',
        queryParameters: browsing
            ? {
                'app_name': _appName,
                'offset': request.offset,
                if (genre.isNotEmpty) 'genre': genre,
                if (window.isNotEmpty) 'time': window,
              }
            : {'query': query, 'app_name': _appName, 'offset': request.offset},
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          request.config.id,
          AppStrings.instance.audiusEmptyResponse,
        );
      }

      final songs = parseResults(
        data,
        sourceId: request.config.id,
        limit: limit,
      );
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.audiusNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
    int limit = 20,
  }) {
    final rawResults = data['data'];
    if (rawResults is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawResults) {
      if (raw is! Map) continue;
      if (songs.length >= limit) break;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['title']?.toString().trim() ?? '';
      if (externalId.isEmpty || title.isEmpty || !seen.add(externalId)) {
        continue;
      }

      final user = raw['user'];
      final artist = user is Map ? user['name']?.toString() ?? '' : '';
      final albumLink = raw['album_backlink'];
      final album = albumLink is Map
          ? albumLink['playlist_name']?.toString() ?? ''
          : '';

      final tags = raw['tags'];
      final genres = tags is String
          ? tags
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(growable: false)
          : const <String>[];

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: artist,
          album: album,
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: streamUrlFor(externalId),
          artworkUrl: _artworkUrl(raw['artwork']),
          genre: raw['genre']?.toString(),
          genres: genres.isEmpty ? null : genres,
          year: _yearOf(raw['release_date']?.toString()),
          license: _licenseOf(raw['license']),
          description: _descriptionOf(raw),
        ),
      );
    }

    return songs;
  }

  /// The address of a track, which stays valid because it is resolved again
  /// on every request instead of carrying a signed link.
  static String streamUrlFor(String externalId) =>
      '$_discoveryHost/v1/tracks/$externalId/stream?app_name=$_appName';

  /// Picks the largest cover the payload offers.
  static String? _artworkUrl(Object? artwork) {
    if (artwork is! Map) return null;
    for (final size in ['1000x1000', '480x480', '150x150']) {
      final url = SourceSongFactory.normalizeUrl(artwork[size]?.toString());
      if (url != null) return url;
    }
    return null;
  }

  static String? _descriptionOf(Map<Object?, Object?> raw) {
    final description = raw['description']?.toString().trim() ?? '';
    return description.isEmpty ? null : description;
  }

  /// The licence of a track, when the network states one.
  static String? _licenseOf(Object? value) {
    final license = value?.toString().trim() ?? '';
    if (license.isEmpty) return null;
    if (license == 'All rights reserved') return null;
    return license;
  }

  /// Reads the year out of a release date such as `2020-06-22T07:04:10Z`.
  static int? _yearOf(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }
}
