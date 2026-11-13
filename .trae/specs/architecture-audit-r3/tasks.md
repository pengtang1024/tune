# 任务清单：架构审计 R3

- [x] T1 provider 生命周期：`songContrastProvider` 与 `songMarksProvider` 改为 `autoDispose.family`
  - 文件：`lib/features/smart_lyrics/application/smart_lyrics_contrast_controller.dart`、`lib/features/smart_lyrics/application/smart_lyrics_marks_controller.dart`
  - 验证：`flutter analyze`；`flutter test test/app/smart_lyrics_contrast_controller_test.dart test/app/lyrics_panel_test.dart`
  - 提交：`refactor(smart_lyrics): 按需释放单曲对照与标记缓存`

- [x] T2 服务边界：设置页不再直接 import SAF 平台实现
  - 新增：`lib/data/services/providers/saf_method_channel_provider.dart`
  - 修改：`lib/features/settings/presentation/settings_pane.dart`（去掉 `impl` import，改走 provider）
  - 验证：`flutter analyze`
  - 提交：`refactor(settings): SAF 目录选择改走 provider`

- [x] T3 收尾验证
  - `flutter analyze`
  - `flutter test`
  - 确认工作区只含预期改动，不 push

## 明确不做

- 不动页头来源数口径。
- 不消除 `library_pane` → `online_search_sheet` 的历史例外。
- 不做 `app_router` 转场抽取、`settings_pane` 拆分等纯搬家。
