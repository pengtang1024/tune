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

## 落地顺序

见 `tasks.md`：组件层 → 状态层 → 翻译收敛 → 歌词收敛 → 设置页 → 文案 → 测试门禁 → 提交。

## 验收

1. `flutter analyze` 无问题，`flutter test` 全绿。
2. 设置页逐项显示未安装 / 下载中（进度）/ 已安装（占用）/ 删除 / 重试。
3. 删除只清对应 `components/<id>/`；断网失败后暂存清理，可重试。
4. 系统已装 ffmpeg / whisper-cli 时，组件未装仍能转码与出词。
5. 翻译或歌词选本地时，未安装显示“未安装，可下载”，不报错。
