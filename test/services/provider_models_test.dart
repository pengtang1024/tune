import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/provider_models.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/domain/models/localization_config.dart';

/// Answers every request with one canned JSON body.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, [this.body = const {}]);

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

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

Future<List<String>> _fetch(
  HttpClientAdapter adapter,
  String providerId, {
  String apiKey = 'a-key',
  String baseUrl = '',
}) {
  return fetchProviderModels(
    provider: providerById(providerId)!,
    credential: ProviderCredential(apiKey: apiKey, baseUrl: baseUrl),
    dio: _dioWith(adapter),
  );
}

void main() {
  test(
    'an OpenAI-compatible vendor answers data[].id behind a bearer token',
    () async {
      final adapter = _JsonAdapter(200, {
        'data': [
          {'id': 'gpt-first'},
          {'id': 'gpt-second'},
        ],
      });

      final models = await _fetch(adapter, 'openai');

      expect(models, ['gpt-first', 'gpt-second']);
      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://api.openai.com/v1/models');
      expect(request.headers['Authorization'], 'Bearer a-key');
    },
  );

  test('Anthropic answers its own list behind x-api-key', () async {
    final adapter = _JsonAdapter(200, {
      'data': [
        {'id': 'claude-first'},
      ],
    });

    final models = await _fetch(adapter, 'anthropic');

    expect(models, ['claude-first']);
    final request = adapter.lastRequest!;
    expect(request.uri.path, '/v1/models');
    expect(request.uri.queryParameters['limit'], '1000');
    expect(request.headers['x-api-key'], 'a-key');
    expect(request.headers['anthropic-version'], '2023-06-01');
  });

  test(
    'Gemini keeps the models that generate content and drops the prefix',
    () async {
      final adapter = _JsonAdapter(200, {
        'models': [
          {
            'name': 'models/gemini-flash',
            'supportedGenerationMethods': ['generateContent'],
          },
          {
            'name': 'models/text-embedding',
            'supportedGenerationMethods': ['embedContent'],
          },
          {'name': 'models/gemini-pro'},
        ],
      });

      final models = await _fetch(adapter, 'gemini');

      expect(models, ['gemini-flash', 'gemini-pro']);
      final request = adapter.lastRequest!;
      expect(
        request.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models'
        '?pageSize=1000',
      );
      expect(request.headers['x-goog-api-key'], 'a-key');
    },
  );

  test('Ollama reads /api/tags on the server root', () async {
    final adapter = _JsonAdapter(200, {
      'models': [
        {'name': 'qwen3:4b'},
        {'name': 'llama3.2:3b'},
      ],
    });

    final models = await _fetch(
      adapter,
      'ollama',
      apiKey: '',
      baseUrl: 'http://127.0.0.1:12345/v1',
    );

    expect(models, ['qwen3:4b', 'llama3.2:3b']);
    expect(
      adapter.lastRequest!.uri.toString(),
      'http://127.0.0.1:12345/api/tags',
    );
  });

  test('a typed endpoint wins over the catalog', () async {
    final adapter = _JsonAdapter(200, {
      'data': [
        {'id': 'local-one'},
      ],
    });

    final models = await _fetch(
      adapter,
      'custom',
      baseUrl: 'https://example.test/v1/',
    );

    expect(models, ['local-one']);
    expect(
      adapter.lastRequest!.uri.toString(),
      'https://example.test/v1/models',
    );
  });

  test('blank and repeated names are dropped', () async {
    final adapter = _JsonAdapter(200, {
      'data': [
        {'id': 'one'},
        {'id': 'one'},
        {'id': ' '},
        {'id': 'two'},
        {'id': 3},
      ],
    });

    final models = await _fetch(adapter, 'deepseek');

    expect(models, ['one', 'two']);
  });

  test('a refused key throws so the page can say so', () async {
    final adapter = _JsonAdapter(401, {'error': 'bad key'});

    await expectLater(_fetch(adapter, 'openai'), throwsA(isA<DioException>()));
  });

  test('the bundled local model has no list to read', () async {
    final adapter = _JsonAdapter(200, {
      'data': [
        {'id': 'never-read'},
      ],
    });

    final models = await _fetch(adapter, 'local');

    expect(models, isEmpty);
    expect(adapter.calls, 0);
  });

  test('a custom endpoint without an address asks nothing', () async {
    final adapter = _JsonAdapter(200, {});

    final models = await _fetch(adapter, 'custom');

    expect(models, isEmpty);
    expect(adapter.calls, 0);
  });
}
