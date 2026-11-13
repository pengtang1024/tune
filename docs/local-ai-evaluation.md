# 本地 AI 选型评估（ASR / 翻译 / 音频解码）

> 评估日期：2026-11-13。范围：只评估，不改代码。
> 结论见 §1，逐项对比见 §3–§5，许可证清单见 §6，需要拍板的见 §7。
> 体积与内存是公开资料的量级估算，**不是本文档实测值**；落地前须在目标机与目标机型上量一遍。

## 1. 结论速览

| 层 | 现在的组合 | 建议的组合 | 一句话理由 |
| --- | --- | --- | --- |
| ASR 运行时 | `whisper-cli` 子进程 + `sherpa-onnx-offline` 子进程 | **Linux 保留子进程**（崩溃隔离、系统优先）；**Android 新增 `sherpa_onnx` FFI 后端**；是否两端统一 FFI 由 D1 拍板 | 子进程在 Android 上不成立；Linux 的隔离层不必为了 Android 删掉 |
| ASR 模型 | 默认 `tiny`，可选 `base` / `small` | 默认两票：**Whisper `small`（质量锚）+ SenseVoice-Small int8（中文快锚）**；低配 `base`；`large-v3-turbo` 作为可选质量包 | `tiny` 是占用下限，不是质量档；两票算法不同，互证关系保留 |
| 翻译 | `llama-cli` 子进程 + Qwen2.5-0.5B q4_k_m | **Linux 保留子进程；Android 用 llama.cpp FFI**；模型换 Qwen3-0.6B（默认）/ Qwen2.5-0.5B（低配）/ 1.5B（可选） | Android 没有可执行文件；Qwen3-0.6B 更新、仍是 Apache-2.0 |
| 解码 | Linux 系统 FFmpeg，不随包 | Linux 保持系统 FFmpeg；**Android 走 MediaCodec**；仍不随包 FFmpeg | 许可证最干净；Android 没有 ffmpeg 可执行文件 |

### 1.1 三个必须纠正的点

1. **SenseVoice 的权重不是 Apache/MIT。** [smart-lyrics.md](smart-lyrics.md) 的 M12 摘要与 §6.2 写「SenseVoice via sherpa-onnx（Apache/MIT）」，这混淆了运行时与权重：sherpa-onnx 运行时是 Apache-2.0，SenseVoiceSmall 权重是阿里自定义的《FunASR 模型开源协议》v1.1。详见 §6.1。
2. **whisper.cpp 有词级时间戳，只是现在没打开。** 当前 [whisper_local_engine.dart](../lib/data/services/smart_lyrics/whisper_local_engine.dart) 的转写调用只传 `-oj`，拿到的是 segment 级 `offsets`；whisper.cpp 支持 `-ml 1` 词级切分与 `--dtw` 更准的时间对齐。因此「whisper 无词级时间戳」不成立，准确说法是「当前调用没有启用」。
3. **默认 `tiny` 不是可辩护的质量档。** 它适合「低占用可用」，不适合作为中文歌词/播客的默认；`base` 也只是过渡。中文场景应把默认两票提到 Whisper `small` + SenseVoice-Small int8，`tiny` 只留作最低占用档；内存不足的机器再退到 `base`。

## 2. 评估口径与现状

### 2.1 现状（代码依据）

| 能力 | 现状 | 关键约束 |
| --- | --- | --- |
| 本地 ASR（Whisper） | [whisper_local_engine.dart](../lib/data/services/smart_lyrics/whisper_local_engine.dart) 起 `whisper-cli` 子进程，产物落 JSON 后读回；系统已装优先，[whisper_model_store.dart](../lib/data/services/smart_lyrics/whisper_model_store.dart) 从 HF 下载并校验 sha256 | 默认 `tiny`，可选 `tiny/base/small`；ffmpeg 只在 m4a 等格式上兜底 |
| 本地 ASR（第二家族） | [sherpa_local_engine.dart](../lib/data/services/smart_lyrics/sherpa_local_engine.dart) 起 `sherpa-onnx-offline` 子进程，按 token 起始时间的静默间隙切行 | 只认 WAV；模型 `model.int8.onnx`（SenseVoice） |
| 跨平台 | [app_capabilities.dart](../lib/core/config/app_capabilities.dart) 的 `externalToolPipeline` 在 Android 为 `false` | Android 不能执行应用数据目录里的外部二进制 |
| 翻译 | [llama_local_translation_engine.dart](../lib/data/services/translation/llama_local_translation_engine.dart) 起 `llama-cli` 子进程；云端走 [translation_provider_catalog.dart](../lib/data/services/translation/translation_provider_catalog.dart) | 本地组件单独下载；目标语言只有 `en` / `zh-CN` / `zh-TW`（[text_language.dart](../lib/features/localization/domain/text_language.dart)） |
| 解码 | Linux 系统 ffmpeg 转 16k 单声道 WAV；不捆绑 | Ubuntu 的 libmpv/FFmpeg 是 GPL 构建，只作系统依赖 |

