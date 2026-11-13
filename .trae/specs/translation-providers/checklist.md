# 验收清单

- [x] 默认安装包不含 `translation/`：`tool/package_linux.sh` 默认只归档 bundle，只有 `--offline` 才追加模型
- [x] `translation/manifest.json` 合法，字段与 `TranslationAssets` 一致
- [x] 厂商目录含 11 家 + 自定义 + 本地，id 唯一，OpenAI 兼容族共用 `/chat/completions`
- [x] 配置为 `backendId` + 每厂商 credential；旧 `local` / `openAiCompatible` 配置升级后 Key 与模型不丢
- [x] Key 不再写入 `localization` JSON，单独落到 `<support>/translation_keys.json`，Linux 下权限 600
- [x] OpenAI / Anthropic / Gemini 三种协议各自可用，用量字段映射正确
- [x] 余额只对 DeepSeek / Moonshot / OpenRouter / SiliconFlow 发起，其它厂商不发请求并提示未提供
- [x] 未配置厂商、缺 Key、缺模型、本地未安装时：不发请求、返回原文、设置页说明原因
- [x] 本地模型状态机 `checking → notInstalled → downloading → verifying → ready/failed` 可用，支持取消与删除
- [x] 设置页拆分完成（card / provider block / local block / ledger），无单文件超 300 行
- [x] Ollama 尝试读 `/api/tags`，失败静默退回手填建议
- [x] 旧文案键已清理，`flutter gen-l10n` 产物已更新
- [x] `flutter analyze` 为 No issues found
- [x] `flutter test` 全绿
