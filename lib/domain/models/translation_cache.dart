/// One row of the translation cache, ready to be written.
class TranslationCacheEntry {
  /// The hash of the normalized source text; the same album or station name
  /// shares one row across every track that carries it.
  final String hash;
  final String source;
  final String value;

  const TranslationCacheEntry({
    required this.hash,
    required this.source,
    required this.value,
  });
}

/// The tokens the translation engine reported, summed.
class TranslationTokenUsage {
  final int promptTokens;
  final int completionTokens;

  const TranslationTokenUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
  });

  int get total => promptTokens + completionTokens;
}
