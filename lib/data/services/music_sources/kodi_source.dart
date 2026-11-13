import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The music library of a Kodi media centre.
///
/// Kodi answers JSON-RPC at `/jsonrpc`: the newest songs of the library, or
/// the songs a keyword matches. A song is a file on the machine that runs
/// Kodi, so the playable address is the file served by Kodi's web server, and
/// the account that protects the web server rides along as a basic header.
class KodiSourceAdapter extends MusicSourceAdapter {
  /// How many songs one scan reads, and the most it may read.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 100);

  /// The properties a scan reads for every song.
  static const _properties = [
    'title',
    'artist',
    'album',
    'duration',
    'thumbnail',
    'file',
    'genre',
    'year',
    'track',
    'disc',
  ];

  final Dio _dio;

  KodiSourceAdapter({Dio? dio})
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
  String get sourceType => 'kodi';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      normalizeServer(config.setting('server')) != null;

  @override
  String get configurationHint => AppStrings.instance.kodiHint;

  /// Without a keyword the scan reads the songs that joined the library last,
  /// or walks the library album by album.
  @override
  List<String> get browseModes => const [BrowseMode.latest, BrowseMode.albums];

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'server',
      AppStrings.instance.fieldServer,
      AppStrings.instance.kodiFieldServerHint,
      required: true,
    ),
    MusicSourceField(
      'user',
      AppStrings.instance.fieldUser,
      AppStrings.instance.kodiFieldUserHint,
    ),
    MusicSourceField(
      'password',
      AppStrings.instance.fieldPassword,
      AppStrings.instance.kodiFieldPasswordHint,
      secret: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.kodiFieldQueryHint,
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
  Duration get scanTimeout => const Duration(seconds: 60);

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
      final query = config.setting('query')?.trim() ?? '';
      final headers = _authHeader(config);
      final songs = query.isEmpty && browseModeOf(config) == BrowseMode.albums
          ? await _songsOfAlbums(
              server,
              sourceId: config.id,
              offset: request.offset,
              limit: limit,
              headers: headers,
            )
          : await _songs(
              server,
              sourceId: config.id,
              query: query,
              offset: request.offset,
              limit: limit,
              headers: headers,
            );
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.kodiNoMatch : null,
      );
    } on MusicSourceFailure catch (error) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.failed,
        message: error.message,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The songs of one window of the library.
  ///
  /// A keyword asks the library for the songs whose title or artist contains
  /// it; without one the newest songs are read. Both answers carry the files
  /// of the songs, so the playable address is built here.
  Future<List<Song>> _songs(
    String server, {
    required String sourceId,
    required String query,
    required int offset,
    required int limit,
    required String? headers,
  }) async {
    final response = await _dio.post<String>(
      '$server/jsonrpc',
      data: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': query.isEmpty
            ? 'AudioLibrary.GetRecentlyAddedSongs'
            : 'AudioLibrary.GetSongs',
        'params': {
          'properties': _properties,
          'limits': {'start': offset, 'end': offset + limit},
          if (query.isNotEmpty)
            'filter': {
              'or': [
                {'field': 'title', 'operator': 'contains', 'value': query},
                {'field': 'artist', 'operator': 'contains', 'value': query},
              ],
            },
        },
      }),
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.jsonContentType,
        headers: headers == null ? null : {'Authorization': headers},
      ),
    );

    final decoded = _decode(response.data);
    final result = decoded?['result'];
    final rawSongs = result is Map ? result['songs'] : null;
    if (rawSongs is! List) {
      throw MusicSourceFailure(AppStrings.instance.kodiEmptyResponse);
    }

    final songs = <Song>[];
    for (final raw in rawSongs) {
      if (raw is! Map) continue;
      final song = _songOf(
        raw,
        sourceId: sourceId,
        server: server,
        headers: headers,
      );
      if (song != null) songs.add(song);
    }
    return songs;
  }

  /// The songs of the albums of one window, album by album.
  ///
  /// Walking the albums keeps an album together instead of handing out the
  /// songs that happened to join the library last; a song of an album inherits
  /// the album name, the year and the picture when its own entry lacks them.
  Future<List<Song>> _songsOfAlbums(
    String server, {
    required String sourceId,
    required int offset,
    required int limit,
    required String? headers,
  }) async {
    final albums = await _albums(
      server,
      offset: offset,
      limit: limit,
      headers: headers,
    );

    final songs = <Song>[];
    for (final album in albums) {
      final id = SourceSongFactory.parseInt(album['albumid']);
      if (id <= 0) continue;
      final tracks = await _albumSongs(
        server,
        albumId: id,
        sourceId: sourceId,
        headers: headers,
      );
      for (final song in tracks) {
        songs.add(_withAlbum(song, album));
      }
    }
    return songs;
  }

  /// The albums of one window of the library.
  Future<List<Map>> _albums(
    String server, {
    required int offset,
    required int limit,
    required String? headers,
  }) async {
    final decoded = await _call(
      server,
      method: 'AudioLibrary.GetAlbums',
      params: {
        'properties': const [
          'title',
          'artist',
          'year',
          'thumbnail',
          'genre',
          'albumlabel',
        ],
        'limits': {'start': offset, 'end': offset + limit},
      },
      headers: headers,
    );
    final result = decoded?['result'];
    final raw = result is Map ? result['albums'] : null;
    if (raw is! List) {
      throw MusicSourceFailure(AppStrings.instance.kodiEmptyResponse);
    }
    return raw.whereType<Map>().toList(growable: false);
  }

  /// The songs of one album.
  Future<List<Song>> _albumSongs(
    String server, {
    required int albumId,
    required String sourceId,
    required String? headers,
  }) async {
    final decoded = await _call(
      server,
      method: 'AudioLibrary.GetSongs',
      params: {
        'properties': _properties,
        'filter': {'albumid': albumId},
      },
      headers: headers,
    );
    final result = decoded?['result'];
    final raw = result is Map ? result['songs'] : null;
    if (raw is! List) return const [];

    final songs = <Song>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final song = _songOf(
        entry,
        sourceId: sourceId,
        server: server,
        headers: headers,
      );
      if (song != null) songs.add(song);
    }
    return songs;
  }

  /// The song with what its album knows and the song does not.
  static Song _withAlbum(Song song, Map album) {
    final title = _text(album['title']);
    final year = SourceSongFactory.parseInt(album['year']);
    final artwork = _text(album['thumbnail']);

    return song.copyWith(
      album: song.album.isEmpty ? title : null,
      year: song.year == null && year > 0 ? year : null,
      artworkUrl: song.artworkUrl == null && artwork != null
          ? _artworkOf(_serverOf(song.streamUrl), artwork)
          : null,
    );
  }

  /// The server a song of this source points at.
  static String _serverOf(String? streamUrl) {
    final uri = Uri.tryParse(streamUrl ?? '');
    if (uri == null || !uri.hasScheme) return '';
    return '${uri.scheme}://${uri.authority}';
  }

  /// Asks the library one JSON-RPC call and reads the answer.
  Future<Map<String, dynamic>?> _call(
    String server, {
    required String method,
    required Map<String, dynamic> params,
    String? headers,
  }) async {
    final response = await _dio.post<String>(
      '$server/jsonrpc',
      data: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params,
      }),
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.jsonContentType,
        headers: headers == null ? null : {'Authorization': headers},
      ),
    );
    return _decode(response.data);
  }

  /// One song of the library, or null when it has no file to play.
  static Song? _songOf(
    Map raw, {
    required String sourceId,
    required String server,
    required String? headers,
  }) {
    final title = _text(raw['title']) ?? _text(raw['label']);
    final file = _text(raw['file']);
    if (title == null || file == null || !file.startsWith('/')) return null;

    final id = SourceSongFactory.parseInt(raw['songid']);
    final genres = _listOf(raw['genre']);
    final thumbnail = _text(raw['thumbnail']);
    final year = SourceSongFactory.parseInt(raw['year']);
    final track = SourceSongFactory.parseInt(raw['track']);
    final disc = SourceSongFactory.parseInt(raw['disc']);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id > 0 ? id.toString() : file,
      title: title,
      artist: _listOf(raw['artist']).join(' / '),
      album: _text(raw['album']) ?? '',
      duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
      streamUrl: '$server/vfs/${Uri.encodeComponent(file)}',
      artworkUrl: _artworkOf(server, thumbnail),
      genre: genres.isEmpty ? null : genres.first,
      genres: genres.isEmpty ? null : genres,
      year: year > 0 ? year : null,
      trackNumber: track > 0 ? track : null,
      discNumber: disc > 0 ? disc : null,
      httpHeaders: headers == null ? null : {'Authorization': headers},
    );
  }

  /// The address of the picture of a song.
  ///
  /// Kodi names a picture with an `image://` address of its own, which its web
  /// server serves under `/image/`; a picture that is already a web address is
  /// kept as it is.
  static String? _artworkOf(String server, String? thumbnail) {
    if (thumbnail == null) return null;
    if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
      return SourceSongFactory.normalizeUrl(thumbnail);
    }
    return '$server/image/${Uri.encodeComponent(thumbnail)}';
  }

  /// The basic header of the account of the web server, when one was written.
  static String? _authHeader(MusicSourceConfig config) {
    final user = config.setting('user')?.trim() ?? '';
    if (user.isEmpty) return null;
    final password = config.setting('password') ?? '';
    final pair = base64Encode(utf8.encode('$user:$password'));
    return 'Basic $pair';
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

  static List<String> _listOf(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}
