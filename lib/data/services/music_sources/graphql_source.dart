import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/json_source_mapping.dart';
import 'package:tune/data/services/music_sources/json_values.dart';
import 'package:tune/data/services/music_sources/music_source_adapter.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';

/// A source that reads a GraphQL interface the reader points at.
///
/// The reader writes the query document and the variables; the conditions
/// live in the document, not in the mapping. The document is a query, not a
/// script: the app sends it as it is and never runs it.
class GraphqlSourceAdapter extends MusicSourceAdapter {
  final Dio _dio;

  GraphqlSourceAdapter({Dio? dio})
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
  String get sourceType => 'graphql';

  @override
  bool isConfigured(MusicSourceConfig config) {
    return config.setting('url') != null &&
        config.setting('document') != null &&
        JsonSourceMapping.of(config).hasAddress;
  }

  @override
  String get configurationHint => AppStrings.instance.graphqlHint;

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
      'document',
      AppStrings.instance.graphqlFieldQuery,
      AppStrings.instance.graphqlFieldQueryHint,
      required: true,
      multiline: true,
    ),
    MusicSourceField(
      'variables',
      AppStrings.instance.graphqlFieldVariables,
      AppStrings.instance.graphqlFieldVariablesHint,
      multiline: true,
    ),
    MusicSourceField(
      'headers',
      AppStrings.instance.jsonFieldHeaders,
      AppStrings.instance.jsonFieldHeadersHint,
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
    final document = config.setting('document');
    if (url == null || document == null) {
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

    if (!isHttpAddress(url)) {
      return failedResult(
        config.id,
        AppStrings.instance.sourceAddressNotHttp,
      );
    }

    final keyword = config.setting('query') ?? '';
    try {
      final headers = parseJsonHeaders(config.setting('headers') ?? '');
      final variables = _variables(config, keyword);
      final answer = _decode(await _send(url, document, variables, headers));

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

  /// The query, the variables and the headers, in one request.
  Future<Response<String>> _send(
    String url,
    String document,
    Map<String, dynamic> variables,
    Map<String, String> headers,
  ) {
    return _dio.post<String>(
      url,
      data: {'query': document, 'variables': variables},
      options: Options(headers: headers, responseType: ResponseType.plain),
    );
  }

  /// The variables of the query, with the keyword written into them.
  Map<String, dynamic> _variables(MusicSourceConfig config, String keyword) {
    final raw = config.setting('variables');
    if (raw == null) return const {};

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
