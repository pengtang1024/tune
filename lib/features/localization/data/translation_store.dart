import 'package:tune/data/services/database/app_database.dart';
import 'package:tune/domain/models/translation_cache.dart';

/// The cache and ledger the repository reads, kept on the one database.
class TranslationStore {
  TranslationStore(this._database);

  final AppDatabase _database;

  Map<String, String> readHashes({
    required String targetLanguage,
    required String engine,
  }) => _database.translations.readHashes(
    targetLanguage: targetLanguage,
    engine: engine,
  );

  void writeBatch({
    required String targetLanguage,
    required String engine,
    required List<TranslationCacheEntry> entries,
    required int createdAt,
  }) => _database.translations.writeBatch(
    targetLanguage: targetLanguage,
    engine: engine,
    entries: entries,
    createdAt: createdAt,
  );

  int count() => _database.translations.count();

  void clear() => _database.translations.clear();

  void addUsage({
    required String engine,
    required int promptTokens,
    required int completionTokens,
    required int createdAt,
  }) => _database.translations.addUsage(
    engine: engine,
    promptTokens: promptTokens,
    completionTokens: completionTokens,
    createdAt: createdAt,
  );

  TranslationTokenUsage usageSince(int since) =>
      _database.translations.usageSince(since);
}
