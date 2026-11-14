import 'package:dio/dio.dart';
import 'package:tune/utils/logger.dart';

/// The models the local Ollama has pulled, so the settings page can offer
/// them instead of only a typed name.
///
/// Ollama publishes them on its own `/api/tags`, not on the
/// OpenAI-compatible `/v1` the chat requests go to. A server that is down or
/// answers another shape returns no model at all: the page keeps its field.
Future<List<String>> fetchOllamaModels({
  Dio? dio,
  String baseUrl = 'http://127.0.0.1:11434',
  Duration timeout = const Duration(seconds: 2),
}) async {
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
  try {
    final response = await client.get<Map<String, dynamic>>(
      '$baseUrl/api/tags',
      options: Options(receiveTimeout: timeout, sendTimeout: timeout),
    );
    final models = response.data?['models'];
    if (models is! List) {
      Log.debug('ollama: /api/tags carried no models list');
      return const [];
    }
    final names = <String>[];
    for (final model in models) {
      if (model is! Map) continue;
      final name = model['name'];
      if (name is String && name.trim().isNotEmpty) names.add(name.trim());
    }
    return List<String>.unmodifiable(names);
  } catch (error) {
    // The endpoint is optional; the reader types a model instead.
    Log.debug('ollama: reading /api/tags failed: $error');
    return const [];
  }
}
