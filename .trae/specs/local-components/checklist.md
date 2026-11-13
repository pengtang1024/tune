# 验收清单

- [x] 组件清单共 10 个（翻译 2、歌词 5、SenseVoice 2、FFmpeg 1），字节数与 sha256 全部钉死在 registry
- [x] 下载后先校验字节数与 sha256，失败或缺失必需文件时不产生可用组件，暂存目录被清理
- [x] 系统已安装（PATH、`~/.local/bin`、`~/bin`、`~/.local/opt/sherpa-onnx`）优先于组件，组件只做兜底
- [x] 翻译、whisper、SenseVoice、ffmpeg 的运行时/模型解析都走同一个 `LocalComponents`
- [x] 设置页新增「本地组件」分区，逐项显示未安装 / 下载中 / 校验中 / 已安装（占用）/ 失败，并支持下载、取消、删除、重试
- [x] 不再有第二套安装状态：`LocalModelController` 与 `local_model_installer.dart` 已删除，歌词侧 `WhisperModelStore` 只委托统一 installer
- [x] 4 个 arb 的新文案与 `flutter gen-l10n` 产物同步
- [x] `flutter analyze` 无问题
- [x] 非联网测试全绿（1643 通过）；联网用例仍依赖外部服务，按 docs/verification.md 单独判断
