# Tasks — Android 本地 AI（FFI + MediaCodec）

按顺序执行；每步完成即更新 todo 状态。

## T1 能力位
- [x] `app_capabilities.dart`：新增 `LocalAsrBackend`、`localAsrBackend`、`nativeAudioDecoder`，5 平台赋值。
- [x] 新增/补齐 `test/core/app_capabilities_test.dart`。

## T2 组件体系
- [x] `local_component.dart`：`platforms` + `supports()` + 新 label。
- [x] `local_component_registry.dart`：`whisperOnnxModelSmall`（sha256 全部实测）与 process-only 条目作用域。
- [x] `local_components_controller.dart`：按平台过滤。
- [x] 设置页标题映射 + `flutter gen-l10n` 全语言文案。
- [x] `test/services/local_component_registry_test.dart`。

## T3 后端抽象
- [x] 新增 `sherpa_transcriber.dart`、`sherpa_process_transcriber.dart`、`sherpa_ffi_transcriber.dart`、`sherpa_ffi_pcm.dart`。
- [x] `SherpaLocalEngine` 改为可注入 transcriber，新增 `.ffi` 构造；桌面路径行为不变。
- [x] `sherpa_ffi_pcm_test.dart`。

## T4 控制器接线
- [x] `smart_lyrics_controller.dart` 按 `localAsrBackend` 选后端；whisper 在 Android 用 ONNX 组件。
- [x] 桌面默认两票与现有测试零变化（跑 `flutter test` 确认）。

## T5 MediaCodec
- [x] Dart `audio_decoder.dart` + `media_codec_audio_decoder.dart`。
- [x] `SmartLyricsService` 注入 `nativeDecoder` 并接进 `_decoded`。
- [x] `MainActivity` 注册 `AudioDecodeChannel`；实现 decodeToWav。
- [x] `flutter build apk --debug` 通过。

## T6 门禁
- [x] `flutter analyze` 干净。
- [x] `flutter test` 全绿（含新增）。
- [x] `flutter build apk --debug` 成功。

## T7 AVD 实测
- [x] 启动 `tune-api35`，推 SenseVoice 模型与测试音频。
- [x] 跑 `integration_test/android_local_asr_test.dart`：解码 + ASR 出词，记录耗时。
- [x] whisper ONNX 实测：三个文件下载后 sha256 与 registry 完全一致；AVD 出词 4,022 ms。
  该导出无 cross-attention，token 时间恒为空，已改为「等间隔近似」并写进文档（不冒充真实对齐）。
- [x] 收集中途可运行后端时先报一次（不重复报同一里程碑）。
- [x] 核对 `yue` 语言标签：桌面 CLI 同模型同音频同样返回 `<|yue|>`，属模型输出；
  我们的代码原样透传，且该字段无消费方，不改。

## T8 文档与提交
- [x] `docs/android.md` E5、`docs/local-ai-evaluation.md`、`docs/local-components.md`、`docs/smart-lyrics.md`。
- [x] 分阶段提交（不 push），提交信息按仓库规范：`a845b8a`（能力位 + FFI + MediaCodec）、
  `3bc6330`（AVD 集成测试）、`42d0b5f`（文档）。
