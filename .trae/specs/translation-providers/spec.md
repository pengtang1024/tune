# 翻译默认策略改造：厂商 API 优先，本地模型改为可选组件

> 状态：已实施（P1–P7 完成；厂商真实 Key 的手工验收待补）。
> 日期：2026-11-13
> 关联：`.trae/specs/translation-model-lfs/`（“随包分发”方案，本次推翻其默认随包决策）
> 边界：**不触碰迷你模式 / shell 并行线的文件**。本 spec 只涉及翻译、设置页、打包脚本与文档。

## 1. 现状（代码事实）

| 现状 | 位置 |
| --- | --- |
| 只有 `local` / `openAiCompatible` 两种引擎，单一 `apiBaseUrl/apiKey/apiModel` | `lib/domain/models/localization_config.dart` |
| 设置页只有一个“端点 / Key / 模型”输入块，无厂商概念 | `lib/features/settings/presentation/settings_localization_card.dart` |
| 余额只支持 DeepSeek / Moonshot / OpenRouter / SiliconFlow，其余返回 `supported: false` | `lib/data/services/translation/translation_balance.dart` |
| 本地模型与 llama.cpp 运行时随 Linux 包分发，走 Git LFS | `tool/package_linux.sh`、`tool/prepare_translation.sh`、`.gitattributes`、`translation/` |
| 未配置 API 时仍会创建仓库；`enabled=true` 时逐行请求，失败后静默回退原文 | `lib/features/localization/application/localization_providers.dart` |
| 本地模型缺失时提示“请重新安装应用”，没有下载入口 | `lib/features/localization/application/local_model_controller.dart` |

## 2. 目标

1. 默认安装包不再携带本地模型；`translation/` 里的 gguf 与 llama 运行时不再是必需件。
2. 本地模型改为设置页按需下载、显示进度与占用、可删除；未安装时入口写“未安装，可下载”，不报错。
3. 默认走厂商模型 API，用户选厂商 + 填 Key 即用；覆盖第一批 11 家 + “自定义 OpenAI 兼容”。
4. 未配置任何厂商时翻译**关闭**：不发请求、不报错、界面显示原文。
5. 说清会发送哪些文本；Key 有明确的存放方式与风险提示；用量与余额只展示能查到的数据。

## 3. 非目标

- 不做账号体系、OAuth 登录、团队配额管理。
- 不做流式翻译、并发多厂商回退、按字段选不同厂商。
- 不做费用估算表（价格会变，算出来的数字不可信）。
- 不改歌词、音频、文件路径相关链路；这些文本不进入翻译请求。
- 不改迷你模式 / shell 的文件与行为。

## 4. 厂商清单（第一批）

端点与模型名以实现时官方文档为准；下表是初始默认值，设置页允许改模型名。

| 厂商 | id | 协议 | 默认端点 | 默认模型 | 模型选项 | 余额 |
| --- | --- | --- | --- | --- | --- | --- |
| OpenAI | `openai` | OpenAI Chat | `https://api.openai.com/v1` | `gpt-4o-mini` | 精选 + 手填 | 无公开接口 |
| Anthropic | `anthropic` | Anthropic Messages | `https://api.anthropic.com/v1` | `claude-3-5-haiku-latest` | 精选 + 手填 | 无 |
| Google Gemini | `gemini` | Gemini generateContent | `https://generativelanguage.googleapis.com/v1beta` | `gemini-2.0-flash` | 精选 + 手填 | 无 |
| DeepSeek | `deepseek` | OpenAI Chat | `https://api.deepseek.com/v1` | `deepseek-chat` | `deepseek-chat` / `deepseek-reasoner` + 手填 | 有（现有实现） |
| Moonshot / Kimi | `moonshot` | OpenAI Chat | `https://api.moonshot.cn/v1` | `moonshot-v1-8k` | 精选 + 手填 | 有（现有实现） |
| 通义 / DashScope | `dashscope` | OpenAI Chat（兼容模式） | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-turbo` | `qwen-turbo` / `qwen-plus` / `qwen-max` + 手填 | 无公开接口 |
| 智谱 GLM | `zhipu` | OpenAI Chat | `https://open.bigmodel.cn/api/paas/v4` | `glm-4-flash` | 精选 + 手填 | 无公开接口 |
| Groq | `groq` | OpenAI Chat | `https://api.groq.com/openai/v1` | `llama-3.1-8b-instant` | 精选 + 手填 | 无 |
| OpenRouter | `openrouter` | OpenAI Chat | `https://openrouter.ai/api/v1` | `openai/gpt-4o-mini` | 大量 + 手填 | 有（现有实现） |
| 硅基流动 | `siliconflow` | OpenAI Chat | `https://api.siliconflow.cn/v1` | `Qwen/Qwen2.5-7B-Instruct` | 精选 + 手填 | 有（现有实现） |
| 本地 Ollama | `ollama` | OpenAI Chat | `http://127.0.0.1:11434/v1` | 首个可用模型 / 手填 | 读 `/api/tags`，失败则手填 | 不适用 |
| 自定义 | `custom` | OpenAI Chat | 用户填 | 用户填 | 手填 | 按端点能力 |

