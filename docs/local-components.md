# 本地组件（本地能力插件）

> 状态：设计（已实施） · 适用版本 1.33.0 · 最后核对 2026-11-15
>
> 实施记录：1.32.0 起，见 CHANGELOG；Android 的 FFI 模型见 §1.1
> 适用范围：翻译的本地模型、智能歌词的本地引擎、转码用的 FFmpeg

本地能力不再各自维护下载与安装状态。所有需要“下载一个可执行文件或模型”的东西，都登记成同一种**组件**，由同一份清单、同一个安装器、同一个控制器管理。

## 目录

- [1. 组件模型](#1-组件模型)
- [2. 状态机](#2-状态机)
- [3. 存放路径与取用顺序](#3-存放路径与取用顺序)
- [4. feature 怎么取用](#4-feature-怎么取用)
- [5. 只有一套事实来源](#5-只有一套事实来源)
- [6. 上游与校验](#6-上游与校验)
- [7. 设置页：功能项 → 档位 → 技术清单](#7-设置页功能项--档位--技术清单)

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
| 歌词（Android） | `lyrics-whisper-onnx-model-small`（whisper-small 的 ONNX int8 encoder/decoder/tokens，供应用内 FFI） |
| 转码 | `ffmpeg`（GPL-2.0-or-later 构建，由本项目自己发布） |
| 分享查重 | `share-fingerprint-runtime`（chromaprint 的 `fpcalc` 1.5.1，上游 release 原始产物；只登记 Linux 的 tar.gz，见下） |

运行时与模型分开下载、分开校验、分开删除。翻译模型按默认、低配、高质量三档并列；引擎取第一个可用的档位，下载仍从默认档开始。SenseVoice 体积大且权重协议需单独确认，只在读者点击时下载，不进默认安装。

Fun-ASR-Nano 是可选的第三 ASR 家族（`docs/local-ai-evaluation.md` D12），不新增运行时：同一份 `sherpa-onnx-offline` 用 `--funasr-nano-encoder-adaptor` / `--funasr-nano-llm` / `--funasr-nano-embedding` / `--funasr-nano-tokenizer` 识别它。模型约 948 MB（int8），六个文件平铺在组件根目录；根目录同时作为 tokenizer 目录（`vocab.json`、`merges.txt`、`tokenizer.json`）。**默认不下载，也不进默认两票**：只有读者在设置页装了它，票池才会多出 `local:funasr-nano` 这一票。它的 token 时间是等间隔近似，不是真实词级对齐，长音频仍按 5 分钟分片。

### 1.1 平台作用域与 Android 的 FFI 模型

`platforms` 只决定「这个组件在哪些平台上被列出、被检查」。控制器与设置页都调
`spec.supports(platform)` 过滤，桌面列表因此保持原样：Android 不会看到 `lyrics-sherpa-runtime`
与 4 个 ggml whisper 模型，桌面也不会看到 `lyrics-whisper-onnx-model-small`。

Android 的运行时不是组件：`sherpa_onnx` 2.0.1 是随包的原生库，`localAsrBackend: ffi`
直接用它，不下载可执行文件。只有模型是组件：

| 组件 | 文件 | 字节 | 用途 |
| --- | --- | --- | --- |
| `lyrics-whisper-onnx-model-small` | `small-encoder.int8.onnx` | 112,442,483 | whisper-small ONNX encoder |
| | `small-decoder.int8.onnx` | 262,226,114 | whisper-small ONNX decoder |
| | `small-tokens.txt` | 816,730 | 词表 |

三个文件来自 `csukuangfj/sherpa-onnx-whisper-small`，安装器照常校验精确字节数与 sha256
（已与发布文件逐一核对）。这份 whisper 导出没有 cross-attention 输出，FFI 拿不到 token
时间，Android 侧按音频时长等间隔近似（见 `docs/smart-lyrics.md` M13）。

FFmpeg 由本项目自己构建并发布：`tool/build_ffmpeg.sh` 从 ffmpeg.org 源码编译 8.0.1，归档内固定带 `COPYING.GPLv2` 与写明源码地址、源码 sha256、configure 行的 `README.tune.txt`，上传到 GitHub Release 后由 app 下载。系统已装的 `ffmpeg` 仍然优先；两者都没有时跳过转码，原音频直接交给引擎。GPL 义务见 `docs/licensing.md` §1、§3。

## 2. 状态机

```text
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

```text
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

## 7. 设置页：功能项 → 档位 → 技术清单

现状：按翻译 / 歌词 / 转码三组平铺 11 个组件行，每行一个按钮。读者要先懂「运行时 / 模型」，才知道该点哪一行。

### 7.1 结构（已实施）

三级，只有第一级默认可见：

1. **功能项**（3 个）：翻译、智能歌词（本地出词）、音频转码。每张卡显示：
   - 标题 + 一句话用途与代价；
   - 状态胶囊：`未安装 · 需要下载约 X` / `下载中 42%` / `校验中` / `可用 · 占用 X` /
     `部分完成 · 已完成 2/3` / `失败：原因` / `检查中`；
   - 主按钮：安装 / 取消 / 继续 / 重试 / 删除。
2. **选项**（卡片内）：
   - 档位单选（翻译 3 档、歌词 4 档），带「推荐：适合本机」标记，选中即写偏好；
   - SenseVoice 作为第二票，随歌词每一档主安装一起装，入口体积里含它的 585 MB；
   - 可选引擎只有 Fun-ASR-Nano 一行（仅 Linux），默认不装，单独下载。
3. **详细信息**（默认收起）：组件行（名称、运行时/模型、状态、占用、单组件下载/删除）+
   每个文件的名称、字节数与来源域名。

点一次主按钮 = 把该档位所需的运行时与模型按顺序装齐；系统已有的组件跳过并在状态里注明。

系统副本已经覆盖整个功能项时（目前只有音频转码会出现：PATH 或 `/usr/bin`、`/usr/local/bin`
里已有 `ffmpeg`），卡片写「使用系统已安装版本」，主按钮隐藏，下面再给一行说明与一个次级按钮
「也可以下载一份自带的（约 X）」。次级按钮走同一个 `download`（相同的下载、字节数与 sha256
校验、解压与原子替换），只是不走「已可用就跳过」的批次逻辑；系统优先的顺序不变，这只是可选
的自带副本。

### 7.2 数据模型

新文件 `local_feature.dart`（纯数据，无中文，不反向依赖 UI）：

```dart
class LocalFeatureTier {
  final String id;                 // 'standard' / 'small' …
  final LocalFeatureLabel label;   // 枚举，设置页映射文案
  final List<LocalComponentSpec> components;
  final int minRamMb;
  final int minCores;
  final int diskSlackBytes;        // 下载量之外要求的余量
}

class LocalFeatureAddon {
  final LocalFeatureAddonLabel label;
  final List<LocalComponentSpec> components;
  final Set<AppPlatform>? platforms;  // null = 所有平台
  bool supports(AppPlatform platform);
}

class LocalFeatureSpec {
  final LocalFeatureId id;         // translation / lyrics / transcode
  final LocalFeatureLabel label;
  final List<LocalFeatureTier> tiers;
  final List<LocalFeatureAddon> addons;
  bool supports(AppCapabilities capabilities);
  List<LocalFeatureTier> tiersFor(AppPlatform platform);
  Set<LocalComponentSpec> get allComponents;
}
```

`LocalComponentRegistry` 仍是唯一的组件清单，功能项只引用它的 spec，不复制字节数与 digest。

功能项与组件：

| 功能项 | 档位 | 必需组件 | 可选 |
| --- | --- | --- | --- |
| 翻译 | 轻量 / 标准（默认）/ 高质量 | `translation-runtime` + 对应 `translation-model*` | — |
| 智能歌词 | 极简 / 省空间 / 均衡（默认）/ 高质量 | `lyrics-whisper-runtime` + 对应 `lyrics-whisper-model-*` + `lyrics-sherpa-runtime` + `lyrics-sensevoice-model` | `lyrics-funasr-nano-model`（复用同一运行时） |
| 音频转码 | 无档位 | `ffmpeg` | — |
| 智能歌词（Android） | 单档 | `lyrics-whisper-onnx-model-small` | — |

平台显隐由「该平台真能跑的组件」推导，而不是只看 `platforms` 字段：Linux 三项齐全；
Windows 目前三个功能的二进制都是 linux-x64 构建，因此整卡不显示；Android 只显示智能歌词
（FFI 读 ONNX），转码的 `ffmpeg` 归档同样是 linux-x64，不显示。整个分区在没有任何可用
功能项时整体隐藏。

### 7.3 组件状态 → 功能项状态

功能项状态完全由组件状态派生，不新增第二份状态：

- `需要下载` = 必需组件里 `!usable` 的 `totalBytes` 之和（系统已装的不计）。
- `占用` = 该功能项下所有已下载组件的 `installedBytes` 之和。
- `下载中 P%` = `(已完成字节 + 当前组件 received) / (已完成字节 + 当前组件 total + 其余待装 total)`。

| 条件 | 功能项状态 | 主按钮 |
| --- | --- | --- |
| 任一必需组件 `checking` | 检查中 | 灰 |
| 任一必需组件 `downloading` / `verifying` | 下载中 P% / 校验中 | 取消 |
| 全部必需组件 `usable` | 可用 · 占用 X（全为系统副本时写「使用系统已安装版本」） | 删除（有可删副本时） |
| 部分 `usable`，其余未装或 `failed` | 部分完成 · 已完成 n/m，还差 X | 继续 |
| 无 `usable`，任一 `failed` | 失败：原因 | 重试 |
| 无 `usable`，无 `failed` | 未安装 · 需要下载约 X | 安装 |

### 7.4 批量安装、部分完成与删除

- **顺序**：共享运行时 → 档位模型 → 其余必需项；已 `usable` 的跳过。
- **进度**：每个组件仍走 `LocalComponentsController.download` 的现有进度回调；功能项读的是
  派生值，控制器不保存批次进度。
- **失败**：第一个失败即停止后面的组件，失败组件保持 `failed`，已完成组件保持 `ready`；
  功能项显示「部分完成」，主按钮变「继续」。续装只处理未 `usable` 的组件。
- **取消**：只取消当前组件的 `CancelToken`，已完成的保留，功能项回到「部分完成」。
- **删除**：功能项删除 = 删除该功能项下所有可删组件（含未选中的档位与已装的可选引擎），
  弹窗写明总占用；系统副本不动。详细信息里仍可单组件删除。
- **切换档位不自动下载、也不自动删除**：选中未装档位时主按钮变「安装此档位（约 X）」；
  旧档位继续占空间，卡片上提示可在详细信息里删除。

### 7.5 档位与偏好

| 功能项 | 存放位置 | 默认 | 迁移 |
| --- | --- | --- | --- |
| 翻译 | `LocalizationConfig.localTier`（新增，`low` / `standard` / `quality` / 空） | 空 = 自动 | 空值沿用现有「默认 → 轻量 → 高质量」的可用性顺序 |
| 歌词 | 现有 `smartLyrics.localModel` | `small` | 不变 |

引擎取用：先选显式档位（若该档位 `usable`），否则按上面的可用性顺序兜底。
安装某个档位成功时把该档位写进偏好，读者不必再选一次。

### 7.6 机器推荐

检测（`lib/data/services/system/machine_profile.dart`，接口 + 可注入探针，全部值可空）：

| 判据 | 来源 | 拿不到时 |
| --- | --- | --- |
| 可用内存 | Linux `/proc/meminfo` 的 `MemAvailable` | 未知，不参与筛选 |
| 磁盘剩余 | 对组件目录跑 `df -k`（带超时） | 未知，不参与筛选 |
| CPU 核数 | `Platform.numberOfProcessors` | 总有值 |
| 系统已装工具 | 组件状态的 `systemAvailable`（不另做探测） | `false` |
| 目标语言 | 界面语言经 `targetLanguageOf` | 界面语言总有值 |

门槛（建议值，不是硬阻断）：

| 功能项 | 档位 | 建议内存 | 建议核数 | 下载 | 额外磁盘余量 |
| --- | --- | --- | --- | --- | --- |
| 翻译 | 轻量 | 1.5 GB | 2 | 470 MB | 500 MB |
| 翻译 | 标准 | 2.5 GB | 4 | 610 MB | 500 MB |
| 翻译 | 高质量 | 5 GB | 6 | 1.1 GB | 1 GB |
| 歌词 | 极简 | 1.5 GB | 2 | 75 MB | 500 MB |
| 歌词 | 省空间 | 2 GB | 2 | 145 MB | 500 MB |
| 歌词 | 均衡 | 3 GB | 4 | 475 MB | 500 MB |
| 歌词 | 高质量 | 8 GB | 8 | 1.6 GB | 1 GB |
| 歌词 | 第二引擎 | 3 GB | 4 | 585 MB | 500 MB |
| 歌词 | 第三引擎 | 8 GB | 8 | 960 MB | 1 GB |
| 转码 | — | — | — | 6 MB | 100 MB |

翻译档位口径：本表「轻量 / 标准 / 高质量」对应注册表的「低配 / 默认 / 高质量」
（`translation-model-low` / `translation-model` / `translation-model-quality`）；
「标准」即默认档，默认档是 Qwen3-0.6B（约 610 MB），下载从默认档开始。

选择顺序（纯函数，可单测）：

1. 可推荐集合 = 内存、核数、磁盘都达标的档位；未知值不参与过滤。
2. 分档：弱机（核 ≤ 2 或内存 < 3 GB）取最低档；强机（核 ≥ 8 且内存 ≥ 8 GB）取最高档——
   翻译在目标语言是中文 / 英文时封顶到「标准」，只有其它语言才推荐「高质量」；其余取中间档。
3. 集合为空 → 取最小档，标记「空间或内存可能不足」，仍允许安装；不显示任何机器规格数字。
4. 内存与磁盘都未知 → 中间档，标记 `certain = false`，文案改为「默认：适合多数电脑」。
5. 系统已装优先：转码检测到系统 `ffmpeg` 时不推荐下载，状态直接「使用系统已安装版本」；
   歌词检测到系统 `whisper` 时安装集去掉运行时；翻译检测到系统 `llama-cli` 时同理。

推荐结果只影响默认选中与「推荐」标记，不改写组件的真实状态；用户选择后以用户为准。

### 7.7 文案

所有文案走 `lib/l10n/app_{zh,zh_CN,zh_TW,en}.arb` 后再 `flutter gen-l10n`，数据层只出现枚举。

功能项：

| 功能项 | 标题 | 说明 |
| --- | --- | --- |
| 翻译 | 翻译 | 不用联网就能把歌曲信息、简介和界面里的外文翻成你的语言。占空间，速度比云端慢。 |
| 智能歌词 | 智能歌词（本地出词） | 听歌时自动听写歌词，不联网、不上传。一首歌要等一会儿，档位越大越准也越慢。 |
| 音频转码 | 音频转码 | 只有遇到播不了的格式才用得上：先把音频转成能播放的格式。平时不占资源。 |

档位：

| 功能项 | 档位 | 说明 |
| --- | --- | --- |
| 翻译 | 轻量 | 最省内存、最快；长句和术语可能翻得生硬。 |
| 翻译 | 标准 | 默认；歌曲信息和简介够用，速度与质量平衡。 |
| 翻译 | 高质量 | 长句、罕见语言更准；慢 2–3 倍，占用也大。 |
| 歌词 | 极简 | 最快、最省；清晰人声够用，嘈杂录音容易漏词。 |
| 歌词 | 省空间 | 比极简准一些，占用仍然很小。 |
| 歌词 | 均衡 | 默认；多数歌曲够用，速度与准确率平衡。 |
| 歌词 | 高质量 | 最准；老录音、现场版明显更好，但慢很多。 |

可选引擎：Fun-ASR-Nano「中文歌曲的第三路识别；更慢、更占空间，只有装了它才参与」。

状态与操作：安装、取消、继续、重试、删除、详细信息、校验中、部分完成、失败原因、
「推荐：适合本机」、「默认：适合多数电脑」、「使用系统已安装的 X」、
「空间可能不够，需至少 X」。

### 7.8 测试

- 推荐纯函数：内存充足（强机 / 翻译中文封顶标准）、内存不足（弱机取最低档）、
  磁盘不足（集合为空 → 最小档 + 提示）、系统已装工具（转码不推荐下载、歌词去掉运行时）、
  检测值全缺失（中间档 + `certain = false`、无数字）、非中英目标语言（强机推荐高质量）。
- 功能项状态派生：未安装 / 下载中聚合 / 部分完成 / 失败 / 全系统副本可用。
- 批量安装：顺序、跳过 `usable`、中途失败保留已完成、续装只补缺口、取消不回滚。
- 设置页 widget 测试：只显示功能项卡；展开后出现技术清单；推荐标记与默认选中一致；
  技术清单不出现别的平台的组件。
- 平台显隐：Linux 三项、Android 只有歌词、Windows 连分区都不出现；Fun-ASR-Nano 只在 Linux 出现。

### 7.9 已确认的决定

1. SenseVoice（585 MB）随歌词每一档主安装一起装，因为它就是默认的两票之一；入口下载量如实包含它。
2. 删除功能项时连未选中的档位一起删，弹窗写明总占用；系统自带副本不动。
3. 跨平台按实际能力显示：Linux 三项齐全，Android 只有歌词，Windows 等装不了的平台连分区都不出现。

### 为什么 `fpcalc` 只登记 Linux

一条 `LocalComponentSpec` 只有一个 `archive` 和一份 `files`——`platforms` 只决定「哪些系统
看得到」，并不按系统挑产物。chromaprint 的 Linux 是 tar.gz、Windows 是 zip、macOS 又是
tar.gz，塞进同一份规格要么把 zip 当 tar.gz 解，要么给规格加一层「按平台的文件」，两条都
不是本轮该动的结构。所以这里只登记验证过的 Linux 产物；Windows/macOS 上查重退回到
`AcoustIdLookup.findFpcalc()` 的 PATH 探测（`~/.local/bin`、`~/bin`、系统 PATH），
找不到就是「没查」，闸门不会把它当清白证明。

## 相关文档

- [settings-redesign.md](settings-redesign.md) — 设置页的分区导航与入口
- [smart-lyrics.md](smart-lyrics.md) — 歌词引擎怎么用这些组件
- [licensing.md](licensing.md) — 随包与下载模型的许可证边界
- [troubleshooting.md](troubleshooting.md) — 下载或校验失败时的现象与处理
- [architecture.md](architecture.md) — 组件注册与状态归属
