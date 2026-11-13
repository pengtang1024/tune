import 'package:dio/dio.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';
import 'package:tune/domain/models/translation_engine.dart';

/// The advanced engine: any endpoint that speaks the OpenAI chat dialect.
class OpenAiTranslationEngine implements TranslationEngine {
  final String baseUrl;
  final String apiKey;
  final String model;
  final Dio _dio;

  OpenAiTranslationEngine({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 60),
             ),
           );

  @override
  String get id {
    final host = Uri.tryParse(baseUrl)?.host ?? baseUrl;
    return 'api:$host:$model';
  }

  @override
  Future<TranslationBatch> translate(
    List<String> texts, {
    required String targetLanguage,
  }) async {
    if (texts.isEmpty) return const TranslationBatch(translations: {});
    if (baseUrl.trim().isEmpty || model.trim().isEmpty) {
      throw const TranslationException(
        'the translation endpoint is not configured',
        unavailable: true,
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '${baseUrl.trim().replaceFirst(RegExp(r'/+$'), '')}/chat/completions',
      data: {
        'model': model.trim(),
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content': translationInstruction(targetLanguage),
          },
          {'role': 'user', 'content': translationPayload(texts)},
        ],
      },
      options: Options(
        headers: {
          if (apiKey.trim().isNotEmpty)
            'Authorization': 'Bearer ${apiKey.trim()}',
        },
      ),
    );

    final data = response.data;
    final choices = data?['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const TranslationException('the endpoint answered nothing');
    }
    final message = (choices.first as Map)['message'];
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const TranslationException('the endpoint answered with empty text');
    }
    final translations = parseTranslationPayload(content, texts);
    if (translations.isEmpty) {
      throw const TranslationException('the answer is not usable JSON');
    }
    final usage = data?['usage'];
    return TranslationBatch(
      translations: translations,
      promptTokens: usage is Map ? (usage['prompt_tokens'] as num?)?.toInt() ?? 0 : 0,
      completionTokens: usage is Map
          ? (usage['completion_tokens'] as num?)?.toInt() ?? 0
          : 0,
    );
  }
}
