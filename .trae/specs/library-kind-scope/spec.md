# 音乐库：内容类型成为默认作用域，专辑成为可见入口

> 依据：用户 2026-11-15 反馈「还是在被电台和播客之类的污染，还有 专辑的体现呢」，截图
> `1a3549b9-…_image.png`（实为 BMP，已转 `/tmp/tune_pollution.png`），并跑的是 1.32.0（新代码已生效）。
> 前置：`library-browse-kinds` / `library-content-kinds` 已全部实施并推送；工作区干净（HEAD `74d0711` 之后）。

## 结论先行

- **分类器没有错**。截图里的 `CC627…CC637` 全部来自 `archive_podcasts`（声明播客），带语音徽标，
  行上 `Case Closed!` / `RelicRadio.com` 是单集的作者与节目名。真正的问题在**视图**：
  默认「歌曲」视图不做任何内容类型分流，`filter.kinds` 默认空 = 全部。
- **默认作用域固定为音乐**：`LibraryFilter.kinds` 永不为空，空值在 `setFilter` 入口规范化为 `{music}`。
  用户不需要勾选任何东西，打开音乐库就是歌。
- **语音有明确去处**：页头「电台」按钮升级为「内容」菜单（音乐 / 播客 / 有声书 / 电台，单选、
  当前项打勾），一项点击直达；专辑墙分节与分类视图「类型」保留为第二条路。
- **专辑有三处可见**：页头「专辑」按钮（已存在计数）、歌曲视图专辑列可点开专辑页、
  专辑墙分节保留；默认视图仍是歌曲（列表是本产品的密度特征），不改成专辑优先。

## 截图现象（已核实的观感来源）

| 位置 | 截图里的事实 | 结论 |
| --- | --- | --- |
| 页头 | `5,106 首歌曲 · 984 张专辑 · 15 个来源` + 「电台」按钮 | 计数是全库总数，语音与电台都被算作「歌曲」 |
| 筛选 chip | `电台 ×` `音乐 ×` `播客 ×`，工具条「筛选 1」 | 用户为了自救勾了三种类型，结果三种混排；默认没有「只看音乐」 |
| 列表行 | `CC627…` / `Case Closed!` / `RelicRadio.com` / 语音图标 | 分类为 podcast（正确），视图没有排除 |
| 列头 | 标题 / 艺术家 / 专辑 / 加入 / 时长 | 专辑只是纯文本列，不可点，没有封面/集数 |
| 视图切换 | 4 个无文字图标，默认第 1 个 | 专辑墙在第 4 个图标后面，发现成本极高 |

## 数据库证据（用户本机，只读查询）

| 项 | 值 |
| --- | --- |
| 活动曲目 | 5,106 |
| 直播（`isLiveStream=1`，`radio` 源） | 152 |
| 播客（`archive_podcasts` 329 + `podcast_rss` 101 + 其余 59） | 489 |
| 有声书（`librivox` 496 + `independent_audiobooks` 240） | 736 |
| 电台录音（`old_time_radio` 480 + `radio_recordings` 66） | 546 |
| 音乐 | 3,183 |

即约 **1,923 条（37.6%）非音乐内容** 默认混在「歌曲」里。未声明、按规则归音乐的实例还有
`news_recordings` 182、`unlocked_recordings` 103、`poetry_books` 37、`poetry` 8、`science_talks` 8。

## 问题清单

| # | 问题 | 位置 | 根因 |
| --- | --- | --- | --- |
| P1 | 默认歌曲视图不按内容类型过滤 | `library_pane.dart:202`、`library_state.dart:128` | `kinds` 默认空 = 全部；`filteredSongsOf` 只处理 query/source |
| P2 | 空 `kinds` 可被任何「清除筛选」路径重新产生 | `library_controller.dart:531`、`library_filter_panel.dart:311`、`library_filter_chips.dart:137`、`library_pane.dart:432,753` | 所有路径都写 `LibraryFilter.empty` |
| P3 | 页头与工具条计数把语音算作歌曲 | `library_pane.dart:232`、`library_toolbar.dart:118` | 摘要用 `total`，单位固定「首歌曲」 |
| P4 | 播客 / 有声书没有常驻入口；电台只有一个按钮 | `library_header.dart` | 类型只存在于筛选面板、分类视图「类型」与专辑墙分节 |
| P5 | 专辑不可点、入口无文字 | `library_track_card.dart:176`、`library_view_switch.dart` | 专辑列是纯文本；专辑墙在第 4 个无标签图标 |
| P6 | 「歌曲」视图里 `hasRadio` 用当前窗口判断 | `library_pane.dart:216` | 作用域改成音乐后窗口内没有电台，按钮会消失 |

## 方案

### D1 默认作用域 = 音乐，且 `kinds` 永不为空

- `lib/domain/models/library_filter.dart`：新增
  `static const LibraryFilter songs = LibraryFilter(kinds: {ContentKind.music});`
  与 `LibraryFilter withoutGroups() => LibraryFilter(kinds: kinds);`（清除全部时保留作用域）。
- `LibraryController.setFilter`：**唯一规范化点**
  ```dart
  final next = filter.kinds.isEmpty
      ? filter.copyWith(kinds: const {ContentKind.music})
      : filter;
  ```
  所有「清除全部 / 移除最后一个类型 chip / 树里点全部歌曲」自动落回音乐，不平铺全部内容。
- `build`：加载 `view.json` 后同样规范化一次（已有 `kinds` 的旧视图保持用户选择），并把规范化后的
  过滤条件回写，避免每次启动重复判断。
