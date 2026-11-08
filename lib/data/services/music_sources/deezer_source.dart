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