第二批（本次不做，留扩展位）：Mistral、xAI、百度千帆、火山方舟、腾讯混元、MiniMax、Together、Fireworks、Cerebras。

### 4.1 协议差异

- **OpenAI Chat 兼容族**（9 家 + 自定义）：一个适配器即可。差异只在 `baseUrl`、鉴权头、可选额外头、以及个别端点不返回 `usage`。
- **Anthropic Messages**：路径 `/messages`，头 `x-api-key` + `anthropic-version: 2023-06-01`，`system` 与 `messages` 分开，必须带 `max_tokens`；响应 `content[]` 里取 `text`；用量字段是 `input_tokens` / `output_tokens`。没有 OpenAI 兼容层，必须单独适配。
- **Gemini generateContent**：路径 `/models/{model}:generateContent`，头 `x-goog-api-key`；`systemInstruction` 与 `contents` 分开；响应 `candidates[0].content.parts[*].text`；用量在 `usageMetadata`。有 OpenAI 兼容层，但原生适配能稳定拿到用量，建议原生。
- 三家都可能把 JSON 包在 Markdown 代码块里；现有 `parseTranslationPayload` 用首个 `[` 与最后一个 `]` 截取，已能兜住，不需要各写一套解析。

## 5. 配置模型与迁移

### 5.1 新模型

`lib/domain/models/localization_config.dart`：

```text
LocalizationConfig
  enabled: bool
  showOriginal: bool
  backendId: String            // 'local' | 厂商 id | 'custom'
  credentials: Map<String, ProviderCredential>
ProviderCredential
  apiKey: String
  model: String
  baseUrlOverride: String      // 仅 custom 使用
```

- 每个厂商各存一份 Key 与模型，切换厂商不丢配置。
- `effectiveConfigured`：`backendId` 非空，模型非空，且（厂商允许空 Key 或 Key 非空）。
- 旧 JSON 迁移：`engine=local` → `backendId=local`；`engine=openAiCompatible` → `backendId=custom`，把旧的 `apiBaseUrl/apiKey/apiModel` 写进 `custom` 的 credential；旧字段不再写回。

### 5.2 单一事实来源

- 配置仍只存在 `SettingsController` 的 `localization` 字段，持久化仍走 `settings_controller.dart` 的 `localization` 键。
- 厂商目录是**只读常量表**，不是状态，不参与持久化。
- 本地模型安装状态由 `LocalModelController` 一家持有；`TranslationAssets` 只负责路径与校验，不缓存“是否已安装”的业务结论。

## 6. Key 的存放

推荐 v1：

- 非敏感配置（厂商、模型、baseUrl）继续放现有设置 JSON。
- Key 单独写入 `<support>/translation_keys.json`，写入后 `chmod 600`（Windows 用 ACL 尽力而为）。
- 设置页明确写：“密钥以明文保存在本机配置目录，仅当前用户可读。”
- 不把 Key 写进日志、错误信息、导出文件。