- `LibraryPane` 里所有 `setFilter(LibraryFilter.empty)` 改为 `LibraryFilter.empty`（会被规范化）
  或显式 `LibraryFilter.songs`；语义上不新增第二份状态。

### D2 页头「内容」菜单（替换「电台」按钮）

- `LibraryHeader` 删除 `radioActive` / `onRadio`，改为：
  - `final ContentKind? selectedKind;`（单一类型时非空，多选/无选为空）
  - `final ValueChanged<ContentKind> onKind;`
  - `final bool showKindMenu;`
- 渲染 `PopupMenuButton<ContentKind>`（`key: library-content-kind`）：
  - 按钮文案 = 当前类型名（`contentKindMusic/Podcast/Audiobook/Radio`），非单一类型时用
    `libraryFilterKinds`（类型）；图标沿用 `radio/podcasts/record_voice_over/music_note`。
  - 菜单四项：音乐 / 播客 / 有声书 / 电台，当前项 `checked: true`。
  - 点击 → `_selectKind(kind)`：`setFilter(filter.copyWith(kinds: {kind}))`，并切回歌曲视图。
- 显示条件：`showKindMenu = library.otherKindCount > 0`。这个计数在 controller 里用一次
  `countQuery(filter: kinds={podcast,audiobook,radio})` 取得，跟 `total` 同批刷新；不再用当前窗口
  判断（修 P6）。
- `LibraryState` 新增 `final int otherKindCount;` 与 `final int matching;`（作用域内命中数），
  `copyWith` 同步。

### D3 专辑入口与可点列

- **页头**：`LibraryHeader` 新增 `onAlbums` / `albumsActive`，按钮 `key: library-albums`，
  图标 `grid_view_rounded`，文案 `libraryViewAlbums`（已存在）；`albumsActive` 时主色 + 浅底，
  与内容菜单同一套样式。点击 `_setView(LibraryViewMode.albums)`。专辑数为 0 时不显示。
- **歌曲视图专辑列可点**：`LibraryTrackCard` 新增 `final ValueChanged<Song>? onOpenAlbum;`
  专辑单元格用 `TuneTooltip(打开专辑)` + `InkWell` 包裹，`Semantics(button: true)`，
  hover 时文字加下划线；专辑为空或找不到汇总时不显示可点态（保持纯文本）。
- **命中规则只有一份**：把 `library_pane.dart:708` 的 `_currentAlbumKey` 与新的点击解析抽成
  `LibraryAlbum? _albumOf(List<AlbumSummary>, Song)`（精确 key → 合并节目按归一化名 + 来源），
  当前曲定位与列点击共用它。
- 专辑墙、专辑页头（封面 / 专辑名 / 艺人 / 曲目数 / 总时长 / 播放全部）保持不变，只由新按钮进入。

### D4 计数口径

- 页头摘要：`librarySummary` 的 4 份文案从「{count} 首歌曲」改为「{count} 项内容」，数字仍是全库
  `library.total`（页头描述库本身）。
- 工具条计数：始终显示，数字用 `library.matching`，单位随作用域：音乐 `libraryTrackCount`（首）、
  播客 `libraryEpisodeCount`（集）、有声书 `libraryChapterCount`（章）、电台新键
  `libraryStationCount`（台）；多选时用 `libraryTrackCount` 的「首」作中性单位。
- `LibraryToolbar` 入参 `filteredCount` 改为 `count` + `ContentKind? kind`，不再用 `showCount` 门控。

### D5 不做

- 不新增一级导航（播客 / 电台独立页），不改路由。
- 不改扫描器、音源适配器、SQL 分类规则。
- 不做按专辑分组的歌曲线性列表（避免虚拟列表分节与性能预算）。
- 不改专辑墙分节与合并规则。

## 待确认（默认按推荐执行，批准即视为认可）

1. **默认视图**：保持「歌曲」（推荐）；若希望打开就是专辑墙，把 D3 的默认 `_view` 改成 `albums`。
2. **5 个未声明 IA 实例的归属**（不改判定规则，只补声明表）：
   推荐 `news_recordings → radio`、`science_talks → podcast`、`poetry_books → audiobook`、
   `poetry → audiobook`、`unlocked_recordings → music`（保持）。
   若全部保持未声明，它们继续出现在「音乐」作用域里。

## 验收

- `flutter gen-l10n` 产物一并提交；`flutter analyze` 无问题。
- `flutter test` 全绿（排除 `music_source_e2e_live_test.dart`、`music_source_live_test.dart`）。
- 新增 / 更新测试：
  - `library_filter_test.dart`：`LibraryFilter.songs`、`withoutGroups`。
  - `library_controller` 相关测试：无保存视图 → `kinds == {music}`；`setFilter(empty)` 后仍是 `{music}`；
    `otherKindCount` / `matching` 写入。
  - `library_header` 测试：内容菜单四项与勾选、专辑按钮显隐与回调。
  - `library_album_test.dart`：`_albumOf` 的精确 key 与合并节目回退。
  - `library_database_test.dart`：`kinds={music}` 查询排除 `archive_podcasts`。
- 手工（Linux 桌面）：打开音乐库默认只看到音乐（`RelicRadio` 行消失）→ 内容菜单切「播客」看到
  `Case Closed!` →切回「音乐」→ 点专辑列进入专辑页并能返回 → 页头「专辑」进入专辑墙。
- 待用户确认后截图对比：默认视图、内容菜单切播客、专辑页、专辑墙。
