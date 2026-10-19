import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/utils/logger.dart';
import 'package:xml/xml.dart';

/// A podcast feed is a plain RSS document that lists episodes.
///
/// The source takes the address of one feed and turns every episode into a
/// track, so the whole feed becomes playable inside the player. The keyword
/// of the source is not used: a feed already knows what it publishes.
class PodcastRssSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  PodcastRssSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.plain,
              headers: const {'Accept': 'application/rss+xml, application/xml'},
            ),
          );

  @override
  String get sourceId => 'podcast_rss';

  @override
  bool isConfigured(MusicSourceConfig config) => config.setting('feed') != null;

  @override
  String get configurationHint => AppStrings.instance.podcastRssHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'feed',
      AppStrings.instance.podcastRssFieldFeed,
      AppStrings.instance.podcastRssFieldFeedHint,
      required: true,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.podcastRssFieldLimit,
      AppStrings.instance.podcastRssFieldLimitHint,
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 45);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final feed = request.config.setting('feed');
    if (feed == null) {
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = _readLimit(request.config);
      final response = await _dio.get<String>(feed);
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(sourceId, AppStrings.instance.podcastRssEmptyFeed);
      }

      final songs = parseFeed(body, sourceId: sourceId, limit: limit);
      return SourceScanResult(
        sourceId: sourceId,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.podcastRssNoMatch : null,
      );
    } on XmlException catch (error) {
      return failedResult(
        sourceId,
        AppStrings.instance.podcastRssInvalidFeed(error.message),
      );
    } catch (error) {
      return failedResult(sourceId, error);
    }
  }

  /// Reads the feed again and takes the address of the episode.
  ///
  /// Hosts move their audio files, so the address of an episode stops working
  /// after a while. The feed still knows where the episode lives, so the
  /// player can recover without waiting for the next scan.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final feed = config.setting('feed');
    if (feed == null) return null;

    final externalId = song.externalId ?? '';
    if (externalId.isEmpty) return null;

    try {
      final response = await _dio.get<String>(feed);
      final body = response.data;
      if (body == null || body.trim().isEmpty) return null;

      final document = XmlDocument.parse(body);
      for (final item in document.findAllElements('item')) {
        final guid = _firstText([item], 'guid');
        final enclosure = _enclosureUrl(item);
        if (enclosure == null) continue;

        final matches = guid.isNotEmpty
            ? guid == externalId
            : enclosure == externalId;
        if (!matches) continue;

        return song.copyWith(streamUrl: enclosure);
      }
      return null;
    } catch (error) {
      Log.error('刷新播客地址失败: $error');
      return null;
    }
  }

  int _readLimit(MusicSourceConfig config) {
    final parsed = SourceSongFactory.parseInt(config.setting('limit'));
    if (parsed <= 0) return 20;
    return parsed.clamp(1, 100);
  }

  /// Kept static so feed parsing can be tested without network access.
  static List<Song> parseFeed(
    String xml, {
    required String sourceId,
    int limit = 20,
  }) {
    final document = XmlDocument.parse(xml);
    final channel = _first(document.findAllElements('channel'));
    final podcastTitle = _firstText(
      channel == null ? const <XmlElement>[] : [channel],
      'title',
    );
    final podcastArtwork = _channelArtwork(channel);

    final songs = <Song>[];
    final seen = <String>{};

    for (final item in document.findAllElements('item')) {
      if (songs.length >= limit) break;

      final title = _firstText([item], 'title');
      if (title.isEmpty) continue;

      final streamUrl = _enclosureUrl(item);
      if (streamUrl == null) continue;

      final guid = _firstText([item], 'guid');
      final externalId = guid.isNotEmpty ? guid : streamUrl;
      if (!seen.add(externalId)) continue;

      final published = _firstText([item], 'pubDate');
      final year = _yearOf(published);

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: _firstText([item], 'author', fallback: podcastTitle),
          album: podcastTitle,
          duration: _parseDuration(_firstText([item], 'duration')),
          streamUrl: streamUrl,
          artworkUrl: _artworkUrl(item, podcastArtwork),
          year: year,
        ),
      );
    }

    return songs;
  }

  /// Reads the audio file of an episode.
  ///
  /// `enclosure` is the standard element; feeds that only publish a media
  /// element are supported as well.
  static String? _enclosureUrl(XmlElement item) {
    final enclosure = _first(item.findElements('enclosure'));
    final url = SourceSongFactory.normalizeUrl(enclosure?.getAttribute('url'));
    if (url != null) return url;

    final media = _first(item.findElements('content'));
    return SourceSongFactory.normalizeUrl(media?.getAttribute('url'));
  }

  /// Reads the cover of an episode, falling back to the podcast cover.
  static String? _artworkUrl(XmlElement item, String? podcastArtwork) {
    final image = _first(item.findElements('image', namespace: '*'));
    final href = SourceSongFactory.normalizeUrl(image?.getAttribute('href'));
    if (href != null) return href;

    final thumbnail = _first(item.findElements('thumbnail', namespace: '*'));
    final thumbnailUrl = SourceSongFactory.normalizeUrl(
      thumbnail?.getAttribute('url'),
    );
    if (thumbnailUrl != null) return thumbnailUrl;

    return podcastArtwork;
  }

  /// Reads the cover of the whole feed.
  static String? _channelArtwork(XmlElement? channel) {
    if (channel == null) return null;

    final image = _first(channel.findElements('image', namespace: '*'));
    final href = SourceSongFactory.normalizeUrl(image?.getAttribute('href'));
    if (href != null) return href;

    final cover = _first(channel.findElements('image'));
    final url = _first(cover?.findElements('url') ?? const <XmlElement>[]);
    return SourceSongFactory.normalizeUrl(url?.innerText.trim());
  }

  /// Reads the first matching text of a list of elements.
  static String _firstText(
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

  /// Reads a `HH:MM:SS`, `MM:SS` or plain seconds duration.
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

  /// Reads the year out of a RFC 822 date such as `Tue, 06 Oct 2026 09:00:00`.
  static int? _yearOf(String date) {
    final match = RegExp(r'(\d{4})').firstMatch(date);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
