# 验收清单

- [x] 组件清单共 12 个（翻译 4、歌词 7、FFmpeg 1），字节数与 sha256 全部钉死在 registry
- [x] FFmpeg 由 `tool/build_ffmpeg.sh` 自建 8.0.1 GPL 静态归档并发布到本项目 Release；系统已装优先，组件兜底；registry 钉住字节数与 sha256
- [x] GPL 义务齐全：归档内 `COPYING.GPLv2` + `README.tune.txt`（源码、sha256、configure），`docs/licensing.md` 与 `THIRD_PARTY_NOTICES.md` 均可追到源码与全文
- [x] 翻译默认 Qwen3-0.6B，低配 Qwen2.5-0.5B、可选 Qwen2.5-1.5B；ASR 默认 Whisper small，large-v3-turbo 只作可选质量包
- [x] SenseVoice 保持可选、不进默认两票；`docs/smart-lyrics.md` 写明运行时 Apache-2.0、权重 FunASR 模型开源协议 v1.1
- [x] 下载后先校验字节数与 sha256，失败或缺失必需文件时不产生可用组件，暂存目录被清理
- [x] 系统已安装（PATH、`~/.local/bin`、`~/bin`、`~/.local/opt/sherpa-onnx`）优先于组件，组件只做兜底
- [x] 翻译、whisper、SenseVoice、ffmpeg 的运行时/模型解析都走同一个 `LocalComponents`
- [x] 设置页新增「本地组件」分区，逐项显示未安装 / 下载中 / 校验中 / 已安装（占用）/ 失败，并支持下载、取消、删除、重试
- [x] 不再有第二套安装状态：`LocalModelController` 与 `local_model_installer.dart` 已删除，歌词侧 `WhisperModelStore` 只委托统一 installer
- [x] 4 个 arb 的新文案与 `flutter gen-l10n` 产物同步
- [x] `flutter analyze` 无问题
- [x] 非联网测试全绿（1643 通过）；联网用例仍依赖外部服务，按 docs/verification.md 单独判断

## T10 Fun-ASR-Nano
- [x] 组件 `lyrics-funasr-nano-model` 归「歌词」组，6 个文件字节数与 sha256 全部钉死
- [x] 运行时复用 `lyrics-sherpa-runtime`，不新增运行时；参数与 sherpa-onnx v2.0.1 源码一致
- [x] 默认不下载：未安装时票池仍只有 Whisper small + SenseVoice；下载后才出现 `local:funasr-nano`
- [x] 设置页可下载、取消、删除、重试，走统一 installer
- [x] 文档与 `THIRD_PARTY_NOTICES.md` 补 Fun-ASR-Nano（Apache-2.0，时间戳为近似）
- [x] `flutter analyze` 与非联网 `flutter test` 全绿
