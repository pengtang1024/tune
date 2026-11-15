# Android 本地 AI：sherpa_onnx FFI 后端 + MediaCodec 解码

> 依据：`docs/local-ai-evaluation.md` D1/D2/D7（已接受）、`docs/android.md` §2 E3 / §4。
> 约束：桌面行为零变化；桌面现有测试不改；实现与文档冲突以实测为准并顺手修文档。

## 0. 目标与非目标

目标：

1. Android 上新增 `sherpa_onnx` FFI 本地 ASR 后端；Linux 继续走现有 `sherpa-onnx-offline` 子进程。
2. 默认两票（whisper small、SenseVoice）与可选 Fun-ASR-Nano 在 Android 都能被票池识别；
   后端选择与能力判断只读 `AppCapabilities`，不散写 `Platform.isAndroid`。
3. Android 用系统 MediaCodec 解码/转码到 16 kHz 单声道 WAV；不随包 FFmpeg；桌面解码仍走系统 ffmpeg。
4. AVD 上真实跑通：一首歌经 MediaCodec 解码 + 本地 ASR 出词，记录耗时与失败点。

非目标：

- 不把 Linux 的子进程换成 FFI（D1 保留隔离层）。
- 不做 Android 的 llama.cpp 翻译 FFI（翻译线另排）。
- 不引入 whisper.cpp 第二 FFI 库；Android 的 whisper 走 sherpa-onnx 的 Whisper ONNX。
- 不改桌面组件列表、默认模型与解码路径。

## 1. 能力位（唯一平台判断处）

改 `lib/core/config/app_capabilities.dart`：

```dart
enum LocalAsrBackend { none, process, ffi }
```

`AppCapabilities` 新增两个字段（构造函数必填）：

| 字段 | 含义 | linux | windows | android | ios / other |
| --- | --- | --- | --- | --- | --- |
| `localAsrBackend` | 本地 ASR 怎么跑 | `process` | `none` | `ffi` | `none` |
| `nativeAudioDecoder` | 系统解码器可把音频转 16k 单声道 WAV | `false` | `false` | `true` | `false` |

- `externalToolPipeline` 语义不变（能否跑外部二进制；Linux 唯一为真），仍只决定 ffmpeg 子进程与子进程引擎。
- 其它平台分支保持现有值，不改桌面任何行为。

新增测试：`test/core/app_capabilities_test.dart`（若已存在则补齐）覆盖 5 个平台的
`localAsrBackend` / `nativeAudioDecoder`。

## 2. 组件体系（registry / installer / 组件目录）

改 `lib/data/services/components/local_component.dart`：

- `LocalComponentSpec` 新增 `final Set<AppPlatform>? platforms;`（`null` = 全平台）。
- 新增 `bool supports(AppPlatform p) => platforms == null || platforms!.contains(p);`
- `LocalComponentLabel` 新增 `whisperOnnxModelSmall`。

改 `lib/data/services/components/local_component_registry.dart`：

- 新增：

```dart
static const LocalComponentSpec whisperOnnxModelSmall = LocalComponentSpec(
  id: 'lyrics-whisper-onnx-model-small',
  kind: LocalComponentKind.model,
  label: LocalComponentLabel.whisperOnnxModelSmall,
  platforms: {AppPlatform.android},
  files: [
    // csukuangfj/sherpa-onnx-whisper-small，int8
    // small-encoder.int8.onnx  112442483
    //   sha256 4cbe7b22fa9026b843b60a68640c747de05bafb1a11b57edc0e66c232d9f33a9
    // small-decoder.int8.onnx  262226114
    //   sha256 acad50b5c782696e91b55914cc5ab4f756f1532f76e22aa6fc615f39fb69a8ee
    // small-tokens.txt           816730  sha256 落地时下载实测填入
  ],
  requiredFiles: ['small-encoder.int8.onnx', 'small-decoder.int8.onnx', 'small-tokens.txt'],
);
```

- 给纯子进程条目加 `platforms: {AppPlatform.linux, AppPlatform.windows}`：
  `whisperRuntime`、`whisperModels`（ggml 四个）、`sherpaRuntime`、`ffmpeg`。
  桌面列表与顺序不变；Android 不再列出跑不起来的二进制组件。
- `all` 追加 `whisperOnnxModelSmall`。

改 `lib/features/local_components/application/local_components_controller.dart`：
第 39 行遍历 `LocalComponentRegistry.all` 时加 `if (spec.supports(AppCapabilities.current.platform))`。

