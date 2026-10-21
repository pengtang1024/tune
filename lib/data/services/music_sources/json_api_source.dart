import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/json_source_mapping.dart';
import 'package:tune/data/services/music_sources/json_values.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A source that reads a JSON interface the reader points at.
///
/// The reader writes where the interface lives and where each value sits in
/// the answer. The app asks, reads and maps — it never runs what the reader
/// wrote.
class JsonApiSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  JsonApiSourceAdapter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.plain,
            ),
          );

  @override
  String get sourceType => 'json_api';

  @override
  bool isConfigured(MusicSourceConfig config) {
    return config.setting('url') != null &&
        JsonSourceMapping.of(config).hasAddress;
  }

  @override
  String get configurationHint => AppStrings.instance.jsonApiHint;

  @override
  MusicSourceLimit get scanLimit => const MusicSourceLimit(50, 200);

  @override
  List<MusicSourceField> get configurationFields => [
    MusicSourceField(
      'url',
      AppStrings.instance.jsonFieldUrl,
      AppStrings.instance.jsonFieldUrlHint,
      required: true,
    ),
    MusicSourceField(
      'method',
      AppStrings.instance.jsonApiFieldMethod,
      AppStrings.instance.jsonApiFieldMethodHint,
      choices: const [
        MusicSourceChoice('GET', 'GET'),
        MusicSourceChoice('POST', 'POST'),
      ],
    ),
    MusicSourceField(
      'headers',
      AppStrings.instance.jsonFieldHeaders,
      AppStrings.instance.jsonFieldHeadersHint,
      multiline: true,
    ),
    MusicSourceField(
      'body',
      AppStrings.instance.jsonApiFieldBody,
      AppStrings.instance.jsonApiFieldBodyHint,
      multiline: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQuery,
      AppStrings.instance.jsonFieldQueryHint,
      required: true,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
    ),
    ...jsonMappingFields(),
  ];

  @override
  Future<SourceScanResult> scan(MusicSourceScanRequest request) async {
    final config = request.config;
    final url = config.setting('url');
    if (url == null) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: configurationHint,
      );
    }

    final mapping = JsonSourceMapping.of(config);
    if (!mapping.hasAddress) {
      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.needsConfiguration,
        message: AppStrings.instance.jsonNoAddressPath,
      );
    }

    final keyword = config.setting('query') ?? '';
    try {
      final headers = parseJsonHeaders(config.setting('headers') ?? '');
      final body = _body(config, keyword);
      final answer = _decode(await _send(url, keyword, headers, body));

      final songs = mapping.songs(
        answer,
        sourceId: config.id,
        limit: scanLimit.read(config.setting('limit')),
      );
      if (songs.isEmpty) {
        return SourceScanResult(
          sourceId: config.id,
          status: SourceScanStatus.success,
          message: AppStrings.instance.jsonNoTracks,
        );
      }

      return SourceScanResult(
        sourceId: config.id,
        status: SourceScanStatus.success,
        songs: songs,
      );
    } catch (error) {
      return failedResult(config.id, error);
    }
  }

  /// The request, in the way the reader asked for it.
  Future<Response<String>> _send(
    String url,
    String keyword,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final address = url.replaceAll('\${query}', Uri.encodeComponent(keyword));
    final options = Options(headers: headers, responseType: ResponseType.plain);

    if ((body ?? const {}).isEmpty) {
      return _dio.get<String>(address, options: options);
    }
    return _dio.post<String>(address, data: body, options: options);
  }

  /// The body of the request, with the keyword written into it.
  Map<String, dynamic>? _body(MusicSourceConfig config, String keyword) {
    final raw = config.setting('body');
    if (raw == null) return null;

    final decoded = decodeJsonObject(raw);
    return replaceJsonKeyword(decoded, keyword) as Map<String, dynamic>;
  }

  /// The answer of the interface, decoded.
  Object? _decode(Response<String> response) {
    final text = response.data ?? '';
    try {
      return jsonDecode(text);
    } on FormatException {
      throw MusicSourceFailure(AppStrings.instance.jsonInvalidResponse);
    }
  }
}
