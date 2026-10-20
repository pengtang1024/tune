import 'package:dio/dio.dart';
import 'package:tune/data/services/music_sources/browse_mode.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// Jamendo is an open catalogue of independent music.
///
/// It requires a free Client ID from https://developer.jamendo.com/, so the
/// source stays disabled until the user configures one.
class JamendoSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  JamendoSourceAdapter({Dio? dio})
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
  String get sourceType => 'jamendo';

  /// Jamendo serves its own charts and its own newest releases, so the
  /// source only needs the key it asks for.
  @override
  List<String> get browseModes => const [BrowseMode.charts, BrowseMode.latest];

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('clientId') != null;

  @override
  String get configurationHint => AppStrings.instance.jamendoHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'clientId',
      AppStrings.instance.jamendoFieldClientId,
      AppStrings.instance.jamendoFieldClientIdHint,
      required: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.jamendoFieldQueryHint,
    ),
    MusicSourceField(
      'format',
      AppStrings.instance.fieldFormat,
      AppStrings.instance.jamendoFieldFormatHint,
      choices: const [
        MusicSourceChoice('mp31', 'MP3 · 96 kbps'),
        MusicSourceChoice('mp32', 'MP3 · 192 kbps'),
        MusicSourceChoice('mp3', 'MP3 · 320 kbps'),
      ],
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 35);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final clientId = request.config.setting('clientId');
    if (clientId == null) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final query = request.config.setting('query');
      final parameters = <String, dynamic>{
        'client_id': clientId,
        'format': 'json',
        'limit': 20,
        'order': browseModeOf(request.config) == BrowseMode.latest
            ? 'release_date'
            : 'popularity_total',
        'include': 'musicinfo',
        'audioformat': _format(request.config),
      };
      if (query != null) {
        parameters['search'] = query;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.jamendo.com/v3.0/tracks/',
        queryParameters: parameters,
      );
      final data = response.data;
      if (data == null) {
        return failedResult(request.config.id, AppStrings.instance.jamendoEmptyResponse);
      }

      final songs = parseResults(data, sourceId: request.config.id);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.jamendoNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// The audio format the tracks are delivered in.
  ///
  /// Jamendo offers the same track in three qualities; the catalogue keeps
  /// the one the user picked and falls back to the middle one.
  static String _format(MusicSourceConfig config) {
    final format = config.setting('format');
    if (format == 'mp31' || format == 'mp3') {
      return format!;
    }
    return 'mp32';
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    Map<String, dynamic> data, {
    required String sourceId,
  }) {
    final rawResults = data['results'];
    if (rawResults is! List) return const [];

    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in rawResults) {
      if (raw is! Map) continue;

      final externalId = raw['id']?.toString() ?? '';
      final title = raw['name']?.toString().trim() ?? '';
      final streamUrl = SourceSongFactory.normalizeUrl(
        (raw['audio'] ?? raw['audiodownload'])?.toString(),
      );
      if (externalId.isEmpty ||
          title.isEmpty ||
          streamUrl == null ||
          !seen.add(externalId)) {
        continue;
      }

      final musicInfo = raw['musicinfo'];
      String? genre;
      final genres = <String>[];
      if (musicInfo is Map) {
        final tags = musicInfo['tags'];
        if (tags is Map) {
          final rawGenres = tags['genres'];
          if (rawGenres is List) {
            for (final item in rawGenres) {
              final name = item?.toString().trim() ?? '';
              if (name.isNotEmpty) genres.add(name);
            }
          }
        }
        genre = genres.isEmpty ? null : genres.first;
      }

      final releaseDate = raw['releasedate']?.toString() ?? '';
      final year = releaseDate.length >= 4
          ? int.tryParse(releaseDate.substring(0, 4))
          : null;

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: externalId,
          title: title,
          artist: raw['artist_name']?.toString() ?? '',
          album: raw['album_name']?.toString() ?? '',
          duration: SourceSongFactory.parseInt(raw['duration']) * 1000,
          streamUrl: streamUrl,
          artworkUrl:
              raw['album_image']?.toString() ?? raw['image']?.toString(),
          genre: genre,
          genres: genres.isEmpty ? null : genres,
          year: year,
          license: raw['license_ccurl']?.toString(),
        ),
      );
    }

    return songs;
  }
}
