import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/anthropic_translation_engine.dart';
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

TranslationProvider get _anthropic => providerById('anthropic')!;

Dio _dioWith(HttpClientAdapter adapter) =>
    Dio()..httpClientAdapter = adapter;

void main() {
  test('a batch travels to /messages with the Anthropic headers', () async {
    final adapter = _JsonAdapter(200, {
      'content': [
        {'type': 'thinking', 'thinking': 'ignored'},
        {
          'type': 'text',
          'text': jsonEncode([
            {'id': 0, 'text': '蓝调绿'},
          ]),
        },
      ],
      'usage': {'input_tokens': 11, 'output_tokens': 7},
    });
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(apiKey: 'anthropic-key'),
      dio: _dioWith(adapter),
    );

    final result = await engine.translate(
      ['Blue in Green'],
      targetLanguage: 'zh-CN',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.uri.toString(), '${_anthropic.baseUrl}/messages');
    expect(request.headers['x-api-key'], 'anthropic-key');
    expect(
      request.headers['anthropic-version'],
      AnthropicTranslationEngine.apiVersion,
    );

    final body = request.data as Map<String, dynamic>;
    expect(body['model'], _anthropic.defaultModel);
    expect(body['max_tokens'], 96);
    expect(body['system'], contains('zh-CN'));
    final messages = body['messages'] as List;
    expect(messages, hasLength(1));
    expect(messages.single['role'], 'user');
    expect(messages.single['content'], contains('Blue in Green'));

    expect(result.translations, {'Blue in Green': '蓝调绿'});
    expect(result.promptTokens, 11);
    expect(result.completionTokens, 7);
  });

  test('non-text content parts are not part of the answer', () async {
    final adapter = _JsonAdapter(200, {
      'content': [
        {'type': 'thinking', 'thinking': 'not the answer'},
        {
          'type': 'text',
          'text': jsonEncode([
            {'id': 0, 'text': '泛蓝'},
          ]),
        },
      ],
    });
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(apiKey: 'anthropic-key'),
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
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(),
      dio: _dioWith(adapter),
    );

    await expectLater(
      engine.translate(['Blue in Green'], targetLanguage: 'zh-CN'),
      _unavailable(),
    );
    expect(adapter.calls, 0);
  });

  test('an empty batch is no request at all', () async {
    final adapter = _JsonAdapter(200, const {});
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(apiKey: 'anthropic-key'),
      dio: _dioWith(adapter),
    );

    final result = await engine.translate(const [], targetLanguage: 'zh-CN');

    expect(result.translations, isEmpty);
    expect(adapter.calls, 0);
  });

  test('a refused key surfaces the endpoint error', () async {
    final adapter = _JsonAdapter(401, {
      'type': 'error',
      'error': {'type': 'authentication_error'},
    });
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(apiKey: 'bad-key'),
      dio: _dioWith(adapter),
    );

    await expectLater(
      engine.translate(['Blue in Green'], targetLanguage: 'zh-CN'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('an answer of prose instead of JSON is unusable', () async {
    final adapter = _JsonAdapter(200, {
      'content': [
        {'type': 'text', 'text': 'I cannot translate that.'},
      ],
    });
    final engine = AnthropicTranslationEngine(
      provider: _anthropic,
      credential: const ProviderCredential(apiKey: 'anthropic-key'),
      dio: _dioWith(adapter),
    );

    await expectLater(
      engine.translate(
        ['Blue in Green', 'Kind of Blue'],
        targetLanguage: 'zh-CN',
      ),
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
