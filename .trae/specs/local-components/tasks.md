# 实施清单

## T0 文档
- [x] `AGENTS.md` 文档地图加一行 → `docs/local-components.md`

## T1 组件层
- [x] `lib/data/services/components/local_component.dart`（模型与状态数据）
- [x] `local_component_registry.dart`（10 个组件，字节数 + sha256 钉死）
- [x] `local_component_installer.dart`（下载 → 校验 → 解压 → chmod → 原子替换 → 删除/占用）
- [x] `local_components.dart`（系统 → 旧目录 → 组件的解析）
- [x] `lib/data/services/providers/local_components_provider.dart`

## T2 状态层
- [x] `lib/features/local_components/application/local_components_controller.dart`（按 id 的状态、下载/取消/删除/刷新）
- [x] 删除 `local_model_controller.dart`、`local_model_installer.dart` 并改引用

## T3 翻译
- [x] `translation_assets.dart` 改为门面，保留 `resolve/inspect/installedSize`
- [x] `localization_providers.dart` 可用性改读组件状态
- [x] `settings_localization_local_block.dart` 复用统一状态与动作

## T4 歌词
- [x] `whisper_assets.dart` 可选注入 `LocalComponents`，系统优先
- [x] `whisper_model_store.dart` 委托统一 installer，校验值来自 registry
- [x] `smart_lyrics_controller.dart` 的 Sherpa / Whisper 资产解析走统一入口
- [x] `smart_lyrics_service.dart` 的 ffmpeg 运行时解析
- [x] `settings_smart_lyrics_local_section.dart` 去掉本地下载状态

## T5 设置页
- [x] catalog / pane / customize sheet 增加 `SettingsSection.components`
- [x] `settings_local_components_card.dart`（三组、每行状态/占用/操作、删除确认）

## T6 文案
- [x] 4 个 arb + `flutter gen-l10n`

## T7 测试
- [x] 新增 installer / resolver / controller 测试
- [x] 更新 translation_assets、whisper_assets、whisper_model_store、translation_availability、settings_smart_lyrics_card 测试
- [x] `flutter analyze`、`flutter test` 全绿（联网用例按 docs/verification.md 单独判断）

## T8 提交
- [x] 只暂存本线文件，提交 `refactor(components): 本地能力收敛为统一组件注册与安装器`，不 push

## T9 档位与合规调整
- [x] FFmpeg 作为可下载组件：`tool/build_ffmpeg.sh` 从 ffmpeg.org 源码构建 8.0.1 GPL 归档（含 `COPYING.GPLv2`、`README.tune.txt`），发布到本项目 GitHub Release；registry 钉住 6100948 字节与 sha256；系统已装仍优先
- [x] GPL 义务：`docs/licensing.md` 允许随组件分发 GPL 二进制（全文 + 源码 + 构建配置），`THIRD_PARTY_NOTICES.md` 增 FFmpeg 条目；升级时源码、configure、bytes/sha256 必须同步
- [x] 翻译模型三档：`translation-model`（Qwen3-0.6B，默认）、`translation-model-low`（Qwen2.5-0.5B）、`translation-model-quality`（Qwen2.5-1.5B）；引擎按默认 → 低配 → 高质量取第一个可用
- [x] ASR 默认改 `small`；新增 `lyrics-whisper-model-large-v3-turbo` 可选质量包，不默认下载
- [x] `docs/smart-lyrics.md` 修正 SenseVoice 许可证；`THIRD_PARTY_NOTICES.md` 补 whisper / sherpa-onnx / SenseVoice / Qwen3
- [x] 4 个 arb + `flutter gen-l10n`；`flutter analyze`、非联网 `flutter test` 全绿
- [x] 只提交本线文件，提交 `feat(components): 默认档位与 FFmpeg 合规调整`，不 push

## T10 Fun-ASR-Nano 可选第三家族（D12）
- [x] `local_component.dart` 增加 `LocalComponentLabel.funasrNanoModel`
- [x] `local_component_registry.dart` 增加 `funasrNanoModel`：id `lyrics-funasr-nano-model`，6 个文件平铺，字节数与 sha256 钉死；加入 `all` 的歌词组
- [x] `sherpa_local_engine.dart` 增加 `SherpaModelFamily`（默认 `sensevoice`），`_Target` 改为带参数列表，Fun-ASR-Nano 传 `--funasr-nano-*`
- [x] `smart_lyrics_controller.dart` 仅在组件 `usable` 时注册 `local:funasr-nano`，默认两票不变
- [x] `settings_local_components_card.dart` 歌词组追加该组件
- [x] 4 个 ARB + `flutter gen-l10n`（新键与共享 sherpa 运行时标签）
- [x] `docs/local-components.md`、`docs/smart-lyrics.md`、`THIRD_PARTY_NOTICES.md` 补家族清单/许可
- [x] `sherpa_local_engine_test.dart` 增加 Fun-ASR-Nano 参数分支测试
- [x] `flutter analyze` 与非联网 `flutter test` 全绿（联网 `music_source_e2e_live_test.dart` 外部服务失败，与本线无关）
- [x] 只提交本线文件（不碰 `docs/local-ai-evaluation.md` 与壳层改动）
