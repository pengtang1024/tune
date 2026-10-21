import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/json_mapping_guess.dart';
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
  bool get supportsPreview => true;

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
      advanced: true,
    ),
    MusicSourceField(
      'headers',
      AppStrings.instance.jsonFieldHeaders,
      AppStrings.instance.jsonFieldHeadersHint,
      multiline: true,
      advanced: true,
    ),
    MusicSourceField(
      'body',
      AppStrings.instance.jsonApiFieldBody,
      AppStrings.instance.jsonApiFieldBodyHint,
      multiline: true,
      advanced: true,
    ),
    MusicSourceField(
      'query',
      AppStrings.instance.fieldQueryOptional,
      AppStrings.instance.jsonFieldQueryHint,
    ),
    MusicSourceField(
      'limit',
      AppStrings.instance.fieldLimit,
      AppStrings.instance.fieldLimitHint(scanLimit.count, scanLimit.max),
      numeric: true,
      advanced: true,
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

    if (!isHttpAddress(url)) {
      return failedResult(
        config.id,
        AppStrings.instance.sourceAddressNotHttp,
      );
    }

    final keyword = config.setting('query') ?? '';
    final post = _isPost(config);
    try {
      final answer = await _answer(config, keyword, post);

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

  @override
  Future<SourcePreview?> preview(MusicSourceConfig config) async {
    final url = config.setting('url');
    if (url == null) return null;

    try {
      final keyword = config.setting('query') ?? '';
      final answer = await _answer(config, keyword, _isPost(config));

      final current = JsonSourceMapping.of(config);
      final guessed = guessJsonMapping(answer, current: current);
      final songs = guessed.songs(answer, sourceId: config.id, limit: 5);

      return SourcePreview(
        songs: songs,
        suggestions: jsonPathSuggestions(current: current, guessed: guessed),
        message: songs.isEmpty ? AppStrings.instance.jsonPreviewNoTracks : null,
      );
    } catch (error) {
      return SourcePreview(message: describeSourceError(error));
    }
  }

  /// The answer of the interface, decoded.
  Future<Object?> _answer(
    MusicSourceConfig config,
    String keyword,
    bool post,
  ) async {
    final url = config.setting('url')!;
    final headers = parseJsonHeaders(config.setting('headers') ?? '');
    final body = _body(config, keyword);
    return _decode(await _send(url, keyword, headers, body, post));
  }

  /// The request, in the way the reader asked for it.
  ///
  /// The way the request goes out is the one the form says: a reader who
  /// picked POST gets a POST, with or without a body. A GET carries no body.
  Future<Response<String>> _send(
    String url,
    String keyword,
    Map<String, String> headers,
    Map<String, dynamic>? body,
    bool post,
  ) {
    final address = url.replaceAll('\${query}', Uri.encodeComponent(keyword));
    final options = Options(
      headers: {
        if (post) 'content-type': 'application/json',
        ...headers,
      },
      responseType: ResponseType.plain,
    );

    if (!post) {
      return _dio.get<String>(address, options: options);
    }
    return _dio.post<String>(address, data: body, options: options);
  }

  /// Whether the request goes out as a POST.
  ///
  /// The form says which way the request goes; a reader who wrote nothing
  /// gets a GET.
  bool _isPost(MusicSourceConfig config) {
    final method = (config.setting('method') ?? 'GET').toUpperCase();
    return method == 'POST';
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
