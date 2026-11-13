import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/data/services/translation/llama_local_translation_engine.dart';
import 'package:tune/data/services/translation/openai_translation_engine.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/data/services/translation/translation_balance.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/domain/models/translation_cache.dart';
import 'package:tune/features/localization/application/translation_repository.dart';
import 'package:tune/features/localization/data/translation_store.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/features/localization/domain/text_language.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// One text that a widget asks to see in the language of the interface.
typedef TranslationRequest = ({String text, String targetLanguage});

final translationAssetsProvider = FutureProvider<TranslationAssets>((ref) {
  return TranslationAssets.forApp();
});

final translationStoreProvider = FutureProvider<TranslationStore>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return TranslationStore(database);
});

/// Bumped after a batch reports tokens, so the ledger can refresh.
final translationUsageRevisionProvider = StateProvider<int>((ref) => 0);

/// Bumped when the settings page asks for a balance snapshot.
final translationBalanceRequestProvider = StateProvider<int>((ref) => 0);

final translationRepositoryProvider = FutureProvider<TranslationRepository>((
  ref,
) async {
  final config = ref.watch(
    settingsControllerProvider.select((settings) => settings.localization),
  );
  final store = await ref.watch(translationStoreProvider.future);
  final assets = await ref.watch(translationAssetsProvider.future);
  final repository = TranslationRepository(
    store: store,
    engine: _engineFor(config, assets),
    onUsage: () => ref.read(translationUsageRevisionProvider.notifier).state++,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// The translation of one text, or `null` when it needs none.
///
/// Widgets watch this per line. The provider is auto-disposed with the row,
/// so a long list does not keep a provider for every title it ever showed.
final translatedTextProvider = FutureProvider.autoDispose
    .family<String?, TranslationRequest>((ref, request) async {
      final config = ref.watch(
        settingsControllerProvider.select((settings) => settings.localization),
      );
      if (!config.enabled) return null;
      if (!needsTranslation(request.text, request.targetLanguage)) return null;
      try {
        final repository = await ref.watch(
          translationRepositoryProvider.future,
        );
        return await repository.translate(request.text, request.targetLanguage);
      } catch (error) {
        // The original text stays on screen; do not log the text itself.
        Log.debug('translation unavailable: $error');
        return null;
      }
    });

final translationTokenUsageProvider =
    FutureProvider.autoDispose<TranslationTokenUsage>((ref) async {
      ref.watch(translationUsageRevisionProvider);
      final store = await ref.watch(translationStoreProvider.future);
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      return store.usageSince(start);
    });

final translationCacheCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final store = await ref.watch(translationStoreProvider.future);
  return store.count();
});

final translationBalanceProvider =
    FutureProvider.autoDispose<TranslationBalance?>((ref) async {
      ref.watch(translationBalanceRequestProvider);
      final config = ref.watch(
        settingsControllerProvider.select((settings) => settings.localization),
      );
      if (config.engine != TranslationEngineKind.openAiCompatible ||
          !config.apiConfigured) {
        return null;
      }
      return probeTranslationBalance(
        baseUrl: config.apiBaseUrl,
        apiKey: config.apiKey,
      );
    });

TranslationEngine _engineFor(
  LocalizationConfig config,
  TranslationAssets assets,
) {
  if (config.engine == TranslationEngineKind.openAiCompatible) {
    return OpenAiTranslationEngine(
      baseUrl: config.apiBaseUrl,
      apiKey: config.apiKey,
      model: config.apiModel,
    );
  }
  return LlamaLocalTranslationEngine(assets: assets);
}
