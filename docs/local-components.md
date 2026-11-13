# 本地组件（本地能力插件）

> 状态：设计已定，实施中
> 适用范围：翻译的本地模型、智能歌词的本地引擎、转码用的 FFmpeg

本地能力不再各自维护下载与安装状态。所有需要“下载一个可执行文件或模型”的东西，都登记成同一种**组件**，由同一份清单、同一个安装器、同一个控制器管理。

## 1. 组件模型

`LocalComponentSpec`（`lib/data/services/components/local_component.dart`）：

| 字段 | 说明 |
| --- | --- |
| `id` | 稳定标识，同时是安装目录名，如 `translation-runtime` |
| `kind` | `runtime` / `model` |
| `label` | 展示枚举，由设置页映射文案，不把中文写进数据层 |
| `files` | `fileName`、`url`、`bytes`、`sha256`；模型可以是多个文件 |
| `archive` | `none` / `zip` / `tarGz` / `tarBz2` / `tarXz` |
| `executable` | 运行时解包后的相对路径，校验存在并 `chmod +x` |
| `requiredFiles` | 模型组件必须存在的文件 |
| `systemNames` | PATH（含 `~/.local/bin`、`~/bin`）里探测的可执行名 |
| `systemPaths` | 绝对路径探测，如 `~/.local/opt/sherpa-onnx/bin/sherpa-onnx-offline` |
| `legacyFiles` / `legacyDirectories` | 旧版本写入的文件/目录，只读兼容 |

### 登记的组件

| 分组 | 组件 |
| --- | --- |
| 翻译 | `translation-runtime`（llama.cpp）、`translation-model`（gguf） |
| 歌词 | `lyrics-whisper-runtime`（whisper-cli）、`lyrics-whisper-model-{tiny,base,small}`（ggml） |
| 歌词第二票 | `lyrics-sherpa-runtime`（sherpa-onnx）、`lyrics-sensevoice-model` |
| 转码 | `ffmpeg` |

运行时与模型分开下载、分开校验、分开删除。

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

- 翻译：`llama-cli` 先在 PATH 找；模型先认 `TUNE_TRANSLATION_DIR`、旧 `translation/models/`，最后才是 `components/translation-model`。
- 歌词：`whisper-cli` / `whisper-cpp` / `whisper` 先在 PATH、`~/.local/bin`、`~/bin` 找；模型先认旧 `whisper/models/`，再用组件。
- SenseVoice：`~/.local/opt/sherpa-onnx/bin` 与 `.../models/sense-voice` 优先，组件兜底。
- FFmpeg：PATH 优先，组件兜底；两者都没有时保持现有行为——跳过转码，原音频直接交给引擎。

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

组件源固定写在 registry：GitHub Release 资产与 HuggingFace 文件都使用发布方公布的字节数与 sha256。Whisper 的 `ggml-*.bin` 与 SenseVoice 的 `tokens.txt` 在实现时取一次清单并钉死，避免运行时再依赖远端清单。

发布前核对：

```bash
curl -sI <url>            # 字节数
sha256sum <downloaded>    # 与 registry 常量比对
```

镜像或测试环境可用 `TUNE_COMPONENT_BASE_URL` 覆盖下载基址；组件本身已是绝对 URL 时不覆盖。

## 7. 设置页

新增「本地组件」分区，按翻译 / 歌词 / 转码三组列出每项的：名称、状态、占用、主按钮（下载 / 取消 / 删除 / 重试）。翻译卡片与歌词卡片里的本地入口复用同一份状态，不再各自下载。