### 2.2 评估口径

- **许可证**：代码许可证与**模型权重许可证**分开看；重点看非商用条款、署名义务、再分发限制、可撤销条款。
- **体积**：随包或首次下载的大小；量化档单独标注。
- **内存**：推理常驻的粗估；CPU 占用与实时率强依赖机器，必须实测。
- **时间戳**：是否给到词/字级起止；只有段级时间戳时，歌词行切分靠静音间隙。
- **分发**：能否随安装包/组件包分发；不能随包时是否有系统依赖兜底。
- **平台**：Linux 桌面优先；Android 只接受「随包原生库 + FFI/平台通道」，不接受子进程。

## 3. ASR 选型

### 3.1 候选对比

| 运行时 + 模型 | 许可证（代码 / 权重） | 体积（约） | 内存（粗估） | 词级时间戳 | 中文歌词/播客 | 长音频 | 随包 | 结论 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| whisper.cpp + tiny | MIT / MIT | 75 MiB | 0.3–0.5 GB | 支持（`-ml 1`、`--dtw`） | 弱；音乐底噪下错误率高 | 30 s 窗口，静音段易幻觉 | 能 | 只保留为「最低占用」 |
| whisper.cpp + base | MIT / MIT | 142 MiB | 0.5–0.7 GB | 支持 | 一般 | 同上 | 能 | 低配第二票 |
| whisper.cpp + small | MIT / MIT | 466 MiB | 0.8–1.2 GB | 支持 | 可用；比 tiny/base 明显稳 | 同上，建议配 VAD | 能 | **默认两票之一（质量锚）** |
| whisper.cpp + large-v3-turbo | MIT / MIT | ≈1.6 GB f16；q5/q8 更小 | 1.5–2.5 GB | 支持 | 本地 Whisper 里最好的一档 | 同上，CPU 实时率需实测 | 能 | 可选质量包，不默认下载 |
| sherpa-onnx + SenseVoice-Small int8 | Apache-2.0 / **FunASR 自定义协议** | 228 MB int8；894 MB fp32 | 0.8–1.2 GB | **token 起始时间**，无结束时间 | 中文/粤语/英/日/韩；非自回归，快 | 需 VAD/分片；长音频按片拼 | 有条件（见 §6.1） | **默认两票之一（中文快锚）** |
| sherpa-onnx + Paraformer-zh | Apache-2.0 / Apache-2.0 | ≈230 MB int8 | 0.7–1.0 GB | 逐模型不同：部分导出有，部分为空 | 普通话强，非自回归 | 需 VAD 分片 | 能 | 可选第三家族；时间戳先实测 |
| sherpa-onnx + Zipformer（中英/流式） | Apache-2.0 / Apache-2.0 | 小模型约 100–200 MB | 0.3–0.5 GB | 支持（transducer） | 读语音训练，唱歌弱于 Whisper | 流式天然适合长音频 | 能 | 低延迟场景可选 |
| sherpa-onnx + Whisper ONNX | Apache-2.0 / MIT | 与 Whisper 档位相当 | 与 Whisper 相当 | 支持（1.12.24 起） | 同 Whisper | 同 Whisper | 能 | 想只留一个运行时时的替代 |
| faster-whisper / CTranslate2 | MIT / MIT | 同 Whisper | 同 Whisper | 支持（word timestamps） | 同 Whisper | 好 | 能，但要 Python 或自建 C++ 绑定 | **否**：Python 栈与 Flutter 打包不匹配 |
| Vosk + 中文小模型 | Apache-2.0 / Apache-2.0 | 约 40–50 MB | 0.3–0.6 GB | 支持（word） | 明显弱于 Whisper/SenseVoice | 流式好 | 能 | **否**：精度不够 |
| Moonshine | MIT / MIT | 小 | 低 | 部分 | 英语为主，中文不在范围 | 好 | 能 | **否**：语言不匹配 |
| FunASR Python 运行时 | MIT / 权重逐模型 | — | — | Paraformer 有 | 中文强 | 好 | 不能直接进 Flutter | **否**：运行时形态不匹配 |
| Demucs 人声分离（前置） | MIT（权重需再核） | 数百 MB | 1–2 GB | 不适用 | 能显著提升歌词识别 | 离线批处理 | 能但重 | 暂不做；列为后续实验 |

