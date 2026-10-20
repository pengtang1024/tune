# 代码约定

> AGENTS.md 的展开文档。写代码前扫一眼这份。

## 日志

- 用 `Log.info` / `Log.error`（`lib/utils/logger.dart`），不要用 `print`（lib 下目前 0 处）。
- `Log` 只有 `debug` / `info` / `error` / `errorWithStack` 四个方法，没有 `warn`。
- 带堆栈的错误用 `Log.error(message, stackTrace)`。

## 主题与尺寸

- 间距、圆角、图标尺寸取 `CompactTokens`（`lib/app/theme/compact_tokens.dart`）。
- 颜色走 `Theme.of(context)` 或 `CompactTheme`（`lib/app/theme/compact_theme.dart`），不写裸色值与魔法数。
- 改外观先找现成 token，不要在 widget 里现编尺寸。

## 字体

- 字体的唯一入口是 `CompactTypography`（`lib/app/theme/compact_typography.dart`）：拉丁三个脸 Fraunces / Instrument Sans / JetBrains Mono 只带拉丁字形，中文靠回退家族接上。
- 中文用随包发布的思源黑体（`Noto Sans SC`）与思源宋体（`Noto Serif SC`），标题走宋体、正文走黑体；不要依赖系统装了什么字体，也不要在 widget 里写 `fontFamily`。
- 需要新样式就调 `CompactTypography.sans` / `display` / `mono` / `asDisplay`，不要在调用点直接 `TextStyle(fontFamily: ...)`。

## 常量

- 偏好键名等放 `lib/core/constants/app_preferences_constants.dart`。
- 业务常量跟所属 feature 走，不要堆进全局常量文件。

## 体积

- 新文件控制在 200 行内、方法 50 行内。
- 已超限的大文件不要再长胖，把新逻辑拆到独立文件。当前超限的：
  - `lib/features/sources/presentation/music_sources_section.dart`
  - `lib/features/settings/presentation/settings_cards.dart`
  - `lib/features/player/application/playback_controller.dart`
  - `lib/features/player/presentation/now_playing_page.dart`
  - `lib/features/search/presentation/online_search_sheet.dart`

## 注释

- 英文，写「为什么」而不是「做了什么」。
- 对外 API 必须有 doc comment；私有成员只在语义不明显时写。
- 生成代码（`lib/l10n/app_localizations*.dart`）不手工改。

## 复用

- 新增 widget 前先搜 `lib/shared/ui/`；新增服务前先搜 `lib/data/services/`。
- 同一概念只留一份实现：重复的片段提到共享文件，不要复制到各处再各改一次。

## 平台差异

- 按 `lib/data/services/impl/*_io.dart` + `*_stub.dart` 成对实现（见 `http_song_download_service_io.dart` / `_stub.dart`）。
- 或走抽象服务，如 `lib/core/services/window_manager_service.dart`。
- 不要在 widget 里写平台判断。

## 脚本与工具目录

- `tool/` 放开发脚本（`generate_linux_icons.dart`、`layout_shots_test.dart`），不放业务代码。
- **测试专用 API 只能在 `test/` 下用**：`SharedPreferences.setMockInitialValues` 这类成员在 `tool/` 里会触发 `invalid_use_of_visible_for_testing_member`。
  - 脚本要留在 `tool/`（不进常规 `flutter test`）就在调用处加 `// ignore: invalid_use_of_visible_for_testing_member` 并写明原因。
  - 脚本要进常规测试运行就挪到 `test/` 下。
- 详见 [verification.md](verification.md)。
