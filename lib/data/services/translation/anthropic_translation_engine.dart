import 'dart:math';

import 'package:dio/dio.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// Anthropic's `/messages` API, which is not OpenAI-compatible.
class AnthropicTranslationEngine implements TranslationEngine {
  static const String apiVersion = '2023-06-01';

  final TranslationProvider provider;
  final ProviderCredential credential;
  final Dio _dio;

  AnthropicTranslationEngine({
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
      '$_baseUrl${provider.chatPath}',
      data: {
        'model': _model,
        'max_tokens': _maxTokens(texts.length),
        'temperature': 0,
        'system': translationInstruction(targetLanguage),
        'messages': [
          {'role': 'user', 'content': translationPayload(texts)},
        ],
      },
      options: Options(
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': apiVersion,
          ...provider.extraHeaders,
        },
      ),
    );

    final data = response.data;
    final content = data?['content'];
    if (content is! List || content.isEmpty) {
      throw const TranslationException('the endpoint answered nothing');
    }
    final buffer = StringBuffer();
    for (final item in content) {
      if (item is Map && item['type'] == 'text' && item['text'] is String) {
        buffer.write(item['text']);
      }
    }
    final answer = buffer.toString();
    if (answer.trim().isEmpty) {
      throw const TranslationException('the endpoint answered with empty text');
    }
    final translations = parseTranslationPayload(answer, texts);
    if (translations.isEmpty) {
      throw const TranslationException('the answer is not usable JSON');
    }
    final usage = data?['usage'];
    return TranslationBatch(
      translations: translations,
      promptTokens: usage is Map
          ? (usage['input_tokens'] as num?)?.toInt() ?? 0
          : 0,
      completionTokens: usage is Map
          ? (usage['output_tokens'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  static int _maxTokens(int count) => min(512, max(96, count * 48));
}
