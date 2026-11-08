import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// The catalogue of Deezer.
///
/// The public API needs no key: it answers a keyword with the songs of the
/// catalogue, and serves the charts of every reach by itself. What it hands
/// out is a thirty-second preview of each song rather than the song, so the
/// tracks of this source are previews: the length of a track is the length of
/// the preview, and the album and the full length ride along in the details.
class DeezerSourceAdapter extends MusicSourceAdapter {
  /// How many songs one scan reads, and the most it may read.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(20, 50);

  /// The length of a preview, in milliseconds.
  static const _previewLength = 30000;

  /// How many albums the album mode reads in one scan.
  ///
  /// An album is read whole, so a scan that walked many of them would fill the
  /// library with one reader's keyword; three albums keep the scan readable
  /// while still handing over complete records.
  static const _albumsPerScan = 3;

  /// The name of the album mode.
  static const _modeAlbums = 'albums';

  /// The name of the artist mode.
  static const _modeArtists = 'artists';

  /// The name of the playlist mode.
  static const _modePlaylists = 'playlists';

  /// How many playlists the playlist mode reads in one scan.
  static const _playlistsPerScan = 3;

  /// How many artists the artist mode reads in one scan.
  static const _artistsPerScan = 3;

  /// The reaches the charts are read for, by the name the reader picks.
  ///
  /// The catalogue names a reach by a number, so the numbers live here and
  /// only the reaches whose chart answered with songs are offered.
  static const _reaches = <String, int>{
    'jazz': 129,
    'pop': 132,
    'rock': 152,
    'classical': 98,
    'metal': 464,
    'electro': 106,
    'rap': 116,
    'soul': 165,
    'reggae': 144,
    'folk': 466,
    'dance': 113,
    'alternative': 85,
    'films': 173,
    'soulfunk': 169,
    'african': 2,
    'asian': 16,
    'blues': 153,
    'brazilian': 75,
    'indian': 81,
    'kids': 95,
    'latin': 197,
  };

  final Dio _dio;

  DeezerSourceAdapter({Dio? dio})
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
  String get sourceType => 'deezer';

  /// The source asks nothing of the reader, so it belongs to the top of the
  /// list.
  @override
  bool get featured => true;

  /// Without a keyword the scan reads the charts the catalogue serves itself,
  /// so a keyword is a choice, not a requirement.
  @override
  List<String> get browseModes => const [BrowseMode.charts];

  @override
  bool isConfigured(MusicSourceConfig config) => true;

