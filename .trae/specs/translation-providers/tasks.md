# 翻译厂商改造任务清单

> 对应 `spec.md`。评审通过后按顺序执行；每个阶段结束跑一次门禁。
> 不触碰迷你模式 / shell 并行线的任何文件。

## P1 配置与厂商目录

- [x] 新增 `lib/domain/models/translation_provider.dart`
  - `enum TranslationProtocol { openAiChat, anthropicMessages, geminiGenerateContent }`
  - `class TranslationProvider`：`id`、`name`、`protocol`、`baseUrl`、`chatPath`、`suggestedModels`、`defaultModel`、`allowsEmptyKey`、`extraHeaders`、`balance`
  - `class TranslationBalanceApi`：`path`、`parser`（`deepseek` / `moonshot` / `openrouter` / `siliconflow`）
- [x] 新增 `lib/data/services/translation/translation_provider_catalog.dart`
  - 12 条常量：`openai`、`anthropic`、`gemini`、`deepseek`、`moonshot`、`dashscope`、`zhipu`、`groq`、`openrouter`、`siliconflow`、`ollama`、`custom`
  - 提供 `TranslationProvider? providerById(String id)`
- [x] 改 `lib/domain/models/localization_config.dart`
  - 用 `backendId` + `Map<String, ProviderCredential>` 替换 `TranslationEngineKind` / 单一 `api*` 字段
  - `ProviderCredential { apiKey, model, baseUrlOverride }`
  - `effectiveConfigured` 与 `copyWith` 更新
  - `fromJson` 兼容旧 `engine/apiBaseUrl/apiKey/apiModel`
- [x] 改 `lib/features/settings/application/settings_controller.dart`
  - `_readLocalization` 继续读同一键，迁移逻辑下沉到 `LocalizationConfig.fromJson`
  - `setLocalization` 保持单一写入点
- [x] 新增 `test/domain/localization_config_test.dart`
  - 旧 `local` / `openAiCompatible` 迁移
  - 多厂商 credentials 往返
  - `effectiveConfigured` 的空 Key 分支
- [x] 新增 `test/services/translation_provider_catalog_test.dart`
  - id 唯一、默认模型非空、OpenAI 兼容族路径一致
- [x] 改 `lib/data/services/translation/openai_translation_engine.dart`
  - 构造参数改为 `TranslationProvider` + `ProviderCredential`
  - 支持 `chatPath`、额外头、空 Key（Ollama / custom）
  - `usage` 缺失时记 0
- [x] 门禁：`flutter analyze`、`flutter test test/domain/localization_config_test.dart test/services/translation_provider_catalog_test.dart`

## P2 原生协议与余额

- [x] 新增 `lib/data/services/translation/anthropic_translation_engine.dart`
  - `POST {base}/messages`、`x-api-key`、`anthropic-version`、`max_tokens`
  - `system` 与 `messages` 分离
  - 解析 `content[]` 的 `text`，用量 `input_tokens` / `output_tokens`
- [x] 新增 `lib/data/services/translation/gemini_translation_engine.dart`
  - `POST {base}/models/{model}:generateContent`、`x-goog-api-key`
  - `systemInstruction` + `contents`
  - 解析 `candidates[0].content.parts[*].text`，用量 `usageMetadata`
- [x] 改 `lib/data/services/translation/translation_balance.dart`
  - 从硬编码 host 判断改为读 `TranslationProvider.balance`
  - 保留四家现有解析器与错误分类
  - 无 `balance` 的厂商返回 `supported: false`
- [x] 新增 `test/services/anthropic_translation_engine_test.dart`
- [x] 新增 `test/services/gemini_translation_engine_test.dart`
- [x] 改 `test/services/translation_balance_test.dart`（若不存在则新建）
  - 四家成功 / 401 / 无字段 / 不支持
- [x] 门禁：`flutter analyze`、`flutter test test/services`

## P3 未配置降级

- [x] 改 `lib/features/localization/application/localization_providers.dart`
  - 新增 `translationAvailabilityProvider`：`available` / `needsProvider` / `needsKey` / `localNotInstalled`
  - `translationRepositoryProvider` 改为 `FutureProvider<TranslationRepository?>`
  - `translatedTextProvider` 在不可用时直接返回 `null`，不创建仓库
  - `_engineFor` 返回 `TranslationEngine?`，按 `protocol` 分派
- [x] 改 `lib/features/settings/presentation/settings_localization_card.dart`
  - 不可用态文案与入口（去配置 / 去下载）
  - 隐私清单：发送字段 / 不发送字段
  - 首次启用或切换厂商的确认提示
- [x] 新增或改 `test/features/localization/translation_availability_test.dart`
  - 未配置时不发起请求
  - 缺 Key 时不发起请求
  - 本地未安装时不创建本地引擎
- [x] 改 `lib/l10n/app_en.arb`、`app_zh.arb`、`app_zh_CN.arb`、`app_zh_TW.arb`
  - 新增厂商相关、隐私清单、降级文案；删除“随应用提供”旧文案
- [x] 跑 `flutter gen-l10n` 并提交产物
- [x] 门禁：`flutter analyze`、`flutter test`

## P4 设置页多厂商交互