> SenseVoice 的「token 起始时间」足够切行，但不是严格意义的词级起止；当前实现正是按相邻 token 起始时间的静音间隙切行。

### 3.2 ASR 结论

- **Android 必须有 FFI 后端，Linux 不必拆掉隔离层**：`sherpa_onnx` 是 k2-fsa 官方维护的 Flutter 包，覆盖 Android / iOS / Linux / Windows / macOS，支持 Whisper、SenseVoice、Paraformer、Zipformer、Moonshine、TeleSpeech 与 VAD。用它在 Android 上替掉子进程，同时保留 Linux 现有的「系统二进制优先 + 进程隔离」。这会多一个后端，但比两端统一 FFI 多一层崩溃隔离；是否合并由 D1 拍板。
- **FFI 的代价是失去进程边界**：native 崩溃会带走整个 app。若最终选择两端统一 FFI，必须把调用放进独立 isolate、给模型加载与推理加硬超时，并把「引擎崩溃 → 该票软失败」纳入健康度，不能假定 FFI 一定不崩。
- **模型保留两个独立家族并默认常开**：Whisper `small`（MIT，质量锚，段级/词级都行）+ SenseVoice-Small int8（中文/粤语/英/日/韩，228 MB，快，中文快锚）。两者算法不同，互证关系不变；低内存机型退到 Whisper `base` + SenseVoice，最低占用档才用 `tiny`。
- **可选质量档**：`large-v3-turbo` 只在用户主动下载时启用；不要默认，CPU 实时率与内存都要先实测。
- **Paraformer 不设为默认**：时间戳随导出而变（有的 `timestamps` 为空），且读语音训练对唱歌不一定优于 Whisper；可作为第三家族，但必须先验证目标模型的时间戳。
- **whisper.cpp 的第二 FFI 库只在实测必要时引入**：如果 sherpa-onnx 的 Whisper 路径在目标机上明显慢，再把 whisper.cpp 作为独立 FFI 库加回来；它只补 Android/性能缺口，不替换 Linux 现有的子进程路径。
- **必须加 VAD**：长音频、纯音乐段、掌声段是幻觉高发区；Silero VAD（MIT）可直接由 sherpa-onnx 提供。
- **体积与内存预算**：两票模型合计约 700 MB（466 + 228），但**串行加载**，峰值内存取较大者（约 1.2 GB），不要同时驻留；组件按需下载，下载完成后默认两票常开。

## 4. 翻译选型

### 4.1 候选对比