可选（建议后续再做）：

- `flutter_secure_storage`：Linux 走 libsecret / gnome-keyring，Android 走 Keystore，Windows 走 DPAPI。
- 风险：无 keyring 的 Linux 桌面会失败，必须有回退；因此不放进 v1 的必做项。

## 7. 会发送哪些文本

设置页在启用翻译前展示一份固定清单：

- **发送**：曲名、专辑名、歌单名、简介 / 播客正文、电台文本、在线搜索结果里需要翻译的文本。
- **不发送**：音频文件、歌词、文件路径、歌手名（当前 UI 不翻译歌手）、播放历史、账号信息。
- 发送目标是用户所选厂商的端点；缓存只存译文与原文本哈希，存在本地数据库。
- 首次启用或切换厂商时给一次确认提示，确认后记住。

## 8. 用量与余额

- **用量**：沿用现有本地账本，按 `engine.id` 记录 `prompt_tokens` / `completion_tokens`，设置页显示“今日 tokens”。
- **余额**：只保留已验证的四家：
  - DeepSeek：`GET https://api.deepseek.com/user/balance`
  - Moonshot：`GET {baseUrl}/users/me/balance`
  - OpenRouter：`GET https://openrouter.ai/api/v1/credits`
  - SiliconFlow：`GET {baseUrl}/user/info`
- 其余厂商显示“该端点未提供余额查询”，**不猜、不估算**。
- 响应里没有 `usage` 时记 0，并显示“端点未返回用量”，不能用字符数反推 token。

## 9. 降级行为矩阵

| 情况 | 行为 |
| --- | --- |
| 未选择厂商 | 翻译关闭；不发请求；行显示原文；设置页显示“未配置翻译服务”+ 入口 |
| 选了厂商但 Key 为空（Ollama / 自定义除外） | 同上，提示“缺少密钥” |
| 选本地但未安装 | 同上，提示“本地模型未安装（约 470 MB），可下载” |
| 本地已安装 | 正常翻译 |
| 请求 401 / 网络失败 | 行显示原文；设置页显示最近一次错误；不逐行报错 |
| 缓存命中 | 不发请求 |
| 端点未返回 `usage` | 账本记 0，不估算 |

实现上新增 `translationAvailabilityProvider`，`translatedTextProvider` 先看它；不可用时直接返回 `null`，不创建仓库、不抛异常。

## 10. 本地模型改为可选下载

### 10.1 分发

- 镜像与运行时打成一个可选组件包：`tune-translation-qwen2.5-0.5b-b12274.zip`（约 500 MB），作为 GitHub Release 附件发布。
- 仓库只保留 `translation/manifest.json` 与 `translation/licenses/`（体积很小），不再保留 gguf 与运行时归档。
- `manifest.json` 固定：版本、包 URL、字节数、sha256、安装后目录结构、许可证文件名。
- 支持 `TUNE_TRANSLATION_BASE_URL` 覆盖下载源，方便镜像 / 内网。
- 默认更新包回到约 41 MiB；更新替换 bundle 不影响用户目录里已下载的模型。

### 10.2 安装与卸载

新增 `lib/data/services/translation/local_model_installer.dart`：

- `install({onProgress})`：下载到 `<support>/translation/.download/` → 校验大小与 sha256 → 解包 → 原子重命名到 `<support>/translation/` → 写 `installed.json`。
- `remove()`：只删用户目录里的安装，不碰旧安装包自带的只读副本。
- `sizeOnDisk()`：设置页显示占用。
- 下载进度用 `dio.download` 的 `onReceiveProgress`，状态只更新设置页那一块。
- v1 不做断点续传；失败重来，临时目录清理。

### 10.3 路径解析

`TranslationAssets.resolve` 的优先级改为：

1. `TUNE_TRANSLATION_DIR`（开发 / 测试覆盖）
2. `<support>/translation`（用户下载）
3. `<exe>/translation`（旧安装包自带，兼容升级用户）
4. 仓库根目录（`flutter run`）
5. 旧的应用支持目录布局

