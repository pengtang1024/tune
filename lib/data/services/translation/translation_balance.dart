import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_provider.dart';

/// What the endpoint could say about the account behind the key.
///
/// There is no universal balance API. The providers below publish one; the
/// others only report tokens per request. A caller must show [supported] as
/// false instead of inventing a number.
class TranslationBalance {
  final bool supported;
  final String? amount;
  final String? currency;

  /// The reason when the query failed, or what the endpoint offers instead.
  final String? message;
  final DateTime checkedAt;

  const TranslationBalance({
    required this.supported,
    required this.checkedAt,
    this.amount,
    this.currency,
    this.message,
  });
}

/// Asks the chosen provider for the balance of its account.
Future<TranslationBalance> probeTranslationBalance({
  required TranslationProvider provider,
  required ProviderCredential credential,
  Dio? dio,
}) async {
  final now = DateTime.now();
  final api = provider.balance;
  if (api == null) {
    return TranslationBalance(
      supported: false,
      checkedAt: now,
      message: AppStrings.instance.settingsLocalizationBalanceUnsupported,
    );
  }

  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
  final key = credential.apiKey.trim();
  final headers = {
    if (key.isNotEmpty) 'Authorization': 'Bearer $key',
    ...provider.extraHeaders,
  };

  try {
    final response = await client.get<Map<String, dynamic>>(
      api.url,
      options: Options(headers: headers),
    );
    return _read(api.parser, response.data, now);
  } on DioException catch (error) {
    return TranslationBalance(
      supported: true,
      checkedAt: now,
      message: _describe(error),
    );
  }
}

TranslationBalance _read(
  TranslationBalanceParser parser,
  Map<String, dynamic>? data,
  DateTime now,
) {
  switch (parser) {
    case TranslationBalanceParser.deepseek:
      {
        final infos = data?['balance_infos'];
        final first = infos is List && infos.isNotEmpty ? infos.first : null;
        if (first is Map) {
          return TranslationBalance(
            supported: true,
            checkedAt: now,
            amount: '${first['total_balance'] ?? ''}',
            currency: '${first['currency'] ?? ''}',
          );
        }
      }
    case TranslationBalanceParser.moonshot:
      {
        final payload = data?['data'];
        if (payload is Map) {
          return TranslationBalance(
            supported: true,
            checkedAt: now,
            amount: '${payload['available_balance'] ?? ''}',
            currency: 'CNY',
          );
        }
      }
    case TranslationBalanceParser.openrouter:
      {
        final payload = data?['data'];
        if (payload is Map) {
          final total = (payload['total_credits'] as num?)?.toDouble() ?? 0;
          final used = (payload['total_usage'] as num?)?.toDouble() ?? 0;
          return TranslationBalance(
            supported: true,
            checkedAt: now,
            amount: (total - used).toStringAsFixed(2),
            currency: 'USD',
          );
        }
      }
    case TranslationBalanceParser.siliconflow:
      {
        final payload = data?['data'];
        if (payload is Map) {
          final value = payload['balance'] ?? payload['totalBalance'];
          return TranslationBalance(
            supported: true,
            checkedAt: now,
            amount: '${value ?? ''}',
            currency: 'CNY',
          );
        }
      }
  }
  return TranslationBalance(
    supported: true,
    checkedAt: now,
    message: AppStrings.instance.settingsLocalizationBalanceNoField,
  );
}

String _describe(DioException error) {
  final strings = AppStrings.instance;
  final status = error.response?.statusCode;
  if (status == 401 || status == 403) {
    return strings.settingsLocalizationBalanceDenied;
  }
  if (status != null) {
    return strings.settingsLocalizationBalanceFailedStatus('$status');
  }
  return strings.settingsLocalizationBalanceFailedNetwork(error.type.name);
}
