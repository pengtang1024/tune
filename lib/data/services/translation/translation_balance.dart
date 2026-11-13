import 'package:dio/dio.dart';
import 'package:tune/core/l10n/app_strings.dart';

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

/// Asks the known providers for the balance of their account.
Future<TranslationBalance> probeTranslationBalance({
  required String baseUrl,
  required String apiKey,
  Dio? dio,
}) async {
  final now = DateTime.now();
  final uri = Uri.tryParse(baseUrl.trim());
  final host = uri?.host ?? '';
  final client =
      dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
  final headers = {
    if (apiKey.trim().isNotEmpty) 'Authorization': 'Bearer ${apiKey.trim()}',
  };

  try {
    if (host.contains('deepseek')) {
      final response = await client.get<Map<String, dynamic>>(
        'https://api.deepseek.com/user/balance',
        options: Options(headers: headers),
      );
      final infos = response.data?['balance_infos'];
      final first = infos is List && infos.isNotEmpty ? infos.first : null;
      if (first is Map) {
        return TranslationBalance(
          supported: true,
          checkedAt: now,
          amount: '${first['total_balance'] ?? ''}',
          currency: '${first['currency'] ?? ''}',
        );
      }
      return TranslationBalance(
        supported: true,
        checkedAt: now,
        message: AppStrings.instance.settingsLocalizationBalanceNoField,
      );
    }

    if (host.contains('moonshot')) {
      final response = await client.get<Map<String, dynamic>>(
        '${_root(baseUrl)}/users/me/balance',
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is Map) {
        return TranslationBalance(
          supported: true,
          checkedAt: now,
          amount: '${data['available_balance'] ?? ''}',
          currency: 'CNY',
        );
      }
      return TranslationBalance(
        supported: true,
        checkedAt: now,
        message: AppStrings.instance.settingsLocalizationBalanceNoField,
      );
    }

    if (host.contains('openrouter')) {
      final response = await client.get<Map<String, dynamic>>(
        'https://openrouter.ai/api/v1/credits',
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is Map) {
        final total = (data['total_credits'] as num?)?.toDouble() ?? 0;
        final used = (data['total_usage'] as num?)?.toDouble() ?? 0;
        return TranslationBalance(
          supported: true,
          checkedAt: now,
          amount: (total - used).toStringAsFixed(2),
          currency: 'USD',
        );
      }
      return TranslationBalance(
        supported: true,
        checkedAt: now,
        message: AppStrings.instance.settingsLocalizationBalanceNoField,
      );
    }

    if (host.contains('siliconflow')) {
      final response = await client.get<Map<String, dynamic>>(
        '${_root(baseUrl)}/user/info',
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is Map) {
        final value = data['balance'] ?? data['totalBalance'];
        return TranslationBalance(
          supported: true,
          checkedAt: now,
          amount: '${value ?? ''}',
          currency: 'CNY',
        );
      }
      return TranslationBalance(
        supported: true,
        checkedAt: now,
        message: AppStrings.instance.settingsLocalizationBalanceNoField,
      );
    }
  } on DioException catch (error) {
    return TranslationBalance(
      supported: true,
      checkedAt: now,
      message: _describe(error),
    );
  }

  return TranslationBalance(
    supported: false,
    checkedAt: now,
    message: AppStrings.instance.settingsLocalizationBalanceUnsupported,
  );
}

String _root(String baseUrl) =>
    baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

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