只读的旧副本可以正常使用，但设置页不提供“删除”。

### 10.4 启动检查

- 启动**不**检查、不下载、不校验模型。
- 只有设置页打开本地块，或用户选择本地后端时，`LocalModelController` 才检查。
- 本地引擎每批翻译只做轻量 size 检查；sha256 在安装时验一次，不在每批重复算。

### 10.5 设置页

本地块状态机：

```text
checking → notInstalled → downloading → verifying → ready
                ↑              ↓            ↓
                └────────── failed ←───────┘
```

- `notInstalled`：说明体积、许可证、下载按钮。
- `downloading`：百分比 + 已下载 / 总量 + 取消。
- `verifying`：校验中。
- `ready`：占用空间 + 删除按钮（仅用户目录安装）。
- `failed`：错误原因 + 重试。

## 11. 建议拆分顺序

| 阶段 | 内容 | 可独立验证 |
| --- | --- | --- |
| P1 | 配置模型重构 + 厂商目录 + OpenAI 兼容适配器 + 设置页最小厂商选择 | `flutter analyze` / 配置迁移测试 |
| P2 | Anthropic / Gemini 原生适配器 + 模型建议项 + 余额表驱动 | 三家协议 fixture 测试 |
| P3 | 未配置降级：可用性 provider、关闭态、隐私清单、错误收敛 | 未配置时不发请求的测试 |
| P4 | 本地模型下载器 + 安装状态机 + 设置页下载/删除 | 临时目录安装/卸载测试 |
| P5 | 打包与分发：默认包瘦身、manifest、LFS 清理、离线包入口 | 打包脚本 dry-run |
| P6 | 文档、许可证、旧文案清理、全量门禁 | `flutter analyze` + `flutter test` |

依赖关系：P1 → P2/P3；P4 独立；P5 必须在 P4 之后；P6 最后。

## 12. 验收

- Linux release 包不含 `translation/`，体积回到约 41 MiB。
- 新装用户不配置厂商时：翻译不发起任何网络请求，界面正常显示原文，设置页说明原因。
- 选任一第一批厂商 + 有效 Key：能翻译，缓存与今日 token 正常累加。
- 四家余额接口仍可用；其余厂商显示“未提供余额查询”。
- 本地模型未安装时提示可下载；下载完成后可翻译；删除后回到未安装状态。
- 旧配置（`local` / `openAiCompatible`）升级后不丢 Key 与模型。
- `flutter analyze` 无问题，`flutter test` 全绿，`flutter gen-l10n` 产物已提交。

## 13. 风险

- 厂商端点与模型名会变：默认值只是初始值，必须允许手填；文档注明“以官方为准”。
- 500 MB 组件包的托管与下载成功率：需要 Release 附件、镜像覆盖与失败重试提示。
- 明文 Key 是已知取舍；设置页必须写清楚，后续可换 keyring。
- 旧安装包自带的 `translation/` 在整包更新后会消失；升级后首次打开本地块要提示“可重新下载”。
- 不碰迷你模式 / shell：`git status` 里属于该并行线的未提交文件不回退、不夹带。

## 14. 需要拍板

1. Key 存放：v1 用“单独文件 + 0600”（推荐），还是直接上 `flutter_secure_storage`？
2. 本地模型资产：从 Git / LFS 删除、改走 Release 附件（推荐），还是继续留在 LFS 但不随包？
3. 未配置厂商时：`enabled` 保持开、实际暂停（推荐），还是直接把开关置为关？
4. 模型选择：静态精选 + 手填（推荐），还是每次打开都拉 `/models`？
5. 余额：只显示四家官方接口（推荐），还是要加价格表估算？
6. 是否保留“自定义 OpenAI 兼容”入口（推荐保留）。
7. 第一批是否就是上表 11 家 + 自定义，还是先砍到 6 家？
8. 本地组件包下载源：GitHub Release（推荐）还是另有镜像 / CDN？
9. 是否保留维护者用的“离线包”打包开关（推荐保留，不发布为更新附件）？