- [x] 拆分 `settings_localization_card.dart`（现 343 行）
  - `settings_localization_provider_block.dart`：厂商选择、Key、模型、自定义端点
  - `settings_localization_local_block.dart`：本地模型下载 / 删除
  - `settings_localization_ledger.dart`：今日 tokens、缓存数、清空
- [x] 厂商选择用下拉或列表，显示名称与协议标识
- [x] 模型选择用可编辑下拉：精选项 + 手填；Ollama 尝试读 `/api/tags`，失败退回手填
- [x] Key 输入默认隐藏，提供显示切换；保存时 trim
- [x] 余额按钮仅在厂商有 `balance` 时可用
- [x] 新增 `test/features/settings/settings_localization_card_test.dart`
  - 切换厂商保留各自 Key / 模型
  - 无余额接口的厂商按钮禁用
  - 未配置态文案
- [x] 门禁：`flutter analyze`、`flutter test`

## P5 本地模型可选下载

- [x] 新增 `translation/manifest.json`
  - 组件版本、包 URL、字节数、sha256、安装后目录、许可证文件
- [x] 新增 `lib/data/services/translation/local_model_installer.dart`
  - `install({onProgress})`：下载 → 校验 → 解包 → 原子落位 → 写 `installed.json`
  - `remove()`、`sizeOnDisk()`
  - 临时目录 `<support>/translation/.download/`，失败清理
- [x] 改 `lib/data/services/translation/translation_assets.dart`
  - 解析顺序：env → `<support>/translation` → `<exe>/translation` → 仓库 → 旧支持目录
  - `inspect` 读 `installed.json`，sha256 只在安装时验
  - 标记只读旧副本（不提供删除）
- [x] 改 `lib/features/localization/application/local_model_controller.dart`
  - 状态机 `checking / notInstalled / downloading / verifying / ready / failed`
  - `download()`、`cancel()`、`remove()`、进度字段
- [x] 改 `lib/features/settings/presentation/settings_localization_local_block.dart`
  - 体积、进度、取消、删除、失败重试、许可证提示
- [x] 改 `lib/data/services/translation/llama_local_translation_engine.dart`
  - 每批只做 size 检查；未安装由可用性 provider 拦截
- [x] 新增 `test/services/local_model_installer_test.dart`
  - 假下载器 + 临时目录：安装、校验失败、删除、只读旧副本
- [x] 门禁：`flutter analyze`、`flutter test`

## P6 打包与分发

- [x] 改 `tool/package_linux.sh`
  - 默认不再调用 `prepare_translation.sh`、不再追加 `translation/`
  - 新增 `--offline`：仅维护者本地打出含组件的包，不作为更新附件
- [x] 改 `tool/prepare_translation.sh`
  - 改为离线包专用；或重命名为 `tool/fetch_translation_assets.sh`
- [x] 删除仓库内的 `translation/models/*.gguf` 与 `translation/bin/*.tar.gz`、解包运行时（需用户确认后执行）
- [x] 改 `.gitattributes`
  - 移除两条 LFS 规则
- [x] 改 `.gitignore`
  - 移除已删除目录的忽略项，保留下载缓存忽略
- [x] 改 `lib/data/services/update/`（若归档名匹配逻辑会误选组件包）
  - 确认组件包命名为 `tune-translation-*`，不会被当成平台更新包
- [x] 改 `README.md`、`docs/licensing.md`、`docs/updates.md`、`THIRD_PARTY_NOTICES.md`
  - 默认包体积、组件包发布、许可证随组件包分发、升级后模型需重新下载
- [x] 校验：`bash -n tool/package_linux.sh`、`./tool/package_linux.sh --dry-run`（若实现）
- [x] 门禁：`flutter analyze`、`flutter test`

## P7 清理与最终验收

- [x] 清理 `TranslationEngineKind` 及旧文案的引用
- [x] 全仓 grep 确认没有残留 `settingsLocalizationLocalBundled` 等旧键
- [x] `flutter gen-l10n`
- [x] `flutter analyze` 必须 `No issues found`
- [x] `flutter test` 全绿
- [x] 手工验收（Linux）：
  - [ ] 无配置启动：无请求、原文正常、设置页说明原因
  - [ ] 选 DeepSeek / Moonshot / OpenRouter / SiliconFlow：翻译与余额
  - [ ] 选 OpenAI / Anthropic / Gemini：翻译与用量
  - [ ] 本地模型：未安装 → 下载 → 翻译 → 删除
  - [ ] 旧配置升级：Key 与模型不丢
- [x] 更新 `.trae/specs/translation-providers/spec.md` 的状态为“已实施”

## 实施说明

- `test/domain/localization_config_test.dart` 落在 `test/features/localization/localization_config_test.dart`（测试目录按现有布局归档）。
- `.gitattributes` 只有这两条 LFS 规则，删除资产后整份文件一并移除。
- `.gitignore` 保留 `translation/bin/llama-b12274/`：离线打包脚本仍会就地解包运行时，产物不应入库。
- 手工验收中的厂商 API 用例需要真实 Key，未在本次自动化里执行；无配置、降级、本地模型状态机由单元/组件测试覆盖。
