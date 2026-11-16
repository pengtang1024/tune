import 'package:dio/dio.dart';
import 'package:tune/data/services/translation/ollama_models.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/utils/logger.dart';

/// The model names one vendor serves, read from the vendor itself.
///
/// Each dialect publishes its list at its own path and header: the OpenAI
/// chat dialect answers `/models` with a bearer token, Anthropic answers
/// `/models` with `x-api-key`, Gemini answers `/models` with `x-goog-api-key`
/// and prefixes every name with `models/`, and a local Ollama answers
/// `/api/tags` on its server root.
///
/// A list is knowledge the vendor owns. An endpoint that is unreachable or
/// refuses the key throws, so the page says the list could not be read; an
/// answer in another shape yields no name. A vendor without the endpoint is
/// marked in the catalog and never asked, so its button never appears. Either way the page never shows a
/// model the vendor does not serve, and the reader keeps the free-form field.
Future<List<String>> fetchProviderModels({
  required TranslationProvider provider,
  required ProviderCredential credential,
  Dio? dio,
  Duration timeout = const Duration(seconds: 10),
}) async {
  if (provider.isLocalModel || !provider.listsModels) return const [];
  final baseUrl = _baseUrlOf(provider, credential);
  if (baseUrl.isEmpty) return const [];

  final client =
      dio ?? Dio(BaseOptions(connectTimeout: timeout, receiveTimeout: timeout));
  try {
    final names = switch (provider.protocol) {
      TranslationProtocol.openAiChat =>
        provider.id == 'ollama'
            ? await fetchOllamaModels(
                dio: client,
                baseUrl: _withoutVersionSuffix(baseUrl),
                timeout: timeout,
              )
            : await _fetchOpenAi(
                client,
                baseUrl,
                credential,
                provider,
                timeout,
              ),
      TranslationProtocol.anthropicMessages => await _fetchAnthropic(
        client,
        baseUrl,
        credential,
        provider,
        timeout,
      ),
      TranslationProtocol.geminiGenerateContent => await _fetchGemini(
        client,
        baseUrl,
        credential,
        provider,
        timeout,
      ),
    };
    return _unmodifiableNames(names);
  } catch (error) {
    // The page reports the failure and keeps its free-form field.
    Log.debug('models: reading the list of ${provider.id} failed: $error');
    rethrow;
  }
}

/// The root the list is built on: the typed one wins over the catalog.
String _baseUrlOf(TranslationProvider provider, ProviderCredential credential) {
  final override = credential.baseUrl.trim();
  final value = override.isNotEmpty ? override : provider.baseUrl.trim();
  return value.replaceFirst(RegExp(r'/+$'), '');
}

/// `/api/tags` sits on the Ollama server root, not under its `/v1` chat path.
String _withoutVersionSuffix(String baseUrl) {
  const suffix = '/v1';
  return baseUrl.endsWith(suffix)
      ? baseUrl.substring(0, baseUrl.length - suffix.length)
      : baseUrl;
}

Future<List<String>> _fetchOpenAi(
  Dio dio,
  String baseUrl,
  ProviderCredential credential,
  TranslationProvider provider,
  Duration timeout,
) async {
  final response = await dio.get<dynamic>(
    _modelListUrlOf(provider, baseUrl),
    options: Options(
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        if (credential.apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${credential.apiKey.trim()}',
        ...provider.extraHeaders,
      },
    ),
  );
  return _namesFrom(response.data);
}

Future<List<String>> _fetchAnthropic(
  Dio dio,
  String baseUrl,
  ProviderCredential credential,
  TranslationProvider provider,
  Duration timeout,
) async {
  final response = await dio.get<Map<String, dynamic>>(
    '$baseUrl/models',
    queryParameters: const {'limit': 1000},
    options: Options(
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'x-api-key': credential.apiKey.trim(),
        'anthropic-version': '2023-06-01',
        ...provider.extraHeaders,
      },
    ),
  );
  return _namesFrom(response.data);
}

Future<List<String>> _fetchGemini(
  Dio dio,
  String baseUrl,
  ProviderCredential credential,
  TranslationProvider provider,
  Duration timeout,
) async {
  final response = await dio.get<Map<String, dynamic>>(
    '$baseUrl/models',
    queryParameters: const {'pageSize': 1000},
    options: Options(
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'x-goog-api-key': credential.apiKey.trim(),
        ...provider.extraHeaders,
      },
    ),
  );
  final models = response.data?['models'];
  if (models is! List) return const [];
  final names = <String>[];
  for (final model in models) {
    if (model is! Map) continue;
    final methods = model['supportedGenerationMethods'];
    if (methods is List && !methods.contains('generateContent')) continue;
    final name = model['name'];
    if (name is! String || name.trim().isEmpty) continue;
    names.add(
      name.startsWith('models/') ? name.substring('models/'.length) : name,
    );
  }
  return names;
}

/// The absolute list endpoint: a catalog override wins over `baseUrl/models`.
String _modelListUrlOf(TranslationProvider provider, String baseUrl) {
  final explicit = provider.modelListUrl?.trim() ?? '';
  return explicit.isNotEmpty ? explicit : '$baseUrl/models';
}

/// Reads names out of the three list shapes vendors publish: OpenAI's
/// `data[].id`, an Anthropic-style `data[].id`, and a plain list of names or
/// `{id, name}` objects (OpenCode answers one of these).
List<String> _namesFrom(Object? body) {
  final entries = switch (body) {
    final List<dynamic> list => list,
    final Map<dynamic, dynamic> map when map['data'] is List =>
      map['data'] as List<dynamic>,
    final Map<dynamic, dynamic> map when map['models'] is List =>
      map['models'] as List<dynamic>,
    _ => const <dynamic>[],
  };
  final names = <String>[];
  for (final entry in entries) {
    if (entry is String) {
      names.add(entry);
      continue;
    }
    if (entry is Map) {
      final value = entry['id'] ?? entry['name'];
      if (value is String) names.add(value);
    }
  }
  return names;
}

/// Drops blank and repeated names, and keeps the order the vendor served.
List<String> _unmodifiableNames(List<String> names) {
  final seen = <String>{};
  final kept = <String>[];
  for (final name in names) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    kept.add(trimmed);
  }
  return List<String>.unmodifiable(kept);
}
