# 本地组件（本地能力插件）

> 状态：设计已定，实施中（Android 的 FFI 模型已接入，见 §1.1）
> 适用范围：翻译的本地模型、智能歌词的本地引擎、转码用的 FFmpeg

本地能力不再各自维护下载与安装状态。所有需要“下载一个可执行文件或模型”的东西，都登记成同一种**组件**，由同一份清单、同一个安装器、同一个控制器管理。

## 1. 组件模型

`LocalComponentSpec`（`lib/data/services/components/local_component.dart`）：

| 字段 | 说明 |
| --- | --- |
| `id` | 稳定标识，同时是安装目录名，如 `translation-runtime` |
| `kind` | `runtime` / `model` |
| `label` | 展示枚举，由设置页映射文案，不把中文写进数据层 |
| `files` | `fileName`、`url`、`mirrors`、`bytes`、`sha256`；模型可以是多个文件 |
| `archive` | `none` / `zip` / `tarGz` / `tarBz2` / `tarXz` |
| `executable` | 运行时解包后的相对路径，校验存在并 `chmod +x` |
| `requiredFiles` | 模型组件必须存在的文件 |
| `systemNames` | PATH（含 `~/.local/bin`、`~/bin`）里探测的可执行名 |
| `systemPaths` | 绝对路径探测，如 `~/.local/opt/sherpa-onnx/bin/sherpa-onnx-offline` |
| `platforms` | 该组件只在哪些平台出现；缺省为全平台。桌面专用二进制标 `{linux, windows}`，Android 专用模型标 `{android}` |
| `legacyFiles` / `legacyDirectories` | 旧版本写入的文件/目录，只读兼容 |

### 登记的组件

| 分组 | 组件 |
| --- | --- |
| 翻译 | `translation-runtime`（llama.cpp）、`translation-model`（Qwen3-0.6B，默认）、`translation-model-low`（Qwen2.5-0.5B，低配）、`translation-model-quality`（Qwen2.5-1.5B，可选） |
| 歌词 | `lyrics-whisper-runtime`（whisper-cli）、`lyrics-whisper-model-{tiny,base,small,large-v3-turbo}`（ggml） |
| 歌词第二票 | `lyrics-sherpa-runtime`（sherpa-onnx）、`lyrics-sensevoice-model` |
| 歌词可选第三家族 | `lyrics-funasr-nano-model`（Fun-ASR-Nano，复用上面的 sherpa-onnx 运行时） |
| 歌词（Android） | `lyrics-whisper-onnx-model`（whisper-small 的 ONNX int8 encoder/decoder/tokens，供应用内 FFI） |
| 转码 | `ffmpeg`（GPL-2.0-or-later 构建，由本项目自己发布） |

运行时与模型分开下载、分开校验、分开删除。翻译模型按默认、低配、高质量三档并列；引擎取第一个可用的档位，下载仍从默认档开始。SenseVoice 体积大且权重协议需单独确认，只在读者点击时下载，不进默认安装。

Fun-ASR-Nano 是可选的第三 ASR 家族（`docs/local-ai-evaluation.md` D12），不新增运行时：同一份 `sherpa-onnx-offline` 用 `--funasr-nano-encoder-adaptor` / `--funasr-nano-llm` / `--funasr-nano-embedding` / `--funasr-nano-tokenizer` 识别它。模型约 948 MB（int8），六个文件平铺在组件根目录；根目录同时作为 tokenizer 目录（`vocab.json`、`merges.txt`、`tokenizer.json`）。**默认不下载，也不进默认两票**：只有读者在设置页装了它，票池才会多出 `local:funasr-nano` 这一票。它的 token 时间是等间隔近似，不是真实词级对齐，长音频仍按 5 分钟分片。

### 1.1 平台作用域与 Android 的 FFI 模型

`platforms` 只决定「这个组件在哪些平台上被列出、被检查」。控制器与设置页都调
`spec.supports(platform)` 过滤，桌面列表因此保持原样：Android 不会看到 `lyrics-sherpa-runtime`
与 4 个 ggml whisper 模型，桌面也不会看到 `lyrics-whisper-onnx-model`。

Android 的运行时不是组件：`sherpa_onnx` 2.0.1 是随包的原生库，`localAsrBackend: ffi`
直接用它，不下载可执行文件。只有模型是组件：

| 组件 | 文件 | 字节 | 用途 |
| --- | --- | --- | --- |
| `lyrics-whisper-onnx-model` | `small-encoder.int8.onnx` | 112,442,483 | whisper-small ONNX encoder |
| | `small-decoder.int8.onnx` | 262,226,114 | whisper-small ONNX decoder |
| | `small-tokens.txt` | 816,730 | 词表 |

三个文件来自 `csukuangfj/sherpa-onnx-whisper-small`，安装器照常校验精确字节数与 sha256
（已与发布文件逐一核对）。这份 whisper 导出没有 cross-attention 输出，FFI 拿不到 token
时间，Android 侧按音频时长等间隔近似（见 `docs/smart-lyrics.md` M13）。

FFmpeg 由本项目自己构建并发布：`tool/build_ffmpeg.sh` 从 ffmpeg.org 源码编译 8.0.1，归档内固定带 `COPYING.GPLv2` 与写明源码地址、源码 sha256、configure 行的 `README.tune.txt`，上传到 GitHub Release 后由 app 下载。系统已装的 `ffmpeg` 仍然优先；两者都没有时跳过转码，原音频直接交给引擎。GPL 义务见 `docs/licensing.md` §1、§3。

