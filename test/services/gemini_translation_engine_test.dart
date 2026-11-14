import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/gemini_translation_engine.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// Answers every request with one canned JSON body.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
  int calls = 0;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Matcher _unavailable() => throwsA(
  isA<TranslationException>().having(
    (error) => error.unavailable,
    'unavailable',
    isTrue,
  ),
);

TranslationProvider get _gemini => providerById('gemini')!;

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

void main() {
  test('a batch travels to generateContent with the key header', () async {
    final adapter = _JsonAdapter(200, {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '[{"id":0,'},
              {'text': '"text":"蓝调绿"}]'},
            ],
          },
        },
      ],
      'usageMetadata': {'promptTokenCount': 20, 'candidatesTokenCount': 9},
    });
    final engine = GeminiTranslationEngine(
      provider: _gemini,
      credential: const ProviderCredential(apiKey: 'gem-key'),
      dio: _dioWith(adapter),
    );

    final result = await engine.translate(
      ['Blue in Green'],
      targetLanguage: 'zh-CN',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(
      request.uri.toString(),
      '${_gemini.baseUrl}/models/${_gemini.defaultModel}:generateContent',
    );
    expect(request.headers['x-goog-api-key'], 'gem-key');

    final body = request.data as Map<String, dynamic>;
    final system = body['systemInstruction'] as Map;
    expect((system['parts'] as List).single['text'], contains('zh-CN'));
    final contents = body['contents'] as List;
    expect(contents, hasLength(1));
    expect(contents.single['role'], 'user');
    final part = (contents.single['parts'] as List).single;
    expect(part['text'], contains('Blue in Green'));
    final config = body['generationConfig'] as Map;
    expect(config['temperature'], 0);
    expect(config['maxOutputTokens'], 96);

    expect(result.translations, {'Blue in Green': '蓝调绿'});
    expect(result.promptTokens, 20);
    expect(result.completionTokens, 9);
  });

  test('the parts of one answer are joined before they are read', () async {
    final adapter = _JsonAdapter(200, {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '[{"id":0,"text":"泛'},
              {'text': '蓝"}]'},
            ],
          },
        },
      ],
    });
    final engine = GeminiTranslationEngine(
      provider: _gemini,
      credential: const ProviderCredential(apiKey: 'gem-key'),
      dio: _dioWith(adapter),
    );

    final result = await engine.translate(
      ['Kind of Blue'],
      targetLanguage: 'zh-CN',
    );

    expect(result.translations, {'Kind of Blue': '泛蓝'});
    expect(result.promptTokens, 0);
    expect(result.completionTokens, 0);
  });

  test('a missing key stops before a request goes out', () async {
    final adapter = _JsonAdapter(200, const {});
    final engine = GeminiTranslationEngine(
      provider: _gemini,
      credential: const ProviderCredential(),
      dio: _dioWith(adapter),
    );

    await expectLater(
      engine.translate(['Blue in Green'], targetLanguage: 'zh-CN'),
      _unavailable(),
    );
    expect(adapter.calls, 0);
  });

  test('an answer without candidates is unusable', () async {
    final adapter = _JsonAdapter(200, {'candidates': const []});
    final engine = GeminiTranslationEngine(
      provider: _gemini,
      credential: const ProviderCredential(apiKey: 'gem-key'),
      dio: _dioWith(adapter),
    );

    await expectLater(
      engine.translate(['Blue in Green'], targetLanguage: 'zh-CN'),
      throwsA(
        isA<TranslationException>().having(
          (error) => error.unavailable,
          'unavailable',
          isFalse,
        ),
      ),
    );
  });
}
