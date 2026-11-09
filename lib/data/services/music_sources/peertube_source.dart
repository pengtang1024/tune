import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/shared/utils/short_description.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// PeerTube is a federated video platform, and a lot of what it hosts is
/// music: concerts, sessions, albums uploaded by the artists themselves.
///
/// The platform has no server of its own, so the reader names the instance to
/// read. The adapter asks that instance for its music category, reads the
/// details of the videos it found, and plays the audio-only version PeerTube
/// transcodes next to the video: a music player has no use for the picture,
/// and the audio file is a fraction of the size.
class PeerTubeSourceAdapter extends MusicSourceAdapter {
  /// How many videos a scan reads, and the most it may read.
  ///
  /// A scan reads the details of every video it keeps — the list answer does
  /// not carry the playable files — so the ceiling stays low on purpose.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(12, 40);

  /// The id of PeerTube's music category.
  static const _musicCategory = 1;

  final Dio _dio;

  PeerTubeSourceAdapter({Dio? dio})
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
  String get sourceType => 'peertube';

  @override
  bool get featured => true;

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null;

  @override
  String get configurationHint => AppStrings.instance.peerTubeHint;

  @override
  List<String> get browseModes => const [
    BrowseMode.charts,
    BrowseMode.latest,
  ];

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.peerTubeFieldServerHint,
      required: true,
      defaultValue: 'https://framatube.org',
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.peerTubeFieldQueryHint,
    ),
    MusicSourceField(
      'category',
      AppStrings.instance.peerTubeCategory,
      AppStrings.instance.peerTubeCategoryHint,
      choices: [
        MusicSourceChoice(
          'music',
          AppStrings.instance.peerTubeCategoryMusic,
        ),
        MusicSourceChoice(
          'all',
          AppStrings.instance.peerTubeCategoryAll,
        ),
      ],
    ),
    MusicSourceField(
      'sort',
      AppStrings.instance.peerTubeFieldSort,
      AppStrings.instance.peerTubeFieldSortHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.peerTubeSortDefault),
        MusicSourceChoice(_sortNewest, AppStrings.instance.peerTubeSortNewest),
        MusicSourceChoice(_sortViewed, AppStrings.instance.peerTubeSortViewed),
      ],
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


  /// The sorts the server reads, by the name the reader picks.
  ///
  /// A search also knows the trending order, but that one answers with
  /// nothing when there is a keyword to read, so it is not offered.
  static const _sortNewest = '-publishedAt';
  static const _sortViewed = '-views';

  /// The sort the reader picked, if any.
  static String? _sortOf(MusicSourceConfig config) {
    final value = config.setting('sort')?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  /// Every video is read once more for its files, so a scan is given more
  /// time than a catalogue that hands the playable address along.
  @override
  Duration get scanTimeout => const Duration(seconds: 120);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    if (server == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = scanLimit.read(config.setting('limit'));
      final query = _queryOf(config);
      final answer = await _videos(
        server,
        query: query,
        offset: request.offset,
        limit: limit,
        charts: browseModeOf(config) == BrowseMode.charts,
        musicOnly: config.setting('category') != 'all',
        sort: _sortOf(config),
      );
      if (answer == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.peerTubeEmptyResponse,
        );
      }

      final songs = await _playable(config.id, server, answer);
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.peerTubeNoMatch : null,
      );
    } on MusicSourceFailure catch (error) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: error.message,
      );
    } on DioException catch (error) {
      return failedResult(config.id, error);
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The videos of one window, or null when the answer is not a list.
  ///
  /// A keyword searches the instance and, through it, the whole federation;
  /// without a keyword the list is the instance's own, ordered by the stream
  /// the instance named.
  Future<List<Map<String, dynamic>>?> _videos(
    String server, {
    required String? query,
    required int offset,
    required int limit,
    required bool charts,
    required bool musicOnly,
    required String? sort,
  }) async {
    final parameters = <String, String>{
      'count': '$limit',
      'start': '$offset',
      'nsfw': 'false',
      if (musicOnly) 'categoryOneOf': '$_musicCategory',
    };

    // A sort the reader picked takes precedence over the one a browsing mode
    // would ask for; without one the mode decides, and a search keeps the
    // relevance order the server serves.
    final Map<String, dynamic>? answer;
    if (query != null) {
      parameters['search'] = query;
      if (sort != null) parameters['sort'] = sort;
      answer = await _get(
        '$server/api/v1/search/videos',
        parameters: parameters,
      );
    } else {
      parameters['sort'] = sort ?? (charts ? _sortViewed : _sortNewest);
      answer = await _get('$server/api/v1/videos', parameters: parameters);
    }

    final raw = answer?['data'];
    if (raw is! List) return null;
    final videos = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map) videos.add(Map<String, dynamic>.from(entry));
    }
    return videos;
  }

  /// The songs of the videos that carry an audio file.
  ///
  /// PeerTube gives the files of a video in its detail answer only, so the
  /// videos are read one by one, in small batches. A video that is live, that
  /// cannot be read or that has no file to play is left out instead of
  /// failing the scan.
  Future<List<Song>> _playable(
    String sourceId,
    String server,
    List<Map<String, dynamic>> videos,
  ) async {
    final songs = <Song>[];
    for (var start = 0; start < videos.length; start += 4) {
      final batch = videos.skip(start).take(4).toList(growable: false);
      final details = await Future.wait(
        batch.map((video) async {
          final uuid = _string(video['uuid']);
          if (uuid == null || video['isLive'] == true) return null;
          try {
            return await _get(
              '$server/api/v1/videos/${Uri.encodeComponent(uuid)}',
            );
          } catch (_) {
            return null;
          }
        }),
      );
      for (final detail in details) {
        if (detail == null) continue;
        final song = _songFrom(detail, sourceId: sourceId, server: server);
        if (song != null) songs.add(song);
      }
    }
    return songs;
  }

  /// One video of an answer, or null when it has nothing to play.
  static Song? _songFrom(
    Map<String, dynamic> raw, {
    required String sourceId,
    required String server,
  }) {
    final uuid = _string(raw['uuid']);
    final title = _string(raw['name']);
    if (uuid == null || title == null) return null;

    final file = _audioFile(raw['files']);
    final streamUrl = _string(file?['fileUrl']);
    if (streamUrl == null) return null;

    final channel = _map(raw['channel']);
    final account = _map(raw['account']);
    final category = _map(raw['category']);
    final licence = _map(raw['licence']);
    final duration = _number(raw['duration']);
    final genres = _genresOf(raw, category);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: uuid,
      title: title,
      artist:
          _string(channel?['displayName']) ??
          _string(account?['displayName']) ??
          '',
      album: '',
      duration: duration == null ? 0 : (duration * 1000).round(),
      streamUrl: streamUrl,
      artworkUrl: _absolute(
        server,
        _string(raw['thumbnailPath']) ?? _string(raw['previewPath']),
      ),
      // The category of a music video is "Music" for all of them, which says
      // nothing the library can group by; the tags the uploader wrote are the
      // only style the video has, and the category stands in when they are
      // empty.
      genre: genres.isEmpty ? null : genres.first,
      genres: genres.isEmpty ? null : genres,
      language: _languageOf(raw['language']),
      year: _yearOf(_string(raw['publishedAt'])),
      size: _number(file?['size'])?.round(),
      license: licence == null || licence['id'] == null
          ? null
          : _string(licence['label']),
      description: _descriptionOf(raw),
      sourceData: {
        'pageUrl': _string(raw['url']),
        'views': _number(raw['views'])?.round(),
      },
    );
  }


  /// The styles a video is filed under, read out of its tags.
  static List<String> _genresOf(
    Map<dynamic, dynamic> raw,
    Map<dynamic, dynamic>? category,
  ) {
    final genres = <String>[];
    final tags = raw['tags'];
    if (tags is List) {
      for (final tag in tags) {
        final name = tag?.toString().trim() ?? '';
        if (name.isNotEmpty && !genres.contains(name)) genres.add(name);
      }
    }
    if (genres.isEmpty) {
      final label = _string(category?['label']);
      if (label != null && label.isNotEmpty) genres.add(label);
    }
    return genres.take(5).toList(growable: false);
  }

  /// The tongue of a video, read out of the language the instance names.
  ///
  /// An instance writes the language as an object with a label; "Unknown" is
  /// what it writes when nobody said, and a track with no known tongue is not
  /// filed under one.
  static String? _languageOf(Object? raw) {
    final label = _string(_map(raw)?['label']);
    if (label == null || label.isEmpty) return null;
    return label.toLowerCase() == 'unknown' ? null : label;
  }

  /// The file to play: the audio-only version when the instance made one,
  /// otherwise the smallest video file that still carries its sound.
  static Map<String, dynamic>? _audioFile(Object? raw) {
    if (raw is! List) return null;

    Map<String, dynamic>? smallest;
    var smallestSize = -1;
    for (final entry in raw) {
      if (entry is! Map) continue;
      final file = Map<String, dynamic>.from(entry);
      if (file['hasAudio'] == false) continue;
      if (_string(file['fileUrl']) == null) continue;

      final resolution = _map(file['resolution']);
      if (_number(resolution?['id']) == 0) return file;

      final size = _number(file['size'])?.round() ?? 0;
      if (smallest == null || (size > 0 && (smallestSize <= 0 || size < smallestSize))) {
        smallest = file;
        smallestSize = size;
      }
    }
    return smallest;
  }

  /// The description of a video without its markdown and line breaks.
  ///
  /// A PeerTube description is written in markdown and may be long; the
  /// details panel is a caption, not the page of the video.
  static String? _descriptionOf(Map<String, dynamic> raw) {
    final text =
        _string(raw['description']) ?? _string(raw['truncatedDescription']);
    if (text == null) return null;
    // A PeerTube description is markdown: the marks are taken out before the
    // beginning of it is kept.
    final markdownFree = text
        .replaceAll(RegExp(r'\r\n|\r|\n'), ' ')
        .replaceAll(RegExp(r'[*_#>\[\]()]'), '');
    return shorten(markdownFree, length: 400);
  }

  /// The keyword of the instance, when the reader wrote one.
  static String? _queryOf(MusicSourceConfig config) {
    final value = config.setting('query') ?? config.setting('keywords');
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int? _yearOf(String? publishedAt) {
    if (publishedAt == null || publishedAt.length < 4) return null;
    final year = int.tryParse(publishedAt.substring(0, 4));
    return year == null || year <= 0 ? null : year;
  }

  /// Asks the server an answer and reads the JSON in it.
  ///
  /// The body is decoded here instead of by the transformer: an address that
  /// is not a PeerTube server answers with a page instead of json, and that
  /// must read as no answer rather than as a broken request.
  Future<Map<String, dynamic>?> _get(
    String url, {
    Map<String, String>? parameters,
  }) async {
    final response = await _dio.get<String>(
      url,
      queryParameters: parameters,
      options: Options(responseType: ResponseType.plain),
    );
    return _decode(response.data);
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

  /// The server address without a trailing slash.
  static String? normalizeServer(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    var address = value;
    while (address.endsWith('/')) {
      address = address.substring(0, address.length - 1);
    }
    return isHttpAddress(address) ? address : null;
  }

  /// The address of an answer, made absolute against the server.
  static String? _absolute(String server, String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.hasScheme) return raw;
    return Uri.parse('$server/').resolveUri(uri).toString();
  }

  static Map<String, dynamic>? _map(Object? raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static String? _string(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static num? _number(Object? raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }
}
