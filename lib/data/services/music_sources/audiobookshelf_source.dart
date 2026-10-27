import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/media_server_items.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// An Audiobookshelf server hosts a library of audiobooks.
///
/// A book holds several audio files, one per chapter or disc, and the server
/// hands every file out with its own address. A scan reads the newest books
/// of the library and turns every file into a track of the book.
class AudiobookshelfSourceAdapter extends MusicSourceAdapter {
  /// How many books a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(8, 20);

  final Dio _dio;

  AudiobookshelfSourceAdapter({Dio? dio})
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
  String get sourceType => 'audiobookshelf';

  /// The server serves the books it added most recently, so the source is
  /// ready once the address and the token are filled in.
  @override
  List<String> get browseModes => const [BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null &&
      config.setting('token') != null;

  @override
  String get configurationHint => AppStrings.instance.audiobookshelfHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.audiobookshelfFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'token',
      AppStrings.instance.audiobookshelfFieldToken,
      AppStrings.instance.audiobookshelfFieldTokenHint,
      required: true,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.audiobookshelfFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimitBooks,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 12);

  @override
  Duration get scanTimeout => const Duration(seconds: 60);

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
      final library = await _bookLibrary(server, token);
      if (library == null) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.audiobookshelfNoMatch,
        );
      }

      final keyword = config.setting('query');
      final response = await _dio.get<Map<String, dynamic>>(
        keyword == null
            ? '$server/api/libraries/${Uri.encodeComponent(library)}/items'
            : '$server/api/libraries/${Uri.encodeComponent(library)}/search',
        queryParameters: {
          'limit': limit,
          if (keyword == null) 'sort': 'addedAt',
          if (keyword == null) 'desc': '1',
          'q': ?keyword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (data == null) {
        return failedResult(
          config.id,
          AppStrings.instance.audiobookshelfEmptyResponse,
        );
      }

      final songs = parseBooks(
        data,
        sourceId: config.id,
        server: server,
        token: token,
        limit: limit,
      );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty
            ? AppStrings.instance.audiobookshelfNoMatch
            : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The id of the audiobook library of a server.
  ///
  /// A server keeps one library per kind of media; the one whose media type
  /// is a book is the one to read.
  Future<String?> _bookLibrary(String server, String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$server/api/libraries',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final libraries = response.data?['libraries'];
    if (libraries is! List) return null;
    for (final library in libraries) {
      if (library is! Map) continue;
      if (library['mediaType'] != 'book') continue;
      final id = library['id']?.toString() ?? '';
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  /// The server address without a trailing slash.
  static String? normalizeServer(String? raw) =>
      MediaServerItems.trimServerAddress(raw);

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseBooks(
    Map<String, dynamic> data, {
    required String sourceId,
    required String server,
    required String token,
    int limit = 8,
  }) {
    final items = _itemsOf(data);
    if (items.isEmpty) return const [];

    final songs = <Song>[];
    for (final item in items) {
      if (songs.length >= limit * 32) break;
      if (item is! Map) continue;
      final media = item['media'];
      if (media is! Map) continue;
      final metadata = media['metadata'];
      final bookTitle = metadata is Map
          ? metadata['title']?.toString().trim() ?? ''
          : '';
      final author = metadata is Map
          ? metadata['authorName']?.toString().trim() ?? ''
          : '';
      if (bookTitle.isEmpty) continue;

      final tracks = media['tracks'];
      if (tracks is! List) continue;
      for (final track in tracks) {
        if (track is! Map) continue;
        final index = SourceSongFactory.parseInt(track['index']);
        final contentUrl = track['contentUrl']?.toString().trim() ?? '';
        final title = track['title']?.toString().trim() ?? '';
        final stream = SourceSongFactory.normalizeUrl(
          contentUrl.startsWith('/') ? '$server$contentUrl' : contentUrl,
        );
        if (stream == null) continue;

        songs.add(
          SourceSongFactory.create(
            sourceId: sourceId,
            externalId: '${item['id'] ?? ''}/$index',
            title: title.isEmpty ? '$bookTitle ${index + 1}' : title,
            artist: author,
            album: bookTitle,
            duration: (SourceSongFactory.parseInt(track['duration']) * 1000)
                .round(),
            streamUrl: '$stream?token=$token',
            artworkUrl: metadata is Map
                ? SourceSongFactory.normalizeUrl(
                    '$server/api/items/${item['id']}/cover?token=$token',
                  )
                : null,
            trackNumber: index + 1,
            trackTotal: tracks.length,
          ),
        );
      }
    }
    return songs.take(limit * 32).toList(growable: false);
  }

  static List<dynamic> _itemsOf(Map<String, dynamic> data) {
    final results = data['results'];
    if (results is List) return results;
    final book = data['book'];
    return book is List ? book : const [];
  }
}