| 模型 | 许可证（代码 / 权重） | 体积（约） | 内存（粗估） | 上下文/术语表 | 中文输出 | 多语覆盖 | 随包 | 结论 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Qwen2.5-0.5B-Instruct q4_k_m | Apache-2.0 / Apache-2.0 | ≈0.4 GB | 0.7–1.0 GB | 有；可给 JSON 与术语约束 | 可用，短文本稳 | 多语 | 能 | 低配保留 |
| **Qwen3-0.6B** | Apache-2.0 / Apache-2.0 | ≈0.5 GB | 0.8–1.1 GB | 有；`/no_think` 可关思考 | 通常优于 2.5-0.5B | 多语 | 能 | **建议默认**（先 A/B） |
| Qwen2.5-1.5B / Qwen3-1.7B | Apache-2.0 / Apache-2.0 | ≈1.0–1.1 GB | 1.5–2.0 GB | 有 | 明显更好 | 多语 | 能 | 可选高清包 |
| Opus-MT（逐语言对） | MIT / CC-BY-4.0（部分 Apache-2.0） | 每对约 80–300 MB | 0.3–0.5 GB | 无；无术语表 | 直译稳，风格与专名弱 | 需按方向逐个下载 | 能（署名） | **否**：模型组合爆炸，不解决简介/播客 |
| Bergamot（逐语言对） | 代码常见 MPL-2.0；权重逐模型核对 | 每对更小 | 低 | 无 | 浏览器短句向 | 需逐对 | 能（逐模型核对） | **否**：不比 Opus-MT 更适合中文 |
| M2M-100 418M | MIT / MIT | ≈1.7 GB fp32；int8 更小 | 0.8–1.2 GB | 无 | 2020 年模型，弱于 Qwen | 101 语 | 能 | **否**：许可证干净但质量落后 |
| NLLB-200 distilled 600M | MIT / **CC-BY-NC-4.0** | ≈2.4 GB fp32 | 1.0–1.5 GB | 无 | 较好 | 200 语 | **不能**（非商用） | **否决** |
| Gemma 3 270M | Gemma Terms / Gemma Terms | ≈0.3–0.5 GB | 0.6–0.9 GB | 有 | 可用 | 多语 | 有条件（非 OSI） | **否决**：使用限制需向下游传递 |
| SmolLM2-360M-Instruct | Apache-2.0 / Apache-2.0 | ≈0.4 GB | 0.7–1.0 GB | 有 | 英文向，中文弱 | 以英文为主 | 能 | **否**：中文输出不稳 |
| 云端（OpenAI/Anthropic/Gemini/DeepSeek 等） | 服务条款 | — | — | 强 | 强 | 强 | 不适用 | 保留为可选；不涉及模型再分发 |

### 4.2 翻译结论

- **保留 LLM 路线**：Tune 的翻译对象是曲名、专辑、简介、播客正文，需要上下文、术语表、JSON 结构与「不翻译人名」的约束；0.5B 级 instruct 模型虽然小，但比逐对 MT 模型更适合这些约束。
- **默认模型升级到 Qwen3-0.6B**，保留 Qwen2.5-0.5B 作低配；再提供一个 1.5B/1.7B 的可选「高清」组件。三者都是 Apache-2.0，随包与声明成本最低。
- **专用 MT 模型不做主引擎**：Opus-MT 每对语言一个模型，目标语只有 `en` / `zh-CN` / `zh-TW`，但源语任意，组合会膨胀；且它没有术语表、上下文与 JSON 约束，简介和播客正文会明显吃亏。若将来要「微秒级 UI 短词快车道」，再单独评估 Opus-MT，并接受 CC-BY-4.0 署名。
- **明确否决 NLLB 与 Gemma 3**：前者 CC-BY-NC-4.0，不能随商用包分发；后者是 Gemma Terms，不是 OSI 许可证，需要把使用限制传递给下游，和本项目「MIT + 干净许可证」的姿态冲突。
- **Android 用 FFI，Linux 可保留子进程**：`llama-cli` 每批一次进程启动 + 模型加载，短文本场景的固定开销占比很高；但 Linux 上这层进程边界也带来崩溃隔离。建议 Android 走 llama.cpp FFI，Linux 先保留现状，除非实测显示进程启动开销不可接受。llama.cpp 是 MIT，自己维护一层薄绑定比依赖低维护的第三方包更稳。

## 5. 音频解码与转码

### 5.1 候选对比

