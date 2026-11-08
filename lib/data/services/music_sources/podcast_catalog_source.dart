import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/podcast_rss_source.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';

/// The open podcast directory of gpodder.
///
/// A podcast is a feed, and the directory knows the feed of every show it
/// lists. A scan therefore searches the directory, takes the feed of each
/// show and reads the newest episodes of every one of them, so the whole
/// podcast world arrives without the reader having to know one feed. The
/// directory is the open one the podcast community keeps, not a store.
class PodcastCatalogSourceAdapter extends MusicSourceAdapter {
  /// How many podcasts a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(5, 10);

  /// How many episodes of one podcast a scan reads, and the most it may.
  ///
  /// A show may publish hundreds of episodes; the cap keeps one of them from
  /// filling the library, and the reader who wants more raises it.
  static const _episodesPerPodcast = MusicSourceLimit(3, 20);

  static const _directoryHost = 'https://gpodder.net';

  final Dio _dio;

  PodcastCatalogSourceAdapter({Dio? dio})
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
  String get sourceType => 'podcast_catalog';

  /// The directory asks nothing of the reader, so it belongs to the top
  /// of the list.
  @override
  bool get featured => true;

  /// Without a keyword the scan reads the shows the directory lists, so the
  /// source is ready as it is: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.podcastCatalogHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.podcastCatalogFieldQueryHint,
    ),
    MusicSourceField(
      'tag',
      AppStrings.instance.podcastCatalogFieldTag,
      AppStrings.instance.podcastCatalogFieldTagHint,
    ),
    MusicSourceField(
      'episodes',
      AppStrings.instance.podcastFieldEpisodes,
      AppStrings.instance.podcastFieldEpisodesHint(
        _episodesPerPodcast.count,
        _episodesPerPodcast.max,
      ),
      numeric: true,
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

  @override
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final keyword = request.config.setting('query');
      final feeds = await _feeds(
        keyword,
        limit,
        tag: request.config.setting('tag'),
      );
      if (feeds.isEmpty) {
        return SourceScanResult(
          sourceId: request.config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.podcastCatalogNoMatch,
        );
      }

      final songs = <String, Song>{};
      const batchSize = 3;
      for (var start = 0; start < feeds.length; start += batchSize) {
        final batch = feeds.skip(start).take(batchSize).toList(growable: false);
        final episodes = await Future.wait([
          for (final feed in batch)
            _episodesOf(
              feed,
              request.config.id,
              _episodesPerPodcast.read(request.config.setting('episodes')),
            ),
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
            ? AppStrings.instance.podcastCatalogNoMatch
            : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// The feeds the directory answers with.
  ///
  /// Without a keyword the directory serves the shows everybody subscribes
  /// to, or the shows of one tag when the reader wrote one; with a keyword it
  /// searches the whole directory.
  Future<List<String>> _feeds(String? keyword, int limit, {String? tag}) async {
    final wanted = tag?.trim().toLowerCase() ?? '';
    final path = keyword != null
        ? '$_directoryHost/search.json'
        : wanted.isNotEmpty
        ? '$_directoryHost/api/2/tag/$wanted/$limit.json'
        : '$_directoryHost/toplist.json';
    final response = await _dio.get<String>(
      path,
      queryParameters: {'q': ?keyword},
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data;
    if (body == null || body.trim().isEmpty) return const [];

    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return parseFeedUrls(decoded).take(limit).toList(growable: false);
  }

  /// The newest episodes of one feed.
  Future<List<Song>> _episodesOf(
    String feed,
    String sourceId,
    int episodes,
  ) async {
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
        limit: episodes,
      );
    } catch (error) {
      // One broken feed should not fail the whole catalogue.
      Log.error('播客目录读取单集失败: $error');
      return const [];
    }
  }

  /// The feed of every show the directory answered with.
  static List<String> parseFeedUrls(List<dynamic> data) {
    final feeds = <String>[];
    final seen = <String>{};
    for (final raw in data) {
      if (raw is! Map) continue;
      final feed = SourceSongFactory.normalizeUrl(raw['url']?.toString());
      if (feed == null || !seen.add(feed)) continue;
      feeds.add(feed);
    }
    return feeds;
  }
}