改设置页组件标题映射（`local_component` 文案所在文件）与 l10n：
新增 `whisperOnnxModelSmall` 标题，所有现有语言补齐后跑 `flutter gen-l10n`。

## 3. 后端抽象

新增 `lib/data/services/smart_lyrics/sherpa_transcriber.dart`：

```dart
abstract class SherpaTranscriber {
  Future<SherpaAnswer> listen(File wav); // 16k mono 16-bit PCM 分片
  void cancel();
  bool get cancelled;
  Future<void> dispose();
}
```

`SherpaModelFamily` 增加 `whisper`（只有 FFI 后端接受；process 后端遇到它抛
`SherpaLocalException('whisper is not a process model')`）。

新增 `sherpa_process_transcriber.dart`：把 `SherpaLocalEngine` 里现有的
`_target()` / `_senseVoiceArgs` / `_funAsrNanoArgs` / `_run` 原样搬进来，
仍用 `SherpaRunner`，行为字节级不变。

新增 `sherpa_ffi_transcriber.dart`：

- 懒加载 `sherpa_onnx.OfflineRecognizer`，按 family 构造配置：
  - `sensevoice`：`OfflineSenseVoiceModelConfig(model: model.int8.onnx, ...)` + `tokens.txt`，`modelType: 'sensevoice'`。
  - `funAsrNano`：`OfflineFunAsrNanoModelConfig(encoderAdaptor, llm, embedding, tokenizer: 目录)`，字段名以 2.0.1 包内示例为准。
  - `whisper`：`OfflineWhisperModelConfig(encoder: small-encoder.int8.onnx, decoder: small-decoder.int8.onnx,
    enableTokenTimestamps: true)` + `small-tokens.txt`，`modelType: 'whisper'`。
- 读分片 WAV 的 16-bit PCM → `Float32List`（新纯函数 `pcm16ToFloat32`，单独文件
  `sherpa_ffi_pcm.dart` 便于桌面单测）。
- `acceptWaveform` → `decode` → `getResult`；`tokens` + `timestamps` 生成
  `SherpaWord`；过滤 `<|...|>` 特殊标记与空白 token；`lang` 取 `result.lang`。
- 模型目录缺失 / 文件不全 / 运行时异常 → `SherpaLocalException`，通道软失败（健康度照旧）。
- 同一实例串行复用 recognizer；`dispose` 释放；不跨 isolate，Android 上先同步跑，
  由外层超时与取消兜底（FFI 崩溃即通道软失败，不假装成功）。

`SherpaLocalEngine` 改造（保持桌面 API）：

- 保留现有构造函数（`binaryOf` + `modelDirOf` → 内部建 `SherpaProcessTranscriber`）。
- 新增命名构造 `SherpaLocalEngine.ffi({required model, required family, required modelDirOf})`。
- 分片、WAV 校验、`linesOf` 切行、进度、取消、临时目录清理全部复用，不改。

改 `lib/features/smart_lyrics/application/smart_lyrics_controller.dart`：

```dart
final asrBackend = AppCapabilities.current.localAsrBackend;
final localEngines = asrBackend != LocalAsrBackend.none;
```

- SenseVoice：`process` → 现状；`ffi` → `SherpaLocalEngine.ffi(family: sensevoice, modelDirOf: directory(sensevoiceModel))`。
- Fun-ASR-Nano：`funasrReady` 时同上按后端二选一。
- Whisper：`process` → 现有 `WhisperLocalEngine`；`ffi` → `SherpaLocalEngine.ffi(
  family: whisper, model: local, modelDirOf: directory(whisperOnnxModelSmall))`；
  `local != 'small'` 或模型未装时该票软失败（不静默成功）。
- `ffmpegBinaryOf` 仅在 `externalToolPipeline` 为真时传（桌面不变）。

## 4. MediaCodec 解码

Dart：

- 新增 `lib/data/services/smart_lyrics/audio_decoder.dart`：

```dart
abstract class AudioDecoder {
  Future<File?> decodeToWav(File source, {required Directory folder});
}
```

- 新增 `lib/data/services/impl/media_codec_audio_decoder.dart`：`MethodChannel('cn.iouf.tune/audio_decode')`，
  `invokeMethod<bool>('decodeToWav', {'path': source.path, 'output': '$folder/decoded.wav'})`。
