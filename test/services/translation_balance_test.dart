import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/translation/translation_balance.dart';
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

/// Fails the way a timeout does, without a response.
class _TimeoutAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;

Future<TranslationBalance> _probe(
  HttpClientAdapter adapter,
  String providerId, {
  String apiKey = 'a-key',
}) {
  return probeTranslationBalance(
    provider: providerById(providerId)!,
    credential: ProviderCredential(apiKey: apiKey),
    dio: _dioWith(adapter),
  );
}

void main() {
  final strings = AppStrings.instance;

  test('DeepSeek reads total_balance out of balance_infos', () async {
    final adapter = _JsonAdapter(200, {
      'balance_infos': [
        {'currency': 'CNY', 'total_balance': '12.34'},
      ],
    });

    final balance = await _probe(adapter, 'deepseek');

    expect(balance.supported, isTrue);
    expect(balance.amount, '12.34');
    expect(balance.currency, 'CNY');
    expect(balance.message, isNull);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer a-key');
  });

  test('Moonshot reads available_balance out of data', () async {
    final adapter = _JsonAdapter(200, {
      'data': {'available_balance': 42.5},
    });

    final balance = await _probe(adapter, 'moonshot');

    expect(balance.supported, isTrue);
    expect(balance.amount, '42.5');
    expect(balance.currency, 'CNY');
  });

  test('OpenRouter subtracts the usage from the credits', () async {
    final adapter = _JsonAdapter(200, {
      'data': {'total_credits': 10.0, 'total_usage': 3.25},
    });

    final balance = await _probe(adapter, 'openrouter');

    expect(balance.supported, isTrue);
    expect(balance.amount, '6.75');
    expect(balance.currency, 'USD');
  });

  test('SiliconFlow reads its balance field', () async {
    final adapter = _JsonAdapter(200, {
      'data': {'balance': '8.88'},
    });

    final balance = await _probe(adapter, 'siliconflow');

    expect(balance.supported, isTrue);
    expect(balance.amount, '8.88');
    expect(balance.currency, 'CNY');
  });

  test('SiliconFlow also accepts totalBalance when balance is absent', () async {
    final adapter = _JsonAdapter(200, {
      'data': {'totalBalance': '1.23'},
    });

    final balance = await _probe(adapter, 'siliconflow');

    expect(balance.amount, '1.23');
  });

  test('a refused key is reported as denied', () async {
    for (final status in [401, 403]) {
      final adapter = _JsonAdapter(status);

      final balance = await _probe(adapter, 'deepseek');

      expect(balance.supported, isTrue);
      expect(balance.amount, isNull);
      expect(balance.message, strings.settingsLocalizationBalanceDenied);
    }
  });

  test('another status is reported with its code', () async {
    final adapter = _JsonAdapter(500);

    final balance = await _probe(adapter, 'deepseek');

    expect(balance.supported, isTrue);
    expect(
      balance.message,
      strings.settingsLocalizationBalanceFailedStatus('500'),
    );
  });

  test('an answer without the field says so', () async {
    final adapter = _JsonAdapter(200, {'balance_infos': const []});

    final balance = await _probe(adapter, 'deepseek');

    expect(balance.supported, isTrue);
    expect(balance.amount, isNull);
    expect(balance.message, strings.settingsLocalizationBalanceNoField);
  });

  test('a vendor without a balance API sends no request', () async {
    final adapter = _JsonAdapter(200);

    final balance = await _probe(adapter, 'openai');

    expect(balance.supported, isFalse);
    expect(
      balance.message,
      strings.settingsLocalizationBalanceUnsupported,
    );
    expect(adapter.calls, 0);
  });

  test('a network failure is classified, not thrown', () async {
    final adapter = _TimeoutAdapter();

    final balance = await _probe(adapter, 'deepseek');

    expect(balance.supported, isTrue);
    expect(
      balance.message,
      strings.settingsLocalizationBalanceFailedNetwork('connectionTimeout'),
    );
  });
}
