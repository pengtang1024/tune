import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// ccMixter is an open catalogue of Creative Commons music and remixes.
///
/// The public API works without a key. The audio files are served with a
/// hotlink check, so every song carries the `Referer` header the site
/// expects; without it the download answers with HTTP 403.
class CcMixterSourceAdapter extends MusicSourceAdapter {
  /// How many tracks a scan fetches, and the most it may fetch.
  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(15, 30);

  static const _endpoint = 'https://ccmixter.org/api/query';
  static const _referer = 'https://ccmixter.org/';

  final Dio _dio;

  CcMixterSourceAdapter({Dio? dio})
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
  String get sourceType => 'ccmixter';

  @override
  bool isConfigured(MusicSourceConfig config) =>
      config.setting('query') != null;

  @override
  String get configurationHint => AppStrings.instance.ccmixterHint;

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'query',
      AppStrings.instance.ccmixterFieldQuery,
      AppStrings.instance.ccmixterFieldQueryHint,
      required: true,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
  ];

  @override
  Duration get autoScanInterval => const Duration(hours: 6);

  @override
  Duration get scanTimeout => const Duration(seconds: 40);

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final query = request.config.setting('query');
    if (query == null) {
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    try {
      final limit = scanLimit.read(request.config.setting('limit'));
      final response = await _dio.get<String>(
        _endpoint,
        queryParameters: {'f': 'json', 'limit': limit, 'tags': query},
        // The API answers with `text/plain`, so the body is decoded here
        // instead of by the transformer.
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data;
      if (body == null || body.trim().isEmpty) {
        return failedResult(
          request.config.id,
          AppStrings.instance.ccmixterEmptyResponse,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return failedResult(
          request.config.id,
          AppStrings.instance.ccmixterEmptyResponse,
        );
      }

      final songs = parseResults(decoded, sourceId: request.config.id);
      return SourceScanResult(
        sourceId: request.config.id,
        status: SourceScanStatus.success,
        songs: songs,
        message: songs.isEmpty ? AppStrings.instance.ccmixterNoMatch : null,
      );
    } catch (error) {
      return failedResult(request.config.id, error);
    }
  }

  /// Kept static so JSON mapping can be tested without network access.
  static List<Song> parseResults(
    List<dynamic> data, {
    required String sourceId,
  }) {
    final songs = <Song>[];
    final seen = <String>{};

    for (final raw in data) {
      if (raw is! Map) continue;

      final uploadId = raw['upload_id']?.toString() ?? '';
      final title = raw['upload_name']?.toString().trim() ?? '';
      if (uploadId.isEmpty || title.isEmpty || !seen.add(uploadId)) continue;

      final file = _pickAudioFile(raw['files']);
      if (file == null) continue;

      final streamUrl = SourceSongFactory.normalizeUrl(
        file['download_url']?.toString(),
      );
      if (streamUrl == null) continue;

      final extra = raw['upload_extra'];
      final extraMap = extra is Map ? extra : const <dynamic, dynamic>{};
      final tags = extraMap['usertags']?.toString() ?? '';
      final genre = _firstTag(tags);
      final license = raw['license_name']?.toString() ?? '';

      songs.add(
        SourceSongFactory.create(
          sourceId: sourceId,
          externalId: uploadId,
          title: title,
          artist: raw['user_name']?.toString() ?? '',
          duration: _parseDuration(file),
          streamUrl: streamUrl,
          genre: genre,
          httpHeaders: const {'Referer': _referer},
          sourceData: {
            'uploadId': uploadId,
            if (license.isNotEmpty) 'license': license,
          },
        ),
      );
    }

    return songs;
  }

  /// Picks the best audio file of an upload.
  ///
  /// An upload also carries the stems of the track and its archive, so only
  /// files that the API marks as audio are usable. MP3 comes first because it
  /// plays everywhere, the other formats stay as a fallback.
  static Map? _pickAudioFile(Object? rawFiles) {
    if (rawFiles is! List) return null;

    Map? fallback;
    for (final raw in rawFiles) {
      if (raw is! Map) continue;
      final format = raw['file_format_info'];
      final formatMap = format is Map ? format : const <dynamic, dynamic>{};
      if (formatMap['media-type']?.toString() != 'audio') continue;
      if (raw['download_url'] == null) continue;

      if (formatMap['mime_type']?.toString() == 'audio/mpeg') return raw;
      fallback ??= raw;
    }

    return fallback;
  }

  static String? _firstTag(String tags) {
    for (final tag in tags.split(',')) {
      final trimmed = tag.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// Reads the playback length the API reports as `m:ss`.
  static int _parseDuration(Map file) {
    final format = file['file_format_info'];
    final formatMap = format is Map ? format : const <dynamic, dynamic>{};
    final text = formatMap['ps']?.toString().trim() ?? '';
    if (text.isEmpty) return 0;

    final parts = text.split(':').map(int.tryParse).toList(growable: false);
    if (parts.isEmpty || parts.any((part) => part == null)) return 0;

    var seconds = 0;
    for (final part in parts) {
      seconds = seconds * 60 + part!;
    }
    return seconds * 1000;
  }
}