- `SmartLyricsService` 新增 `final AudioDecoder? nativeDecoder;`；`_decoded` 在 WAV 快路径之后、
  ffmpeg 之前插入：`nativeDecoder != null` 时解码，成功返回 `(wav, true)`；失败记一次
  `Log.error('系统解码失败: ...')` 并继续原有 ffmpeg/原样分支（不把失败当成功）。
- 控制器只在 `AppCapabilities.current.nativeAudioDecoder` 时注入，桌面为 `null`（零变化）。

原生（`android/app/src/main/java/cn/iouf/tune/`）：

- 新增 `AudioDecodeChannel.java`，`MainActivity.configureFlutterEngine` 注册。
- `decodeToWav(path, output)`：`MediaExtractor` 选音轨 → `MediaCodec.createDecoderByType`
  → 逐 buffer 喂入 → 收 PCM 16-bit → 声道平均降为单声道 → 线性插值重采样到 16 kHz
  → 写 44 字节 WAV 头 + PCM 到 `output`；不支持/解码失败返回 false。
- 支持普通文件路径；`content://` 用 `ContentResolver.openFileDescriptor` 作输入。
- 不新增任何 native 依赖，不随包 FFmpeg。

## 5. 验证

桌面门禁（不得因本次改动修改现有测试）：

```bash
env -u GDK_BACKEND /opt/flutter/bin/flutter analyze     # No issues found
env -u GDK_BACKEND /opt/flutter/bin/flutter test        # 全绿
JAVA_HOME=~/.jdks/ms-21.0.12.1 /opt/flutter/bin/flutter build apk --debug
```

新增/调整测试：

- `test/core/app_capabilities_test.dart`：5 平台能力表。
- `test/services/local_component_registry_test.dart`（若无则新建）：`supports()` 过滤、
  whisper ONNX 条目只在 Android 可见、桌面 `all` 顺序不变。
- `test/services/sherpa_ffi_pcm_test.dart`：PCM16→Float32、token 过滤与时间戳偏移。
- `integration_test/android_local_asr_test.dart`（仅设备跑）：
  1) 用 `/sdcard/Download/tune-e2e/*.m4a` 走 MediaCodec 解码到临时 WAV，断言 WAV 头为
     16 kHz / 1 ch / 16 bit 且时长 > 0；
  2) 用解码结果跑 SenseVoice FFI，断言至少一行非空文本；
  3) `Stopwatch` 记录解码与 ASR 耗时并 `print` 到测试输出。

AVD 实测步骤：

```bash
# 1) 启动 tune-api35（-no-window -no-audio swiftshader）
# 2) 模型推到应用私有组件目录（run-as 或先 push 再 cp）
#    sense-voice: model.int8.onnx + tokens.txt
#    whisper onnx: small-encoder.int8.onnx / small-decoder.int8.onnx / small-tokens.txt（视带宽）
# 3) 测试音频推 /sdcard/Download/tune-e2e/
# 4) flutter test integration_test/android_local_asr_test.dart -d emulator-5554
```

失败即如实报告（缺模型、下载失败、codec 不支持、FFI 崩溃），不得静默降级为成功。

## 6. 文档

- `docs/android.md`：新增 E5「Android 本地 ASR（FFI）与 MediaCodec 解码」，写清能力位、
  组件、实测耗时与未验项；更新 §2 E3 的「移动端的本地工具边界」不再等于「本地引擎不可用」。
- `docs/local-ai-evaluation.md`：D1/D2/D7 状态改为「Android 已落地」，附实测结论。
- `docs/local-components.md`：新增 Whisper ONNX 组件与 `platforms` 作用域说明。
- `docs/smart-lyrics.md`：M13 一行（Android FFI 后端 + MediaCodec 解码）。

## 7. 风险与决策点

| 风险 | 处理 |
| --- | --- |
| sherpa_onnx 2.0.1 的 Fun-ASR-Nano / Whisper 配置字段与示例不同 | 以包内 `example/` 为准；不支持则该家族在 Android 只保留识别不报错、票软失败，并在文档写明 |
| whisper ONNX 375 MB，AVD 下载/推送慢 | SenseVoice 必须跑通；whisper 运行时验证按带宽尽力，未跑就如实标注「未验」 |
| AVD MediaCodec 对 mp3/m4a 的软解支持 | 用系统自带软解 `c2.android.*`；失败则记录 codec 名与错误码 |
| `flutter build apk` 默认 JDK 25 不兼容 | 固定 `JAVA_HOME=~/.jdks/ms-21.0.12.1` |
| FFI 崩溃带走应用 | 先按 D1 接受；加超时与通道软失败，文档记录 |