| 方案 | 许可证 | 覆盖 | 随包 | 平台 | 结论 |
| --- | --- | --- | --- | --- | --- |
| 系统 FFmpeg（现状） | 发行版构建；Ubuntu 为 GPL-2+ | 几乎全格式 | 不随包 | Linux | **保留**：Linux 兜底，零新增许可证面 |
| Android MediaCodec / MediaExtractor | 平台 API | AAC/m4a、mp3、flac 等 | 不随包 | Android | **建议新增**：Android 唯一干净路径 |
| 随包 FFmpeg（LGPL 构建） | LGPL-2.1+ | 全格式 | 有条件 | 全平台 | 仅当必须自带时；动态链接 + 源码 + 可替换 |
| ffbinaries `ffmpeg-4.4.1-linux-64.zip`（组件化 spec 计划） | 需核对构建配置；常见 Linux 静态构建为 GPL；4.4.1 是 2021 年版本 | 全格式 | **先核对，不要自托管** | Linux | 若是 GPL 构建，与 `docs/licensing.md` 的红线冲突；且版本过旧 |
| ffmpeg-kit / FFmpegKitNext | LGPL/GPL 变体 | 全格式 | 有条件 | 移动端为主 | **否**：ffmpeg-kit 已退役；Next 仅源码 |
| Symphonia（Rust） | MPL-2.0 | AAC/ALAC/FLAC/MP3/Vorbis/WAV | 能 | 需 Rust + FFI | 备选；多一条工具链，先验证 m4a |
| miniaudio | MIT-0 / 公共领域 | WAV/MP3/FLAC/Vorbis | 能 | 全平台 | **否**：不解决 m4a/AAC |
| 系统 GStreamer | LGPL | 全格式 | 不随包 | Linux | 备选；桌面存在但不保证装齐插件 |
| 系统 libmpv | GPL-3+ | 全格式 | **不能** | Linux | 只作播放后端，不用于转码分发 |

### 5.2 FFmpeg 的 LGPL / GPL 边界

- **LGPL 构建**（不带 `--enable-gpl`、不带 `--enable-nonfree`）：可以随包，但必须动态链接、随包提供**完全对应的源码**、保留许可证与版权声明、并让用户能用修改后的库替换（LGPL §6 的 relink 要求）。LGPL 允许闭源应用动态链接；**静态链接同样触发 §6**，需要额外提供目标文件让用户能重链接。
- **GPL 构建**（`--enable-gpl`，Ubuntu 默认就是）：随包分发时必须按 GPL 提供该程序及对应源码；若把它和 Tune 做成一个自包含组合作品，整个组合的分发都要满足 GPL。若做 AppImage/Flatpak 把系统 libmpv/FFmpeg 打进去，同样按 GPL 处理。
- **ffmpeg-kit** 已退役，历史二进制在陆续下架；FFmpegKitNext 只发源码，等于自己维护交叉编译链。不建议把它作为新依赖。

### 5.3 解码结论

- **Linux 继续「系统已装才用」**，不随包；文档里已经写清楚 GPL 组合分发义务，保持不变。
- **Android 用 MediaCodec 解到 PCM，再喂 ASR**；这是平台 API，没有再分发问题，也不需要外部二进制。
- **不引入 Symphonia/miniaudio**：前者多一条 Rust 工具链，后者解决不了 m4a；当前收益不抵复杂度。
- **统一成一步「解码到 16k 单声道 WAV」**：Whisper 能吃 mp3/flac/ogg/wav，但 sherpa-onnx 只认 WAV；m4a 两边都要先解。把这一步收在一个解码接口后面，ASR 引擎不再各自处理格式。

### 5.4 平台可行性

| 方案 | Linux | Android | 结论 |
| --- | --- | --- | --- |
| `sherpa_onnx` FFI | 成立 | 成立 | 两端都可用 |
| whisper.cpp FFI（随包 `.so`） | 成立 | 成立 | 两端都可用 |
| `whisper-cli` 子进程 | 成立 | **不成立** | 只能 Linux |
| llama.cpp FFI | 成立 | 成立 | 两端都可用 |
| `llama-cli` 子进程 | 成立 | **不成立** | 只能 Linux |
| 系统 FFmpeg | 成立 | **不成立** | 只能 Linux |
| Android MediaCodec | 不成立 | 成立 | 只能 Android |
| 系统 libmpv / GStreamer | 成立 | 不成立 | 只能 Linux |

## 6. 许可证风险清单

> 判定口径：Tune 自己是 MIT。能随包 = 可以进安装包或可选组件包；有条件 = 可以，但必须完成声明/链接/源码义务；不能 = 不要随包。

### 6.1 模型权重（重点）

