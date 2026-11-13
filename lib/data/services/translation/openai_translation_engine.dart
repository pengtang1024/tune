import 'package:dio/dio.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// The OpenAI chat dialect and the many endpoints that copy it.
class OpenAiTranslationEngine implements TranslationEngine {
  final TranslationProvider provider;
  final ProviderCredential credential;
  final Dio _dio;

  OpenAiTranslationEngine({
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
    if (!provider.allowsEmptyKey && _apiKey.isEmpty) {
      throw const TranslationException(
        'the translation endpoint needs a key',
        unavailable: true,
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl${provider.chatPath}',
      data: {
        'model': _model,
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
          if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
          ...provider.extraHeaders,
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
      promptTokens: usage is Map
          ? (usage['prompt_tokens'] as num?)?.toInt() ?? 0
          : 0,
      completionTokens: usage is Map
          ? (usage['completion_tokens'] as num?)?.toInt() ?? 0
          : 0,
    );
  }
}
