import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/utils/logger.dart';
import 'package:tune/data/services/translation/anthropic_translation_engine.dart';
import 'package:tune/data/services/translation/gemini_translation_engine.dart';
import 'package:tune/data/services/translation/llama_local_translation_engine.dart';
import 'package:tune/data/services/translation/ollama_models.dart';
import 'package:tune/data/services/translation/openai_translation_engine.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/data/services/translation/translation_balance.dart';
import 'package:tune/data/services/translation/translation_provider_catalog.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';
import 'package:tune/data/services/providers/local_components_provider.dart';
import 'package:tune/data/services/providers/app_database_provider.dart';
import 'package:tune/domain/models/translation_cache.dart';
import 'package:tune/features/localization/application/translation_repository.dart';
import 'package:tune/features/localization/data/translation_store.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/features/localization/domain/text_language.dart';
import 'package:tune/domain/models/translation_engine.dart';
import 'package:tune/domain/models/translation_provider.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// One text that a widget asks to see in the language of the interface.
typedef TranslationRequest = ({String text, String targetLanguage});

/// Whether the chosen backend can translate right now.
enum TranslationAvailability {
  available,
  needsProvider,
  needsKey,
  needsModel,
  localNotInstalled,
}

final translationAssetsProvider = FutureProvider<TranslationAssets>((ref) async {
  ref.watch(localComponentsRevisionProvider);
  final assets = await TranslationAssets.forApp();
  final components = await ref.watch(localComponentsProvider.future);
  await assets.useComponents(components);
  return assets;
});

/// Whether the offline engine has both halves it needs: a llama.cpp runtime
/// and the model, from the system or from a downloaded component.
final localTranslationReadyProvider = FutureProvider<bool>((ref) async {
  ref.watch(localComponentsRevisionProvider);
  final components = await ref.watch(localComponentsProvider.future);
  return _localTranslationReady(components);
});

Future<bool> _localTranslationReady(LocalComponents components) async {
  final runtime = await components.executable(
    LocalComponentRegistry.translationRuntime,
  );
  if (runtime == null) return false;
  final model = await components.file(
    LocalComponentRegistry.translationModel,
    LocalComponentRegistry.translationModelFileName,
  );
  return model != null;
}

final translationStoreProvider = FutureProvider<TranslationStore>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return TranslationStore(database);
});

/// Bumped after a batch reports tokens, so the ledger can refresh.
final translationUsageRevisionProvider = StateProvider<int>((ref) => 0);

/// Bumped when the settings page asks for a balance snapshot.
final translationBalanceRequestProvider = StateProvider<int>((ref) => 0);

/// Reads the chosen backend without creating it.
final translationAvailabilityProvider = Provider<TranslationAvailability>((
  ref,
) {
  final config = ref.watch(
    settingsControllerProvider.select((settings) => settings.localization),
  );
  final backendId = config.backendId.trim();
  if (backendId.isEmpty) return TranslationAvailability.needsProvider;

  if (backendId == LocalizationConfig.localBackendId) {
    final ready = ref.watch(localTranslationReadyProvider);
    return ready.valueOrNull == true
        ? TranslationAvailability.available
        : TranslationAvailability.localNotInstalled;
  }

  final provider = providerById(backendId);
  if (provider == null || provider.isLocalModel) {
    return TranslationAvailability.needsProvider;
  }
  final credential = config.credentialFor(backendId);
  if (provider.isCustom && credential.baseUrl.trim().isEmpty) {
    return TranslationAvailability.needsProvider;
  }
  final model = credential.model.trim().isEmpty
      ? provider.defaultModel.trim()
      : credential.model.trim();
  if (model.isEmpty) return TranslationAvailability.needsModel;
  if (!provider.allowsEmptyKey && credential.apiKey.trim().isEmpty) {
    return TranslationAvailability.needsKey;
  }
  return TranslationAvailability.available;
});

final translationRepositoryProvider = FutureProvider<TranslationRepository?>((
  ref,
) async {
  final config = ref.watch(
    settingsControllerProvider.select((settings) => settings.localization),
  );
  if (!config.enabled) return null;
  if (ref.watch(translationAvailabilityProvider) !=
      TranslationAvailability.available) {
    return null;
  }
  final engine = await _engineFor(ref, config);
  if (engine == null) return null;
  final store = await ref.watch(translationStoreProvider.future);
  final repository = TranslationRepository(
    store: store,
    engine: engine,
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
      if (ref.watch(translationAvailabilityProvider) !=
          TranslationAvailability.available) {
        return null;
      }
      if (!needsTranslation(request.text, request.targetLanguage)) return null;
      try {
        final repository = await ref.watch(
          translationRepositoryProvider.future,
        );
        if (repository == null) return null;
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
      if (!config.enabled) return null;
      if (ref.watch(translationAvailabilityProvider) !=
          TranslationAvailability.available) {
        return null;
      }
      final provider = providerById(config.backendId);
      if (provider == null || !provider.supportsBalance) return null;
      return probeTranslationBalance(
        provider: provider,
        credential: config.credentialFor(provider.id),
      );
    });

/// The models the running Ollama has pulled.
///
/// Only the `ollama` backend asks; every other choice, and an Ollama that is
/// not up, answer an empty list, so the page keeps its free-form field.
final ollamaModelsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final config = ref.watch(
    settingsControllerProvider.select((settings) => settings.localization),
  );
  if (config.backendId != 'ollama') return const [];
  final typed = config.credentialFor('ollama').baseUrl.trim();
  final baseUrl = typed.isEmpty
      ? providerById('ollama')?.baseUrl ?? ''
      : typed;
  if (baseUrl.isEmpty) return const [];
  return fetchOllamaModels(baseUrl: _withoutVersionSuffix(baseUrl));
});

/// `/api/tags` sits on the server root, not under the `/v1` chat path.
String _withoutVersionSuffix(String baseUrl) {
  final trimmed = baseUrl.trim();
  const suffix = '/v1';
  if (!trimmed.endsWith(suffix)) return trimmed;
  return trimmed.substring(0, trimmed.length - suffix.length);
}

Future<TranslationEngine?> _engineFor(
  Ref ref,
  LocalizationConfig config,
) async {
  if (config.backendId == LocalizationConfig.localBackendId) {
    final assets = await ref.watch(translationAssetsProvider.future);
    return LlamaLocalTranslationEngine(assets: assets);
  }
  final provider = providerById(config.backendId);
  if (provider == null || provider.isLocalModel) return null;
  final credential = config.credentialFor(provider.id);
  return switch (provider.protocol) {
    TranslationProtocol.openAiChat => OpenAiTranslationEngine(
      provider: provider,
      credential: credential,
    ),
    TranslationProtocol.anthropicMessages => AnthropicTranslationEngine(
      provider: provider,
      credential: credential,
    ),
    TranslationProtocol.geminiGenerateContent => GeminiTranslationEngine(
      provider: provider,
      credential: credential,
    ),
  };
}