| 组件 | 许可证 | 能否随包 | 必须做什么 / 风险 |
| --- | --- | --- | --- |
| OpenAI Whisper 权重（tiny/base/small/large-v3-turbo） | MIT | **能** | 保留版权与许可文本；无署名以外的义务 |
| SenseVoiceSmall 权重 | **FunASR 模型开源协议 v1.1**（阿里自定义） | **有条件** | 注明出处与作者、保留 `SenseVoice` 模型名；协议写「仅作为参考和学习使用」，且有「诋毁即可终止许可」条款；协议里的管辖地还是占位符 `[国家/地区]`。建议法务确认，或改用 Paraformer |
| Paraformer 权重 | Apache-2.0 | **能** | 保留 LICENSE/NOTICE；商标不随许可授予 |
| Zipformer / icefall 权重 | Apache-2.0（逐模型核对） | **能** | 同上；sherpa-onnx 文档明确要求逐个模型看许可证 |
| Silero VAD | MIT | **能** | 保留版权与许可文本 |
| Qwen2.5 / Qwen3 | Apache-2.0 | **能** | 保留 LICENSE/NOTICE；不要暗示 Qwen 背书 |
| Opus-MT 权重 | CC-BY-4.0（部分 Apache-2.0） | **能** | 署名 Helsinki-NLP、保留许可文本、注明是否修改 |
| M2M-100 权重 | MIT | **能** | 保留版权与许可文本 |
| NLLB-200 权重 | **CC-BY-NC-4.0** | **不能** | 非商用；模型卡还写明「不面向生产部署」 |
| Gemma 3 权重 | Gemma Terms of Use | **有条件/不建议** | 非 OSI；再分发须传递使用限制与协议副本；有禁止用途政策 |

### 6.2 运行时与解码

| 组件 | 许可证 | 能否随包 | 必须做什么 / 风险 |
| --- | --- | --- | --- |
| whisper.cpp | MIT | **能** | 保留版权与许可文本 |
| sherpa-onnx | Apache-2.0 | **能** | 保留 LICENSE/NOTICE；专利授权条款对下游有利 |
| llama.cpp | MIT | **能** | 保留版权与许可文本 |
| FFmpeg（LGPL 构建） | LGPL-2.1+ | **有条件** | 动态链接、提供对应源码、保留声明、允许替换库 |
| FFmpeg（GPL 构建）/ libmpv | GPL-2+/GPL-3+ | **不能随包** | 只能作为系统依赖；组合分发按 GPL |
| Android MediaCodec | 平台 API | **不适用** | 无再分发义务 |
| Symphonia | MPL-2.0 | **能** | 文件级 copyleft：修改过的 MPL 文件需公开该文件源码 |

### 6.3 当前仓库的合规缺口

> 现状是「用户自装二进制 / 运行时下载模型」，Tune 本身不重分发，义务较轻；一旦改成随包 FFI 与组件包，下面这些义务才真正落到 Tune 头上。

- `THIRD_PARTY_NOTICES.md` 已列 Qwen、llama.cpp、libmpv/FFmpeg，但**没有** whisper.cpp、Whisper 权重、sherpa-onnx、SenseVoice、Paraformer 的条目。模型是运行时下载的，不等于可以不告知；至少应在设置页与 notices 里列出模型名、来源、许可证。
- [check_licenses.dart](../tool/check_licenses.dart) 只扫源码文本与 `pubspec.yaml`，**不覆盖模型文件与组件包内的权重**；建议给模型清单加一个 `license` 字段，让门禁能查到。
- [smart-lyrics.md](smart-lyrics.md) 的「Apache/MIT」表述需要在下一次改动时修正为「运行时 Apache-2.0 / 权重 FunASR 自定义协议」。

### 6.4 与 `.trae/specs/local-components` 的关系

- 那份 spec 的 registry / installer / controller 设计**与本评估不冲突**：它解决「三份安装实现」，本评估解决「运行时形态」。若 D1 选择「Android 新增 FFI」，registry 需要同时容纳 `executable`（Linux 子进程）与 `library`（Android 原生库）两种 payload；若选择「两端统一 FFI」，则 `*-runtime` 组件整体从可执行文件换成 `.so`/`.dylib`。
- spec §4.3 计划下载 `ffmpeg-4.4.1-linux-64.zip`（ffbinaries）：这是 2021 年的旧版，且常见 Linux 静态构建是 **GPL**（需核对具体构建配置）。若确认是 GPL，Tune 自托管或打进组件包会撞上 [licensing.md](licensing.md) 的红线；即使只从第三方 URL 下载，也应在 UI/notices 说明这是 GPL 程序。建议不要把它做成 Tune 托管的组件，或改用当前版本的 LGPL 动态构建。
- spec §3 的「不为 Android 增加可执行外部程序」与 D1 一致：FFI 方案不需要下载可执行文件，Android 反而因此成立。

