# 本地能力组件化（spec）

> 状态：待批准
> 设计正文：`docs/local-components.md`（组件字段、状态机、路径、取用、单一事实来源）
> 边界：不动迷你模式 / shell 并行线文件；提交只带本线文件；构建锁冲突时等并行线跑完再重试。

## 要做什么

把翻译本地模型、歌词本地引擎、FFmpeg 收敛为一套组件：一份 registry、一个 installer、一个 controller、一个设置页入口。

## 关键决定

1. **拆成 10 个组件**（运行时与模型分开下载）：
   - `translation-runtime`、`translation-model`
   - `lyrics-whisper-runtime`、`lyrics-whisper-model-{tiny,base,small}`
   - `lyrics-sherpa-runtime`、`lyrics-sensevoice-model`
   - `ffmpeg`
2. **系统优先不变**：PATH 上的 `whisper-cli` / `llama-cli` / `ffmpeg` 与 `~/.local/opt/sherpa-onnx` 先用；组件只兜底。
3. **旧目录只读兼容**：`<support>/translation/`、`<support>/whisper/` 继续被读到；删除只删 `<support>/components/<id>/`。
4. **删除两套旧状态**：`LocalModelController`、`local_model_installer.dart` 删除；`WhisperModelStore` 与 `WhisperAssets` 改为走统一解析。
5. **设置页新增「本地组件」分区**；翻译卡片与歌词卡片内的本地入口复用同一状态。

## 需要拍板

- Whisper 的 tiny / base / small 三个模型都作为独立组件列出（默认），还是只登记当前选中的那个。
  - 默认：三个都列。理由：占用与删除不随配置漂移。
- SenseVoice 运行时 373 MB + 模型 239 MB 体积较大，只在用户点击时下载，默认不提示。

## T10 Fun-ASR-Nano 可选第三 ASR 家族（D12 已接受）

> `docs/local-ai-evaluation.md` 由另一条线提交，本线只读不碰。
> 目标：可选、可下载、可删除、可投票；不默认下载，不改变默认两票（Whisper small + SenseVoice）。

1. **运行时复用**：继续用 `lyrics-sherpa-runtime`（v2.0.1）。源码 `sherpa-onnx/csrc/offline-funasr-nano-model-config.cc` 已确认参数：
   - `--funasr-nano-encoder-adaptor=<file>`
   - `--funasr-nano-llm=<file>`
   - `--funasr-nano-embedding=<file>`
   - `--funasr-nano-tokenizer=<dir>`（目录内需 `vocab.json`、`merges.txt`、`tokenizer.json`）
   - 可选 `--funasr-nano-language`、`--funasr-nano-itn`；输出含 `tokens` 与 `timestamps`，时间戳为等间隔近似，不是真实词级对齐。
2. **组件**：`LocalComponentRegistry.funasrNanoModel`，id `lyrics-funasr-nano-model`，归「歌词」组，`kind: model`。6 个文件平铺到组件根目录（installer 只支持扁平 `fileName`；根目录同时作为 tokenizer 目录）：
   | 文件 | 字节 | sha256 |
   | --- | --- | --- |
   | `embedding.int8.onnx` | 155584380 | `95e61cd0c9c3b9543339a4cf973c95c116815e745ccc1e0285cbd81f76d18644` |
   | `encoder_adaptor.int8.onnx` | 237792748 | `f36dea2e30fbc33b5db1d7a7265cc976c5e5586c77b042d5adb1ad27c72db422` |
   | `llm.int8.onnx` | 600356593 | `dfbf9aa3be41bccc257587f151e15c63fbe1b549f2b517f5ccd5bdce3bf4322a` |
   | `vocab.json` | 2776833 | `ca10d7e9fb3ed18575dd1e277a2579c16d108e32f27439684afa0e10b1440910` |
   | `tokenizer.json` | 11422654 | `aeb13307a71acd8fe81861d94ad54ab689df773318809eed3cbe794b4492dae4` |
   | `merges.txt` | 1671853 | `8831e4f1a044471340f7c0a83d7bd71306a5b867e95fd870f74d0c5308a904d5` |
   来源：`https://huggingface.co/csukuangfj/sherpa-onnx-funasr-nano-int8-2025-12-30/resolve/main/<file>`；总约 1,009,605,061 字节。系统探测路径：`~/.local/opt/sherpa-onnx/models/funasr-nano`。
3. **引擎**：`SherpaLocalEngine` 增加模型家族分支（`sensevoice` / `funAsrNano`，默认 `sensevoice` 保持旧行为）。`_Target` 从固定 `(binary, tokens, onnx)` 改为 `(binary, args)`；SenseVoice 仍传 `--tokens` + `--sense-voice-model`，Fun-ASR-Nano 传上述 4 个参数。`_run` 统一附加 `--num-threads` 与音频路径。缺少模型时软失败，错误信息按家族命名。
4. **票池**：`smart_lyrics_controller.dart` 仅在 `lyrics-funasr-nano-model` 状态 `usable`（已下载或系统可用）时注册 `SherpaLocalEngine(model: 'funasr-nano', family: funAsrNano, ...)`，频道 id `local:funasr-nano`。默认未下载 → 不注册 → 默认两票不变；读者显式下载后它作为第三票加入。
5. **设置页**：`settings_local_components_card.dart` 的「歌词」组追加该组件，走统一下载/取消/删除/重试；不默认下载。
6. **文案**：4 个 ARB 增加 `settingsLocalComponentFunasrNanoModel`；`settingsLocalComponentSherpaRuntime` 改为共享运行时表述；`flutter gen-l10n`。
7. **文档与声明**：`docs/local-components.md` 组件表、取用顺序与说明补该模型；`docs/smart-lyrics.md` M12 家族清单补「可选第三家族」；`THIRD_PARTY_NOTICES.md` 补 Fun-ASR-Nano（Apache-2.0，sherpa-onnx 转换版权重沿用同一许可）。
8. **测试**：`sherpa_local_engine_test.dart` 增加 Fun-ASR-Nano 分支——假二进制记录收到的参数，确认 4 个 `--funasr-nano-*` 与 tokenizer 目录、并仍能把 token 切成行；registry/设置页现有遍历测试自动覆盖新组件。
9. **验收**：`flutter analyze` 无问题；非联网 `flutter test` 全绿；只提交本线文件，不碰 `docs/local-ai-evaluation.md` 与壳层未提交改动。

## 落地顺序

见 `tasks.md`：组件层 → 状态层 → 翻译收敛 → 歌词收敛 → 设置页 → 文案 → 测试门禁 → 提交；T10 在其后按 registry → 引擎 → 票池 → 设置页 → 文案/文档 → 测试 → 提交执行。

## 验收

1. `flutter analyze` 无问题，`flutter test` 全绿。
2. 设置页逐项显示未安装 / 下载中（进度）/ 已安装（占用）/ 删除 / 重试。
3. 删除只清对应 `components/<id>/`；断网失败后暂存清理，可重试。
4. 系统已装 ffmpeg / whisper-cli 时，组件未装仍能转码与出词。
5. 翻译或歌词选本地时，未安装显示“未安装，可下载”，不报错。
