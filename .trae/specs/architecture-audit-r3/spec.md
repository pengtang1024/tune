# 架构审计 R3：player/queue、在线搜索、app 装配、服务边界、provider 生命周期

## 背景与目标

延续前两轮架构审计，本轮只读核查五个区域，先裁决「值得改 / 不值得改」，再只落地值得改的部分。硬约束：

- 不改变任何用户可见行为（页头来源数口径按用户要求继续冻结）。
- 不做纯搬家式重构；每一笔提交只解决一个主题。
- 每笔提交前 `flutter analyze` 通过；收尾跑全量 `flutter analyze` 与 `flutter test`。
- 不 push。

## 审计结论：值得改

### R3-1 provider 生命周期：两个 family 缓存无上限

证据：

- `lib/features/smart_lyrics/application/smart_lyrics_contrast_controller.dart:49`：`songContrastProvider` 是 `FutureProvider.family<SmartSongContrast, Song>`，未加 `autoDispose`，键是**整首 `Song`**。每打开一首歌就在容器里永久留一条 Future 缓存；`Song` 实例变化还会产生新键。
- 同一文件 `:16-43`：`smartLyricsAssistProvider` 是常驻 `Provider`，内部新建 `Dio` 并 `ref.onDispose(dio.close)`。只要任一非 autoDispose 的 contrast 条目还在，assist provider 就一直被订阅，旧 `Dio` 无法随配置变化释放。
- `lib/features/smart_lyrics/application/smart_lyrics_marks_controller.dart:14`：`songMarksProvider` 是 `FutureProvider.family<SmartLyricsSongFlags, int>`，同样按 songId 永久缓存。

对照：仓库里同类按需读取已经是既有模式（`translatedTextProvider`、`libraryFacetsProvider` 都是 autoDispose），这两个属于遗漏。

改法：两处改为 `.autoDispose.family`。消费者都是 `ref.watch`（`lyrics_panel.dart:99/102/465`），面板离开后释放缓存是期望行为；`invalidate` 调用无需改动。

风险：`container.read(provider.future)` 的测试（`test/app/smart_lyrics_contrast_controller_test.dart:118`）需要验证 autoDispose 下 future 仍能完成；以 `flutter test` 结果为准。

### R3-2 服务接口边界：设置页 presentation 直接 import 平台实现

证据：

- `lib/features/settings/presentation/settings_pane.dart:13` import `package:tune/data/services/impl/saf_method_channel.dart`。
- 同文件 `:1344` 直接 `await const SafMethodChannel().pickDirectory()`。

违反 `docs/architecture.md` 硬约束 1（`impl` 只能在组合根/数据层被引用）与约束 4（widget 不直接持有 service）。页面只应通过 provider 触发动作。

改法：新增 `lib/data/services/providers/saf_method_channel_provider.dart`，暴露 `Provider<SafMethodChannel>`；设置页改为 `ref.read(safMethodChannelProvider).pickDirectory()`。不改动 `SafMethodChannel` 本身，也不改动桌面端 `FilePicker` 路径。

## 审计结论：不值得改（保留）

| 项 | 证据 | 保留理由 |
| --- | --- | --- |
| 队列状态归属 | `playback_state.dart:22-28` 队列与游标都在 `PlaybackState`；`features/queue` 只有 presentation，无 controller/domain | 单一事实来源成立，没有第二个队列容器 |
| 播放快/慢订阅 | `playback_overview_provider.dart:21-38` 用 `select` 取慢字段，record 结构化相等会抑制位置 tick | 已符合 AGENTS §1.3 |
| shuffle 前的顺序 | `playback_controller.dart` 私有 `_orderBeforeShuffle` | 不可观察的临时记录，不是第二份可变队列；放进 state 只会扩大播放器的公开面 |
| 队列侧栏显隐 | `compact_shell.dart` 与 `now_playing_page.dart` 各自本地 state | 纯呈现状态，文档已明确不进 provider |
| 在线搜索的跨 feature 依赖 | `online_search_controller.dart:38-52` 同步 `valueOrNull` 读 sources，加载中会显示「没有启用音源」 | 搜索入口在应用初始化完成后才可用，实际触发不到；改成等待加载属于行为变化，不在本轮 |
| 搜索结果不跨会话保留 | `online_search_controller.dart:12-15` 是 autoDispose | 结果是临时数据，关闭即丢弃是产品口径 |
| `library_pane` → `online_search_sheet` | `library_pane.dart:38` | 唯一的跨 feature presentation 引用，但它是单向「打开一个 sheet」，无状态共享；消除需给 `LibraryPane` 加回调参数并改 27 处测试构造，收益只是让文档上的例外消失，属于整容式改动 |
| `/now-playing` 与 `/marks` 的转场重复 | `app_router.dart:69-124` | 两段各约 20 行，抽 `overlayPage` 是纯搬家；不影响装配正确性 |
| 路由白名单 | `app_router.dart:19-33` | 显式列出可达页面，新增页面需同时加路由与白名单；这是有意的收口，不是重复 |
| `appDatabaseProvider` 未 `onDispose(close)` | `lib/data/services/providers/app_database_provider.dart` | 连接与进程同生命周期；容器只在进程退出/启动失败时销毁，此时关闭连接没有安全窗口，反而会在测试收尾与未 await 的写入竞争 |
| `settings_pane.dart` 体量 | 约 1400 行 | 属于拆分诉求，不是本轮五个审计区域；按用户要求不做纯搬家 |
| `settings/domain/settings_state.dart` 使用 Flutter 值类型 | `ThemeMode` / `Locale` | 是应用自身的 UI 配置契约，不构成对 features/app 的反向依赖；为它造镜像枚举只会增加映射 |

## 验收

1. `flutter analyze`：No issues found（每笔提交前一次，收尾一次）。
2. `flutter test`：全绿。
3. 用户可见行为不变；页头来源数、搜索/排序/筛选行为与现有测试期望均不动。
4. 共 2 笔提交：`refactor(smart_lyrics)` 与 `refactor(settings)`；不 push。
