import 'dart:math';

import 'package:dio/dio.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// Gemini's `generateContent` API, which is not OpenAI-compatible.
class GeminiTranslationEngine implements TranslationEngine {
  final TranslationProvider provider;
  final ProviderCredential credential;
  final Dio _dio;

  GeminiTranslationEngine({
    required this.provider,
    required this.credential,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 60),
             ),
           );

  String get _baseUrl {
    final override = credential.baseUrl.trim();
    final value = override.isNotEmpty ? override : provider.baseUrl.trim();
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  String get _model {
    final typed = credential.model.trim();
    return typed.isNotEmpty ? typed : provider.defaultModel.trim();
  }

  String get _apiKey => credential.apiKey.trim();

  @override
  String get id => 'api:${provider.id}:$_model';

  @override
  Future<TranslationBatch> translate(
    List<String> texts, {
    required String targetLanguage,
  }) async {
    if (texts.isEmpty) return const TranslationBatch(translations: {});
    if (_baseUrl.isEmpty || _model.isEmpty) {
      throw const TranslationException(
        'the translation endpoint is not configured',
        unavailable: true,
      );
    }
    if (_apiKey.isEmpty) {
      throw const TranslationException(
        'the translation endpoint needs a key',
        unavailable: true,
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/models/$_model:generateContent',
      data: {
        'systemInstruction': {
          'parts': [
            {'text': translationInstruction(targetLanguage)},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': translationPayload(texts)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'maxOutputTokens': _maxTokens(texts.length),
        },
      },
      options: Options(
        headers: {
          'x-goog-api-key': _apiKey,
          ...provider.extraHeaders,
        },
      ),
    );

    final data = response.data;
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const TranslationException('the endpoint answered nothing');
    }
    final content = (candidates.first as Map)['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const TranslationException('the endpoint answered with empty text');
    }
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) buffer.write(part['text']);
    }
    final answer = buffer.toString();
    if (answer.trim().isEmpty) {
      throw const TranslationException('the endpoint answered with empty text');
    }
    final translations = parseTranslationPayload(answer, texts);
    if (translations.isEmpty) {
      throw const TranslationException('the answer is not usable JSON');
    }
    final usage = data?['usageMetadata'];
    return TranslationBatch(
      translations: translations,
      promptTokens: usage is Map
          ? (usage['promptTokenCount'] as num?)?.toInt() ?? 0
          : 0,
      completionTokens: usage is Map
          ? (usage['candidatesTokenCount'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  static int _maxTokens(int count) => min(512, max(96, count * 48));
}
