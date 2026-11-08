import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// The podcast directory of Apple.
///
/// The directory answers two questions without a key: which shows are ranked
/// highest in a storefront, and which shows match a keyword. A show is not an
/// episode, so the adapter takes the feed of every show it found and reads the
/// newest episodes of the feed: the episodes themselves always come from the
/// broadcaster, never from Apple.
class PodcastAppleSourceAdapter extends MusicSourceAdapter {
  /// How many shows a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(5, 10);

  /// How many episodes of one show a scan reads.
  static const _episodesPerPodcast = 3;

  static const _chartsHost = 'https://itunes.apple.com';
  static const _searchHost = 'https://itunes.apple.com/search';
  static const _lookupHost = 'https://itunes.apple.com/lookup';

  final Dio _dio;

  PodcastAppleSourceAdapter({Dio? dio})
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
  String get sourceType => 'podcast_apple';

  /// The directory asks nothing of the reader, so it belongs to the top of
  /// the list.
  @override
  bool get featured => true;

  /// Without a keyword the scan reads the shows Apple ranks highest, so the
  /// source is ready as it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.podcastAppleHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.podcastAppleFieldQueryHint,
    ),
    MusicSourceField(
      'country',
      AppStrings.instance.podcastAppleFieldCountry,
      AppStrings.instance.podcastAppleFieldCountryHint,
      defaultValue: 'US',
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitPodcasts,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  /// A scan reads the feed of every show it found, so it runs longer than a
  /// scan of one catalogue.
  @override
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final country = _countryOf(request.config);
      final keyword = request.config.setting('query')?.trim() ?? '';

      final feeds = keyword.isEmpty
          ? await _chartFeeds(country, limit)
          : await _searchFeeds(keyword, country, limit);
      if (feeds.isEmpty) {
        return SourceScanResult(
          sourceId: request.config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.podcastAppleNoMatch,
        );
      }

      final songs = <String, Song>{};
      const batchSize = 3;
      for (var start = 0; start < feeds.length; start += batchSize) {
        final batch = feeds.skip(start).take(batchSize).toList(growable: false);
        final episodes = await Future.wait([
          for (final feed in batch) _episodesOf(feed, request.config.id),
        ]);
        for (final episode in episodes) {
          for (final song in episode) {
            songs[song.uri] = song;
          }
        }
        request.onProgress?.call(
          ((start + batch.length) / feeds.length).clamp(0, 1),
        );
      }

      final archive = songs.values.toList(growable: false);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: archive,
        message: archive.isEmpty
            ? AppStrings.instance.podcastAppleNoMatch
            : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// The feeds of the shows Apple ranks highest in a storefront.
  ///
  /// The chart answer names the shows by their Apple id; the feed of a show
  /// comes from one lookup of those ids, and the chart order is kept so the
  /// top show is read first.
  Future<List<String>> _chartFeeds(String country, int limit) async {
    final response = await _dio.get<String>(
      '$_chartsHost/${country.toLowerCase()}/rss/toppodcasts/limit=$limit/json',
      options: Options(responseType: ResponseType.plain),
    );
    final ids = parseTopIds(_decode(response.data));
    if (ids.isEmpty) return const [];

    final lookup = await _dio.get<String>(
      _lookupHost,
      queryParameters: {'id': ids.join(',')},
      options: Options(responseType: ResponseType.plain),
    );
    return parseLookupFeeds(_decode(lookup.data), order: ids);
  }

  /// The feeds of the shows that match a keyword in a storefront.
  Future<List<String>> _searchFeeds(
    String keyword,
    String country,
    int limit,
  ) async {
    final response = await _dio.get<String>(
      _searchHost,
      queryParameters: {
        'media': 'podcast',
        'term': keyword,
        'limit': '$limit',
        'country': country,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return parseSearchFeeds(_decode(response.data)).take(limit).toList(
      growable: false,
    );
  }

  /// The newest episodes of one feed.
  Future<List<Song>> _episodesOf(String feed, String sourceId) async {
    try {
      final response = await _dio.get<String>(
        feed,
        // A feed that does not answer within a few seconds is not worth the
        // wait of the whole scan.
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) return const [];
      return PodcastRssSourceAdapter.parseFeed(
        body,
        sourceId: sourceId,
        limit: _episodesPerPodcast,
      );
    } catch (error) {
      // One broken feed should not fail the whole directory.
      Log.error('Apple 播客读取单集失败: $error');
      return const [];
    }
  }

  /// The ids of the shows of a chart answer, in the order of the chart.
  static List<String> parseTopIds(Map<String, dynamic>? data) {
    final feed = data?['feed'];
    final entries = feed is Map ? feed['entry'] : null;
    if (entries is! List) return const [];

    final ids = <String>[];
    final seen = <String>{};
    for (final raw in entries) {
      if (raw is! Map) continue;
      final id = raw['id'];
      final attributes = id is Map ? id['attributes'] : null;
      final value = attributes is Map ? attributes['im:id']?.toString() : null;
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed)) continue;
      ids.add(trimmed);
    }
    return ids;
  }

  /// The feeds of a lookup answer, in the order of [order] when it is known.
  static List<String> parseLookupFeeds(
    Map<String, dynamic>? data, {
    List<String>? order,
  }) {
    final results = data?['results'];
    if (results is! List) return const [];

    final byId = <String, String>{};
    for (final raw in results) {
      if (raw is! Map) continue;
      final id = raw['collectionId']?.toString();
      final feed = _feedOf(raw);
      if (id == null || feed == null) continue;
      byId[id] = feed;
    }

    if (order == null) return byId.values.toList(growable: false);
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// The feeds of a search answer.
  static List<String> parseSearchFeeds(Map<String, dynamic>? data) {
    final results = data?['results'];
    if (results is! List) return const [];

    final feeds = <String>[];
    final seen = <String>{};
    for (final raw in results) {
      if (raw is! Map) continue;
      final feed = _feedOf(raw);
      if (feed == null || !seen.add(feed)) continue;
      feeds.add(feed);
    }
    return feeds;
  }

  static String? _feedOf(Map raw) {
    final feed = raw['feedUrl']?.toString().trim() ?? '';
    return feed.startsWith('http://') || feed.startsWith('https://')
        ? feed
        : null;
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

  /// The storefront the reader picked, US when none was picked.
  static String _countryOf(MusicSourceConfig config) {
    final value = config.setting('country')?.trim().toUpperCase() ?? '';
    return value.isEmpty ? 'US' : value;
  }
}
