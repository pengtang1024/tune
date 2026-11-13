# 架构审计 R4：分层、依赖方向、状态归属与订阅粒度

## 背景与范围

在 R1–R3 的提交之上（当前 `develop` @ `510dd9f`）重新审一遍：

- 分层与依赖方向（含 `shared/ui`、`lib/providers`、presentation 里的 provider）
- 状态归属（播放/队列、搜索、设置、音乐库）
- provider 生命周期
- 订阅粒度

判据沿用 AGENTS.md §1 与 docs/architecture.md 硬约束 1–6。冻结项：页头「来源数」口径。
原则：只落地有行为证据的结构问题；不做纯搬家；每笔提交前 `flutter analyze`；收尾 `flutter analyze` + `flutter test`；不 push。

## 结论：值得改

### R4-1 消除唯一的跨 feature presentation 引用（library → search）

证据：

- `lib/features/library/presentation/library_pane.dart:38` import `features/search/presentation/online_search_sheet.dart`。
- 全仓库仅此一处跨 feature presentation 引用（`features/shell` 组合 player/queue 是文档允许的例外）。
- 用法只有一处：`library_pane.dart:228` `onSearchOnline: () => showOnlineSearchSheet(context)`。
- sheet 不共享状态：`OnlineSearchController` 是 autoDispose，数据只属于 search 自己。
- R3 判「保留」的理由是「需改 27 处测试构造」；该估算不成立——参数做成可选时，现有 25 处 `const LibraryPane()` 全部无需改动，只有真正点开 sheet 的 `test/app/localization_render_test.dart:206-236` 需要接上回调。

改法：

1. `LibraryPane` 增加可选 `VoidCallback? onSearchOnline`，删除 search import。
2. `LibraryHeader.onSearchOnline` 改为可空；为空时不渲染该按钮（按 docs/conventions.md 的口径：没有接线的入口不画）。
3. `lib/app/router/app_router.dart` 增加轻量包装页 `_LibrarySectionPage`（StatelessWidget），在自己的 `build` 里组合：

   ```dart
   LibraryPane(onSearchOnline: () => showOnlineSearchSheet(context))
   ```

   跨 feature 组合放在 `app/router`，正是硬约束 2 指定的位置。
4. `test/app/localization_render_test.dart` 的 library 用例改为挂载包装页（该用例必须点开搜索 sheet 收集文案）。
5. `docs/architecture.md` 硬约束 2 删除「现存唯一例外」那段。

验收：`flutter test test/app/localization_render_test.dart test/app/online_search_sheet_test.dart`；analyze 干净；app 内行为不变。

### R4-2 provider 归位：`whisperModelStoreProvider` 声明在 presentation

证据：

- `lib/features/settings/presentation/settings_smart_lyrics_local_section.dart:13` 声明 `FutureProvider<WhisperModelStore>`；消费方同文件 `:118` 与 `test/app/settings_smart_lyrics_card_test.dart:301`。
- 其余同类服务 provider 都在 `lib/data/services/providers/`（如 `artwork_cache_provider.dart`、`saf_method_channel_provider.dart`）。provider 是 application/服务装配物，不是 widget。

改法：新建 `lib/data/services/providers/whisper_model_store_provider.dart` 承载该 provider；删除 presentation 里的声明并改 1 处 lib import、1 处测试 import。逻辑与 override 语义不变。

### R4-3 `artworkImageProvider` 生命周期：非 autoDispose family 按 URL 无限累积

证据：

- `lib/providers/artwork_providers.dart:9`：`Provider.family<ArtworkImageProvider, String>`，键是封面 URL，未加 `autoDispose`。
- 消费方 `lib/shared/ui/artwork_thumb.dart:43` 是 `ref.watch(artworkImageProvider(imageUrl!))`，缩略图离开后即可释放。
- 与 R3 已修的两处（`songContrastProvider`、`songMarksProvider`）属同一类遗漏：每张见过的封面永久留一条缓存。

改法：改为 `Provider.autoDispose.family`。`ArtworkImageProvider` 无自身资源需要 dispose，autoDispose 只丢条目。
验收：`flutter test`（含缩略图相关用例）全绿。

## 结论：不值得改（保留）

| 项 | 证据 | 保留理由 |
| --- | --- | --- |
| `settings_pane.dart` 1507 行 | `wc -l` | 体积问题，不是本轮四个审计轴；卡片已拆到 `settings_*_card.dart`，继续拆是纯搬家。是否单独立项由用户拍板 |
| `/now-playing` 与 `/marks` 转场重复 | `app_router.dart:69-124` | 纯搬家，不影响装配正确性 |
| `appDatabaseProvider` 无 `onDispose` | `lib/data/services/providers/app_database_provider.dart` | `AppDatabase` 本身没有 `close()` API；连接与进程同生命周期，新增关闭反而可能与未 await 的写入竞争 |
| `OnlineSearchController` 同步 `valueOrNull` 读 sources | `online_search_controller.dart:38-52` | 搜索入口在初始化完成后才可用，实际触发不到；改成 await 是行为变化 |
| `PlaybackController._orderBeforeShuffle` 在 state 外 | `playback_controller.dart:111/936-967` | 不可观察的临时记录，不是第二份可变队列。playMode 已持久化而回滚顺序没有，重启后不回滚，属已知限制 |
| `settings/domain/settings_state.dart` 用 `ThemeMode` / `Locale` | 同文件 | 应用自身的 UI 配置契约，不构成对 features/app 的反向依赖；造镜像枚举只增映射 |
| `shared/ui/translated_text.dart` 读 features 的 application | `translated_text.dart:3-5` | 方向合法（presentation → application），且不是跨 feature presentation 引用；换位置会变成硬约束 2 的违规 |
| `lib/providers/` 不在文档结构图里 | `lib/providers/*.dart` | 共 40 处 import，搬迁是纯改名；改为在 `docs/architecture.md` 结构图补一行，说明它放跨 feature 的服务 provider |
| `smartLyricsWorkerServiceProvider` 非 autoDispose | `smart_lyrics_controller.dart:152` | 槽位有界，复用一个 worker 的引擎与 Dio 是设计意图 |
| `library_pane` 整份 `settingsControllerProvider` | `library_pane.dart:174` | 设置没有秒级快值；列表已用 `_cachedTracks` 挡住视口重建，窄化只省页头 |

## 需要用户拍板

1. `settings_pane.dart`（1507 行）是否本轮拆分。默认不做。
2. R4-1 采用「未给回调即不画在线搜索按钮」的语义。app 内恒有回调，用户可见行为不变；只是未接线的挂载点（测试）不再出现死按钮。

## 验收

1. 每笔提交前 `flutter analyze` = No issues found。
2. 收尾 `flutter analyze` + `flutter test` 全绿（基线 1549 个测试）。
3. 共 3 笔提交：`refactor(library)`、`refactor(settings)`、`refactor(shared)`；文档与审计结论并入对应提交或最后一笔 `docs`。
4. 不 push。