  @override
  String get configurationHint => AppStrings.instance.deezerHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.deezerFieldQueryHint,
    ),
    MusicSourceField(
      'mode',
      AppStrings.instance.deezerFieldMode,
      AppStrings.instance.deezerFieldModeHint,
      choices: [
        MusicSourceChoice('songs', AppStrings.instance.deezerModeSongs),
        MusicSourceChoice(_modeAlbums, AppStrings.instance.deezerModeAlbums),
        MusicSourceChoice(_modeArtists, AppStrings.instance.deezerModeArtists),
        MusicSourceChoice(
          _modePlaylists,
          AppStrings.instance.deezerModePlaylists,
        ),
      ],
    ),
    MusicSourceField(
      'genre',
      AppStrings.instance.deezerFieldGenre,
      AppStrings.instance.deezerFieldGenreHint,
      choices: [
        MusicSourceChoice('', AppStrings.instance.deezerGenreAll),
        for (final reach in _reaches.keys)
          MusicSourceChoice(reach, _reachLabel(reach)),
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

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final keyword = config.setting('query')?.trim() ?? '';

    try {
      final limit = scanLimit.read(config.setting('limit'));
      final reach = _reaches[config.setting('genre')?.trim().toLowerCase()];
      final mode = config.setting('mode');
      final wantsPlaylists = mode == _modePlaylists;

      if (wantsPlaylists) {
        final songs = await _playlistSongs(
          keyword: keyword,
          sourceId: config.id,
          limit: limit,
        );
        if (songs == null) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: AppStrings.instance.deezerEmptyResponse,
          );
        }
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          songs: songs,
          message: songs.isEmpty ? AppStrings.instance.deezerNoMatch : null,
        );
      }

      final wantsArtists = mode == _modeArtists;

      if (wantsArtists) {
        final songs = await _artistSongs(
          keyword: keyword,
          sourceId: config.id,
          limit: limit,
        );
        if (songs == null) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: AppStrings.instance.deezerEmptyResponse,
          );
        }
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          songs: songs,
          message: songs.isEmpty ? AppStrings.instance.deezerNoMatch : null,
        );
      }

      final wantsAlbums = mode == _modeAlbums;

      if (wantsAlbums) {
        final songs = await _albumSongs(
          keyword: keyword,
          sourceId: config.id,
          limit: limit,
        );
        if (songs == null) {
          return SourceScanResult(
            sourceId: config.id,
            status: SourceScanStatus.failed,
            message: AppStrings.instance.deezerEmptyResponse,
          );
        }
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          songs: songs,
          message: songs.isEmpty ? AppStrings.instance.deezerNoMatch : null,
        );
      }

      final String path;
      if (keyword.isNotEmpty) {
        path = '/search';
      } else if (reach != null) {
        path = '/chart/$reach/tracks';
      } else {
        path = '/chart/0/tracks';
      }

      final response = await _dio.get<String>(
        'https://api.deezer.com$path',
        queryParameters: {
          if (keyword.isNotEmpty) 'q': keyword,
          'limit': '$limit',
          if (request.offset > 0) 'index': '${request.offset}',
        },
        options: Options(responseType: ResponseType.plain),
      );

      final data = _decode(response.data);
      final entries = data?['data'];
      if (entries is! List) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.failed,
          message: AppStrings.instance.deezerEmptyResponse,
        );
      }

      final songs = <Song>[];
      for (final entry in entries) {
        if (entry is! Map) continue;
        final song = songOf(entry, sourceId: config.id);
        if (song != null) songs.add(song);
      }

      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.deezerNoMatch : null,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }




  /// The songs of the playlists the keyword names.
  ///
  /// The catalogue answers the keyword with playlists, so each playlist is
  /// read whole: one request per playlist, and a playlist that answers with
  /// nothing is skipped instead of failing the scan.
  Future<List<Song>?> _playlistSongs({
    required String keyword,
    required String sourceId,
    required int limit,
  }) async {
    final count = limit < _playlistsPerScan ? limit : _playlistsPerScan;
    final List<dynamic> playlists;
    if (keyword.isEmpty) {
      final chart = await _dio.get<String>(
        'https://api.deezer.com/chart/0/playlists',
        queryParameters: {'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(chart.data)?['data'];
      if (entries is! List) return null;
      playlists = entries;
    } else {
      final search = await _dio.get<String>(
        'https://api.deezer.com/search/playlist',
        queryParameters: {'q': keyword, 'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(search.data)?['data'];
      if (entries is! List) return null;
      playlists = entries;
    }

    final songs = <Song>[];
    for (final playlist in playlists) {
      if (playlist is! Map) continue;
      final id = playlist['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final detail = await _dio.get<String>(
        'https://api.deezer.com/playlist/$id',
        options: Options(responseType: ResponseType.plain),
      );
      final tracks = _decode(detail.data)?['tracks'];
      final entries = tracks is Map ? tracks['data'] : null;
      if (entries is! List) continue;

      // A playlist may hold hundreds of songs; the scan keeps the window of
      // the limit so one editorial list does not fill the library.
      var kept = 0;
      for (final entry in entries) {
        if (kept >= limit) break;
        if (entry is! Map) continue;
        final song = songOf(entry, sourceId: sourceId);
        if (song == null) continue;
        songs.add(song);
        kept++;
      }
    }
    return songs;
  }

  /// The most played songs of the artists the keyword names.
  ///
  /// The catalogue answers the keyword with artists rather than songs, so the
  /// top songs of each artist are read: one request per artist, and an artist
  /// without a list is skipped instead of failing the scan.
  Future<List<Song>?> _artistSongs({
    required String keyword,
    required String sourceId,
    required int limit,
  }) async {
    final count = limit < _artistsPerScan ? limit : _artistsPerScan;
    final List<dynamic> artists;
    if (keyword.isEmpty) {
      final chart = await _dio.get<String>(
        'https://api.deezer.com/chart/0/artists',
        queryParameters: {'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(chart.data)?['data'];
      if (entries is! List) return null;
      artists = entries;
    } else {
      final search = await _dio.get<String>(
        'https://api.deezer.com/search/artist',
        queryParameters: {'q': keyword, 'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(search.data)?['data'];
      if (entries is! List) return null;
      artists = entries;
    }

    final songs = <Song>[];
    for (final artist in artists) {
      if (artist is! Map) continue;
      final id = artist['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final top = await _dio.get<String>(
        'https://api.deezer.com/artist/$id/top',
        queryParameters: {'limit': '$limit'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(top.data)?['data'];
      if (entries is! List) continue;

      for (final entry in entries) {
        if (entry is! Map) continue;
        final song = songOf(entry, sourceId: sourceId);
        if (song != null) songs.add(song);
      }
    }
    return songs;
  }

  /// The songs of the albums the keyword names, or of the chart of albums.
  ///
  /// The catalogue answers the keyword with albums rather than songs, so each
  /// album is read whole: one request per album, and the tracks keep the name
  /// of their record even when the track entry names none. Without a keyword
  /// the albums come from the chart the catalogue serves itself.
  Future<List<Song>?> _albumSongs({
    required String keyword,
    required String sourceId,
    required int limit,
  }) async {
    final count = limit < _albumsPerScan ? limit : _albumsPerScan;
    final List<dynamic> albums;
    if (keyword.isEmpty) {
      final chart = await _dio.get<String>(
        'https://api.deezer.com/chart/0/albums',
        queryParameters: {'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(chart.data)?['data'];
      if (entries is! List) return null;
      albums = entries;
    } else {
      final search = await _dio.get<String>(
        'https://api.deezer.com/search/album',
        queryParameters: {'q': keyword, 'limit': '$count'},
        options: Options(responseType: ResponseType.plain),
      );
      final entries = _decode(search.data)?['data'];
      if (entries is! List) return null;
      albums = entries;
    }

    final songs = <Song>[];
    for (final album in albums) {
      if (album is! Map) continue;
      final id = album['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final detail = await _dio.get<String>(
        'https://api.deezer.com/album/$id',
        options: Options(responseType: ResponseType.plain),
      );
      final data = _decode(detail.data);
      if (data == null) continue;
      final tracks = data['tracks'];
      final entries = tracks is Map ? tracks['data'] : null;
      if (entries is! List) continue;

      for (final entry in entries) {
        if (entry is! Map) continue;
        final song = songOf(_withAlbum(entry, data), sourceId: sourceId);
        if (song != null) songs.add(song);
      }
    }
    return songs;
  }

  /// The track entry with what its album knows and the entry does not.
  ///
  /// A track of an album answer carries no album of its own, so the name and
  /// the cover of the record are filled in from the album.
  static Map _withAlbum(Map entry, Map<String, dynamic> album) {
    final merged = Map<String, dynamic>.from(entry);
    final current = merged['album'];
    final albumMap = current is Map ? Map<String, dynamic>.from(current) : <String, dynamic>{};
    albumMap['title'] ??= album['title'];
    albumMap['id'] ??= album['id'];
    albumMap['cover_xl'] ??= album['cover_xl'];
    albumMap['cover_big'] ??= album['cover_big'];
    albumMap['cover_medium'] ??= album['cover_medium'];
    merged['album'] = albumMap;
    final artist = merged['artist'];
    if (artist is! Map || _text(artist['name']) == null) {
      final owner = album['artist'];
      if (owner is Map) merged['artist'] = owner;
    }
    return merged;
  }

  /// The preview address of a track, renewed when the stored one expired.
  ///
  /// The catalogue signs a preview for a while and then refuses it, so the
  /// address is read again from the track itself when the player reports the
  /// stored one dead.
  @override
  Future<Song?> refreshStream(MusicSourceConfig config, Song song) async {
    final id = song.externalId;
    if (id == null || id.isEmpty) return null;
    try {
      final response = await _dio.get<String>(
        'https://api.deezer.com/track/$id',
        options: Options(responseType: ResponseType.plain),
      );
      final data = _decode(response.data);
      if (data == null) return null;
      final preview = SourceSongFactory.normalizeUrl(_text(data['preview']));
      if (preview == null) return null;
      return song.copyWith(streamUrl: preview);
    } catch (error) {
      return null;
    }
  }

  /// The name of a reach in the language of the app.
  static String _reachLabel(String reach) {
    final strings = AppStrings.instance;
    return switch (reach) {
      'jazz' => strings.genreJazz,
      'pop' => strings.genrePop,
      'rock' => strings.genreRock,
      'classical' => strings.genreClassical,
      'metal' => strings.genreMetal,
      'electro' => strings.audiusGenreElectronic,
      'rap' => strings.audiusGenreHipHop,
      'soul' => strings.audiusGenreSoul,
      'reggae' => strings.genreReggae,
      'folk' => strings.genreFolk,
      'dance' => strings.genreDance,
      'alternative' => strings.deezerGenreAlternative,
      'films' => strings.deezerGenreFilms,
      'soulfunk' => strings.deezerGenreSoulFunk,
      'african' => strings.deezerGenreAfrican,
      'asian' => strings.deezerGenreAsian,
      'blues' => strings.deezerGenreBlues,
      'brazilian' => strings.deezerGenreBrazilian,
      'indian' => strings.deezerGenreIndian,
      'kids' => strings.deezerGenreKids,
      'latin' => strings.deezerGenreLatin,
      _ => reach,
    };
  }

  /// One song of the catalogue, or null when it has no preview to play.
  ///
  /// Kept static so the mapping can be tested without network access.
  static Song? songOf(Map raw, {required String sourceId}) {
    final title = _text(raw['title']) ?? _text(raw['title_short']);
    final preview = SourceSongFactory.normalizeUrl(_text(raw['preview']));
    if (title == null || preview == null) return null;

    final id = raw['id']?.toString() ?? preview;
    final album = raw['album'];
    final albumMap = album is Map ? album : const {};
    final artist = raw['artist'];
    final artistMap = artist is Map ? artist : const {};
    final fullDuration = SourceSongFactory.parseInt(raw['duration']);

    return SourceSongFactory.create(
      sourceId: sourceId,
      externalId: id,
      title: title,
      artist: _text(artistMap['name']) ?? '',
      album: _text(albumMap['title']) ?? '',
      // The playable file is a preview, so the track lasts as long as one.
      duration: _previewLength,
      streamUrl: preview,
      artworkUrl: _artworkOf(albumMap),
      description: AppStrings.instance.deezerPreviewNote,
      sourceData: {
        'isPreview': true,
        'fullDurationMs': fullDuration * 1000,
        'albumId': albumMap['id'],
        'link': _text(raw['link']),
      },
    );
  }

  /// The cover of the album of a song, at the size a player shows.
  static String? _artworkOf(Map album) {
    return SourceSongFactory.normalizeUrl(
      _text(album['cover_xl']) ??
          _text(album['cover_big']) ??
          _text(album['cover_medium']),
    );
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
