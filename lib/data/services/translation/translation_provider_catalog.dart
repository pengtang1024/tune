import 'package:tune/domain/models/translation_provider.dart';

/// The vendors the settings page offers, in display order.
///
/// Endpoints and model names are starting points, not promises: every vendor
/// changes them, so the page always allows typing another model.
const List<TranslationProvider> translationProviderCatalog = [
  TranslationProvider(
    id: 'openai',
    name: 'OpenAI',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.openai.com/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['gpt-4o-mini', 'gpt-4.1-mini', 'gpt-4o'],
    defaultModel: 'gpt-4o-mini',
  ),
  TranslationProvider(
    id: 'anthropic',
    name: 'Anthropic',
    protocol: TranslationProtocol.anthropicMessages,
    baseUrl: 'https://api.anthropic.com/v1',
    chatPath: '/messages',
    suggestedModels: [
      'claude-3-5-haiku-latest',
      'claude-3-5-sonnet-latest',
    ],
    defaultModel: 'claude-3-5-haiku-latest',
  ),
  TranslationProvider(
    id: 'gemini',
    name: 'Google Gemini',
    protocol: TranslationProtocol.geminiGenerateContent,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    chatPath: '',
    suggestedModels: ['gemini-2.0-flash', 'gemini-2.5-flash'],
    defaultModel: 'gemini-2.0-flash',
  ),
  TranslationProvider(
    id: 'deepseek',
    name: 'DeepSeek',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.deepseek.com/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['deepseek-chat', 'deepseek-reasoner'],
    defaultModel: 'deepseek-chat',
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
    suggestedModels: ['moonshot-v1-8k', 'moonshot-v1-32k', 'kimi-latest'],
    defaultModel: 'moonshot-v1-8k',
    balance: TranslationBalanceApi(
      url: 'https://api.moonshot.cn/users/me/balance',
      parser: TranslationBalanceParser.moonshot,
    ),
  ),
  TranslationProvider(
    id: 'dashscope',
    name: 'Alibaba DashScope',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
    defaultModel: 'qwen-turbo',
  ),
  TranslationProvider(
    id: 'zhipu',
    name: 'Zhipu GLM',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    chatPath: '/chat/completions',
    suggestedModels: ['glm-4-flash', 'glm-4-air', 'glm-4-plus'],
    defaultModel: 'glm-4-flash',
  ),
  TranslationProvider(
    id: 'groq',
    name: 'Groq',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://api.groq.com/openai/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['llama-3.1-8b-instant', 'llama-3.3-70b-versatile'],
    defaultModel: 'llama-3.1-8b-instant',
  ),
  TranslationProvider(
    id: 'openrouter',
    name: 'OpenRouter',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'https://openrouter.ai/api/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['openai/gpt-4o-mini', 'google/gemini-2.0-flash-001'],
    defaultModel: 'openai/gpt-4o-mini',
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
    suggestedModels: ['Qwen/Qwen2.5-7B-Instruct', 'deepseek-ai/DeepSeek-V3'],
    defaultModel: 'Qwen/Qwen2.5-7B-Instruct',
    balance: TranslationBalanceApi(
      url: 'https://api.siliconflow.cn/user/info',
      parser: TranslationBalanceParser.siliconflow,
    ),
  ),
  TranslationProvider(
    id: 'ollama',
    name: 'Ollama (local)',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: 'http://127.0.0.1:11434/v1',
    chatPath: '/chat/completions',
    suggestedModels: ['qwen2.5:3b', 'llama3.2:3b'],
    defaultModel: 'qwen2.5:3b',
    allowsEmptyKey: true,
  ),
  TranslationProvider(
    id: 'custom',
    name: 'Custom',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: '',
    chatPath: '/chat/completions',
    suggestedModels: [],
    defaultModel: '',
    allowsEmptyKey: true,
    isCustom: true,
  ),
  TranslationProvider(
    id: 'local',
    name: 'Bundled model',
    protocol: TranslationProtocol.openAiChat,
    baseUrl: '',
    chatPath: '',
    suggestedModels: [],
    defaultModel: '',
    isLocalModel: true,
  ),
];

TranslationProvider? providerById(String id) {
  for (final provider in translationProviderCatalog) {
    if (provider.id == id) return provider;
  }
  return null;
}
