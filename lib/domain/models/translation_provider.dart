/// How an endpoint expects a translation request.
enum TranslationProtocol {
  /// The OpenAI chat-completions dialect and its many copies.
  openAiChat,

  /// Anthropic's `/messages` API.
  anthropicMessages,

  /// Gemini's `generateContent` API.
  geminiGenerateContent,
}

/// Which shape a balance endpoint answers in.
enum TranslationBalanceParser { deepseek, moonshot, openrouter, siliconflow }

/// Where one provider keeps its balance, and how to read the answer.
class TranslationBalanceApi {
  final String url;
  final TranslationBalanceParser parser;

  const TranslationBalanceApi({required this.url, required this.parser});
}

/// One vendor the settings page can offer.
///
/// The catalog is a read-only constant table, not state: the reader's choice
/// lives in [LocalizationConfig], and the key/model live with that choice.
class TranslationProvider {
  final String id;
  final String name;
  final TranslationProtocol protocol;

  /// The root every request is built on. Empty for the custom entry.
  final String baseUrl;

  /// Appended to [baseUrl] for one translation request. Empty for Gemini,
  /// whose path carries the model name.
  final String chatPath;

  /// The models offered in the picker. The reader may still type another.
  final List<String> suggestedModels;

  /// The model selected when the vendor is chosen for the first time.
  final String defaultModel;

  /// Whether a request may go out without a key (Ollama, a local proxy).
  final bool allowsEmptyKey;

  /// Whether this entry is the bundled (but optional) local model.
  final bool isLocalModel;

  /// Whether this entry is the free-form OpenAI-compatible endpoint.
  final bool isCustom;

  /// Headers some vendors expect besides the key.
  final Map<String, String> extraHeaders;

  /// The balance endpoint, when the vendor publishes one.
  final TranslationBalanceApi? balance;

  const TranslationProvider({
    required this.id,
    required this.name,
    required this.protocol,
    required this.baseUrl,
    required this.chatPath,
    required this.suggestedModels,
    required this.defaultModel,
    this.allowsEmptyKey = false,
    this.isLocalModel = false,
    this.isCustom = false,
    this.extraHeaders = const {},
    this.balance,
  });

  bool get supportsBalance => balance != null;
}
