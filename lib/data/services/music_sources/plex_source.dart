import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/media_server_items.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:xml/xml.dart';

/// A Plex server hosts a whole media library.
///
/// Plex answers in XML instead of JSON and keeps the music behind one section
/// of the library, so a scan finds the music section first and reads the
/// tracks of it. Every address carries the token of the reader.
class PlexSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(50, 200);

  final Dio _dio;

  PlexSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.plain,
              headers: const {'Accept': 'application/xml'},
            ),
          );

  @override
  String get sourceType => 'plex';

  /// Plex serves the music it recently added, so the source is ready once
  /// the server is configured: a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('token') != null;

  @override
  String get configurationHint => AppStrings.instance.plexHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.plexFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'token',
      AppStrings.instance.plexFieldToken,
      AppStrings.instance.plexFieldTokenHint,
      required: true,
      secret: true,
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
  Duration get scanTimeout => const Duration(seconds: 90);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final server = normalizeServer(config.setting('server'));
    final token = config.setting('token');
    if (server == null || token == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = scanLimit.read(config.setting('limit'));
      final keyword = config.setting('query');
      final body = keyword == null
          ? await _recentTracks(server, token, limit, request.offset)
          : await _searchTracks(server, token, keyword, limit, request.offset);
      if (body == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.plexNoMatch,
        );
      }

      final songs = parseTracks(
        body,
        sourceId: config.id,
        server: server,
        token: token,
        limit: limit,
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.plexNoMatch : null,
      );
    } on XmlException catch (error) {
      return failedResult(
        config.id,
        AppStrings.instance.plexInvalidAnswer(error.message),
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// Reads the tracks the server added most recently.
  ///
  /// The music of a Plex library lives in one section, so the section is
  /// looked up first; a server with no music section answers with nothing.
  Future<String?> _recentTracks(
    String server,
    String token,
    int limit,
    int offset,
  ) async {
    final sections = await _dio.get<String>(
      '$server/library/sections',
      queryParameters: {'X-Plex-Token': token},
    );
    final sectionKey = musicSectionKey(sections.data);
    if (sectionKey == null) return null;

    final response = await _dio.get<String>(
      '$server/library/sections/$sectionKey/all',
      queryParameters: {
        'type': '10',
        'X-Plex-Token': token,
        'X-Plex-Container-Start': '$offset',
        'X-Plex-Container-Size': '$limit',
      },
    );
    return response.data;
  }

  /// Searches the whole library.
  Future<String?> _searchTracks(
    String server,
    String token,
    String keyword,
    int limit,
    int offset,
  ) async {
    final response = await _dio.get<String>(
      '$server/library/search',
      queryParameters: {
        'query': keyword,
        'limit': '$limit',
        'X-Plex-Container-Start': '$offset',
        'X-Plex-Token': token,
      },
    );
    return response.data;
  }

  /// Builds a fresh address of a track.
  ///
  /// The address of a file never changes and the token is stored with the
  /// source, so the player already holds a working address.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    return null;
  }

  /// The server address without a trailing slash.
  static String? normalizeServer(String? raw) =>
      MediaServerItems.trimServerAddress(raw);

  /// The key of the music section of a server.
  ///
  /// The library answers with every section it holds; the one whose type is
  /// an artist is the music library.
  static String? musicSectionKey(String? xml) {
    if (xml == null || xml.trim().isEmpty) return null;
    final document = XmlDocument.parse(xml);
    for (final directory in document.findAllElements('Directory')) {
      if (directory.getAttribute('type') == 'artist') {
        final key = directory.getAttribute('key')?.trim() ?? '';
        if (key.isNotEmpty) return key;
      }
    }
    return null;
  }

  /// Kept static so XML mapping can be tested without network access.
  static List<Song> parseTracks(
    String xml, {
    required String sourceId,
    required String server,
    required String token,
    int limit = 50,
  }) {
    final document = XmlDocument.parse(xml);
    final songs = <Song>[];
    final seen = <String>{};

    for (final track in document.findAllElements('Track')) {
      if (songs.length >= limit) break;

      final id = track.getAttribute('ratingKey')?.trim() ?? '';
      final title = track.getAttribute('title')?.trim() ?? '';
      if (id.isEmpty || title.isEmpty || !seen.add(id)) continue;

      final part = _firstPart(track);
      final partKey = part?.getAttribute('key')?.trim() ?? '';
      if (partKey.isEmpty) continue;

      final thumb = track.getAttribute('thumb')?.trim() ?? '';
      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: id,
          title: title,
          artist: track.getAttribute('grandparentTitle')?.trim() ?? '',
          album: track.getAttribute('parentTitle')?.trim() ?? '',
          duration: SourceSongFactory.parseInt(track.getAttribute('duration')),
          streamUrl: '$server$partKey?X-Plex-Token=$token',
          artworkUrl: thumb.isEmpty
              ? null
              : '$server$thumb?X-Plex-Token=$token',
          year: _yearOf(track),
          bitrate: _kbpsOf(track),
          trackNumber: _positiveInt(track.getAttribute('index')),
          discNumber: _positiveInt(track.getAttribute('parentIndex')),
          size: SourceSongFactory.parseInt(part?.getAttribute('size')),
        ),
      );
    }
    return songs;
  }

  static XmlElement? _firstPart(XmlElement track) {
    for (final media in track.findElements('Media')) {
      for (final part in media.findElements('Part')) {
        return part;
      }
    }
    return null;
  }

  static int? _yearOf(XmlElement track) {
    final year = SourceSongFactory.parseInt(
      track.getAttribute('parentYear') ?? track.getAttribute('year'),
    );
    return year > 0 ? year : null;
  }

  /// The bitrate in kbit/s, which the server already counts that way.
  static int? _kbpsOf(XmlElement track) {
    final bitrate = SourceSongFactory.parseInt(track.getAttribute('bitrate'));
    return bitrate > 0 ? bitrate : null;
  }

  static int? _positiveInt(String? raw) {
    final value = SourceSongFactory.parseInt(raw);
    return value > 0 ? value : null;
  }
}
