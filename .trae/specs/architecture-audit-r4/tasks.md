# 任务清单：架构审计 R4

- [x] T1 消除 library → search 的 presentation 依赖
  - `lib/features/library/presentation/library_pane.dart`：加可选 `VoidCallback? onSearchOnline`，删 search import，改调用点
  - `lib/features/library/presentation/library_header.dart`：`onSearchOnline` 可空，为空不画按钮
  - `lib/app/router/app_router.dart`：新增 `_LibrarySectionPage`，组合 `LibraryPane` 与 `showOnlineSearchSheet`
  - `test/app/localization_render_test.dart`：library 用例改挂包装页
  - `docs/architecture.md`：硬约束 2 删例外段
  - 验证：`flutter analyze` 干净；`flutter test test/app/localization_render_test.dart test/app/online_search_sheet_test.dart` 通过
  - 提交：`refactor(library): 在线搜索入口改由路由装配`

- [x] T2 provider 归位
  - 新建 `lib/data/services/providers/whisper_model_store_provider.dart`
  - 改 `lib/features/settings/presentation/settings_smart_lyrics_local_section.dart`（删声明、换 import）
  - 改 `test/app/settings_smart_lyrics_card_test.dart` 的 import
  - 验证：`flutter analyze` 干净；`flutter test test/app/settings_smart_lyrics_card_test.dart` 通过
  - 提交：`refactor(settings): 本地模型 provider 移出 presentation`

- [x] T3 artwork provider 生命周期
  - `lib/providers/artwork_providers.dart`：`Provider.autoDispose.family`
  - 验证：`flutter analyze` 干净；`flutter test test/app/artwork_thumb_test.dart test/app/now_playing_phone_test.dart` 通过
  - 提交：`refactor(shared): 封面 provider 按需释放`

- [x] T4 文档同步 + 收尾
  - `docs/architecture.md` 结构图补 `data/services/providers/` 与 `providers/`
  - `.trae/specs/architecture-audit-r4/`
  - `flutter analyze` = No issues found；`flutter test` = 1549 个测试全绿
  - 提交：`docs(architecture): 记录第四轮架构审计结论`
  - 不 push

## 结果

- 跨 feature presentation 引用：0 处（`features/shell` 组合 player/queue 仍是文档允许的例外）。
- 未改动：页头来源数口径、`settings_pane.dart` 拆分、`app_router` 转场抽取、`appDatabaseProvider` 关闭、搜索的同步 sources 读取、shuffle 前顺序的持久化。
