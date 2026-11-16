import 'package:tune/domain/models/translation_provider.dart';

/// The vendors the settings page offers, in display order.
///
/// The table carries what a vendor *is* — its dialect, its endpoint and how
/// its balance is read — and no model name. Vendors rename and retire models
/// without notice, so the page asks the vendor for the current list
/// ([fetchProviderModels]) and the reader may still type a name by hand.
const List<TranslationProvider> translationProviderCatalog = [
  TranslationProvider(
    id: 'openai',
    name: 'OpenAI',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.openai.com/v1',
    chatPath: '/chat/completions',
  ),
  TranslationProvider(
    id: 'anthropic',
    name: 'Anthropic',
    protocol: TranslationProtocol.anthropicMessages,
    baseUrl: 'https://api.anthropic.com/v1',
    chatPath: '/messages',
  ),
  TranslationProvider(
    id: 'gemini',
    name: 'Google Gemini',
    protocol: TranslationProtocol.geminiGenerateContent,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    chatPath: '',
  ),
  TranslationProvider(
    id: 'deepseek',
    name: 'DeepSeek',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.deepseek.com',
    chatPath: '/chat/completions',
    balance: TranslationBalanceApi(
      url: 'https://api.deepseek.com/user/balance',
      parser: TranslationBalanceParser.deepseek,
    ),
  ),
  TranslationProvider(
    id: 'moonshot',
    name: 'Moonshot / Kimi',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.moonshot.cn/v1',
    chatPath: '/chat/completions',
    balance: TranslationBalanceApi(
      url: 'https://api.moonshot.cn/v1/users/me/balance',
      parser: TranslationBalanceParser.moonshot,
    ),
  ),
  TranslationProvider(
    id: 'dashscope',
    name: 'Alibaba DashScope',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    chatPath: '/chat/completions',
  ),
  TranslationProvider(
    id: 'zhipu',
    name: 'Zhipu GLM',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    chatPath: '/chat/completions',
    // Zhipu's API reference carries no model-list endpoint.
    listsModels: false,
  ),
  TranslationProvider(
    id: 'groq',
    name: 'Groq',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.groq.com/openai/v1',
    chatPath: '/chat/completions',
  ),
  TranslationProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://openrouter.ai/api/v1',
    chatPath: '/chat/completions',
    balance: TranslationBalanceApi(
      url: 'https://openrouter.ai/api/v1/credits',
      parser: TranslationBalanceParser.openrouter,
    ),
  ),
  TranslationProvider(
    id: 'siliconflow',
    name: 'SiliconFlow',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.siliconflow.cn/v1',
    chatPath: '/chat/completions',
    balance: TranslationBalanceApi(
      url: 'https://api.siliconflow.cn/v1/user/info',
      parser: TranslationBalanceParser.siliconflow,
    ),
  ),
  TranslationProvider(
    id: 'ollama',
    name: 'Ollama (local)',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'http://127.0.0.1:11434/v1',
    chatPath: '/chat/completions',
    allowsEmptyKey: true,
  ),
  TranslationProvider(
    id: 'custom',
    name: 'Custom',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: '',
    chatPath: '/chat/completions',
    allowsEmptyKey: true,
    isCustom: true,
  ),
  TranslationProvider(
    id: 'local',
    name: 'Bundled model',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: '',
    chatPath: '',
    isLocalModel: true,
  ),
];

TranslationProvider? providerById(String id) {
  for (final provider in translationProviderCatalog) {
    if (provider.id == id) return provider;
  }
  return null;
}