## 7. 需要拍板的选项

| 编号 | 选项 | 建议 | 影响 |
| --- | --- | --- | --- |
| D1 | ASR/翻译的运行时形态 | **Linux 保留子进程 + Android 新增 FFI**；若追求单一代码路径，再考虑两端统一 FFI | 决定 Android 能否有本地 AI；决定是否牺牲 Linux 的崩溃隔离 |
| D2 | Android ASR 用哪个 FFI 运行时 | `sherpa_onnx`（一个包覆盖 Whisper/SenseVoice/Paraformer/Zipformer/VAD） | 少一个原生依赖 vs whisper.cpp 的极限性能 |
| D3 | 是否接受 SenseVoice 的自定义权重协议 | 接受则补署名与法务确认；不接受则第二家族换 Paraformer | 影响默认中文模型与许可证姿态 |
| D4 | 默认 ASR 档位 | Whisper small + SenseVoice int8 常开；低配 `base`；`tiny` 只作最低占用 | 影响首包体积、内存与识别质量 |
| D5 | 是否提供 `large-v3-turbo` 可选质量包 | 提供，默认不下载 | 影响质量上限与大文件下载体验 |
| D6 | 翻译默认模型 | Qwen3-0.6B 先 A/B；保留 0.5B 低配；1.5B 可选 | 影响质量、内存与组件包大小 |
| D7 | Android 解码是否现在做 MediaCodec | 现在做 | 决定 Android 上 m4a（约 16% 库）能否有本地票 |
| D8 | Linux 是否随包 FFmpeg | 不随包；若做 AppImage/Flatpak 再按 LGPL 构建 | 决定包体与 GPL/LGPL 义务 |
| D9 | 是否引入 Opus-MT 快车道 | 暂不 | 避免逐语言对模型组合与双引擎维护 |

## 8. 参考来源

- whisper.cpp（MIT、词级时间戳 `-ml 1` / `--dtw`）：https://github.com/ggml-org/whisper.cpp
- OpenAI Whisper large-v3-turbo 模型卡（MIT）：https://huggingface.co/openai/whisper-large-v3-turbo
- sherpa-onnx 文档（SenseVoice / Paraformer / Zipformer / 时间戳）：https://k2-fsa.github.io/sherpa/onnx/
- sherpa_onnx Flutter 包（Android/iOS/Linux/Windows/macOS）：https://pub.dev/packages/sherpa_onnx
- SenseVoiceSmall 模型卡（`model-license`）：https://huggingface.co/FunAudioLLM/SenseVoiceSmall
- FunASR 模型开源协议 v1.1：https://github.com/modelscope/FunASR/blob/main/MODEL_LICENSE
- Paraformer 模型页（Apache-2.0）：https://www.modelscope.cn/models/iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch
- Qwen3（Apache-2.0）：https://qwenlm.github.io/zh/blog/qwen3/
- Qwen2.5-0.5B-Instruct（Apache-2.0）：https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct
- NLLB-200 distilled 600M（CC-BY-NC-4.0）：https://huggingface.co/facebook/nllb-200-distilled-600M
- M2M-100 418M（MIT）：https://huggingface.co/facebook/m2m100_418M
- Opus-MT zh-en（CC-BY-4.0）：https://huggingface.co/Helsinki-NLP/opus-mt-zh-en
- Marian NMT（MIT）：https://marian-nmt.github.io/
- Gemma Terms of Use：https://ai.google.dev/gemma/terms
- FFmpeg 许可证与合规：https://ffmpeg.org/legal.html
- ffmpeg-kit 退役与 FFmpegKitNext（仅源码）：https://arthenica.github.io/ffmpeg-kit/
- Android W^X 与「应用数据目录不可执行」：https://chaosgoo.com/en/android-run-executable-binary-bypass/
- Android MediaCodec：https://developer.android.com/reference/android/media/MediaCodec
- Symphonia（MPL-2.0）：https://github.com/pdeljanov/Symphonia
- llama.cpp Dart FFI 绑定（示例，非官方）：https://pub.dev/packages/llama_cpp_dart
