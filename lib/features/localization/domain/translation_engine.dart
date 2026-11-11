/// What one batch of translations brought back.
class TranslationBatch {
  final Map<String, String> translations;

  /// The tokens the endpoint reported; `0` when it reported none.
  final int promptTokens;
  final int completionTokens;

  const TranslationBatch({
    required this.translations,
    this.promptTokens = 0,
    this.completionTokens = 0,
  });
}

/// A translation did not happen, and why.
///
/// [unavailable] is set when the engine cannot run at all (the model is not
/// downloaded, the endpoint is not configured). The caller stops asking for
/// the rest of the session instead of starting one process per row.
class TranslationException implements Exception {
  final String message;
  final bool unavailable;

  const TranslationException(this.message, {this.unavailable = false});

  @override
  String toString() => 'TranslationException: $message';
}

/// One way of turning text into the language of the interface.
abstract class TranslationEngine {
  /// The identity that participates in the cache key. A change of model or
  /// endpoint changes it, so old rows are not served under the new engine.
  String get id;

  /// Translates [texts] as one batch, keyed by the exact source text.
  Future<TranslationBatch> translate(
    List<String> texts, {
    required String targetLanguage,
  });
}