## 2. 状态机

```
checking ──> notInstalled ──> downloading ──> verifying ──> ready
                  ^                 |                          |
                  └── 取消/失败 <────┘                          |
                  └──────────────── remove ────────────────────┘
```

- `notInstalled`：目录不存在或缺少必需文件。
- `ready`：必需文件齐全。安装时校验字节数与 sha256；日常刷新只查存在性与字节数，不每次读 500 MB。
- `failed`：下载、校验或解压失败，保留原因，可重试；暂存目录被清掉。
- `downloading`：带 `received/total`，可取消；取消后不留半成品。
- 系统已装时组件状态仍是 `notInstalled`，但取用可用；设置页标注“使用系统已安装版本”。

## 3. 存放路径与取用顺序

```
<support>/components/<id>/            组件本体（可删除）
<support>/components/.<id>.staging/   下载与解包暂存（失败即清）
<support>/translation/                旧版翻译目录（只读兼容）
<support>/whisper/                    旧版歌词目录（只读兼容）
```

取用顺序固定为 **系统 → 旧目录 → 组件**：

- 翻译：`llama-cli` 先在 PATH 找；模型先认 `TUNE_TRANSLATION_DIR`、旧 `translation/models/`，再按默认 → 低配 → 高质量找 `components/translation-model*`。
- 歌词：`whisper-cli` / `whisper-cpp` / `whisper` 先在 PATH、`~/.local/bin`、`~/bin` 找；模型先认旧 `whisper/models/`，再用组件。
- SenseVoice：`~/.local/opt/sherpa-onnx/bin` 与 `.../models/sense-voice` 优先，组件兜底。
- Fun-ASR-Nano：同一份 `~/.local/opt/sherpa-onnx/bin`；模型先认 `.../models/funasr-nano`，再用 `components/lyrics-funasr-nano-model`。
- FFmpeg：先找 PATH 与 `/usr/bin`、`/usr/local/bin`，没有再用 `components/ffmpeg`；两者都没有时保持现有行为——跳过转码，原音频直接交给引擎。

组件下载只负责“没有系统版本时也能用”，不改变已有系统的优先级。

## 4. feature 怎么取用

统一入口 `LocalComponents`：

```dart
Future<File?> executable(LocalComponentSpec spec);
Future<Directory?> directory(LocalComponentSpec spec);
Future<File?> file(LocalComponentSpec spec, String name);
Future<int> installedBytes(LocalComponentSpec spec);
```

- `TranslationAssets` 变成它的门面，保留 `resolve` / `inspect` / `installedSize` 的旧契约。
- `WhisperAssets` 可选注入 `LocalComponents`；显式传目录的旧构造（测试）行为不变。
- `SmartLyricsService` 的 ffmpeg 命令在运行时解析。
- 设置页只读 `LocalComponentsController` 的状态，不再自己 `_downloading`。

## 5. 只有一套事实来源

1. `LocalComponentRegistry`：唯一组件清单与校验常量。
2. `LocalComponentInstaller`：唯一下载 / 校验 / 解压 / 原子替换 / 删除实现。
3. `LocalComponentsController`：唯一安装状态，按 id 存 `Map<String, LocalComponentState>`。
4. 各 feature 只读状态或解析结果；不新增 ready/downloading 字段，不缓存第二份。

翻译的 `LocalModelController` 与 `local_model_installer.dart` 在本次收敛后删除。

## 6. 上游与校验

组件源固定写在 registry：GitHub Release 资产与 HuggingFace 文件都使用发布方公布的字节数与 sha256（HF LFS 的 `oid` 就是文件 sha256）。Whisper 的 `ggml-*.bin` 与 SenseVoice 的 `tokens.txt` 在实现时取一次清单并钉死，避免运行时再依赖远端清单。Fun-ASR-Nano 的六个文件取自 `csukuangfj/sherpa-onnx-funasr-nano-int8-2025-12-30`，总大小约 1,009,605,061 字节。

**下载源容错**：每个文件按 `url` → `mirrors` 的顺序逐个尝试，任一下载成功的文件都必须通过与主源完全相同的字节数与 sha256 校验才算 ready；镜像只能提高可达性，不能降低校验强度。一个源在连接、HTTP 或校验上失败就换下一个；全部源失败时只抛一个错误，里面列出试过的域名与各自原因，不无限重试。取消下载会立刻停止，不进入下一个源。Fun-ASR-Nano 的主源是 `huggingface.co`，镜像为同路径的 `hf-mirror.com`；1 GB 的模型不走 GitHub 附件。

FFmpeg 是唯一由本项目自建的组件：源码与构建配置写进 `tool/build_ffmpeg.sh`，归档上传到自己的 GitHub Release；升级版本时源码地址、configure 行、字节数与 sha256 必须同一次提交一起改。

发布前核对：

```bash
curl -sI <url>            # 字节数
sha256sum <downloaded>    # 与 registry 常量比对
```

镜像或测试环境可用 `TUNE_COMPONENT_BASE_URL` 覆盖下载基址：设置后所有文件只从 `<base>/<id>/<file name>` 取，不再尝试 registry 里的主源与镜像。

## 7. 设置页

新增「本地组件」分区，按翻译 / 歌词 / 转码三组列出每项的：名称、状态、占用、主按钮（下载 / 取消 / 删除 / 重试）。翻译卡片与歌词卡片里的本地入口复用同一份状态，不再各自下载。
