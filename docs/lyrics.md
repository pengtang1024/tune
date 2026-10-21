# 歌词

> AGENTS.md 的展开文档。改歌词链路（取词、解析、高亮、落盘）前读这份。
> 音源侧的整体约定见 [需求/音源设计.md](../需求/音源设计.md) 的「4.4 歌词」。

## 0. 一句话

歌词是**按需**取的：用户打开歌词面板才去要，要到了就写在曲目旁边，下次直接读本地。

## 1. 分层与依赖方向

```text
LyricsPanel (features/player/presentation)
  └── LyricsController (features/player/application)
        ├── MusicSourceService.fetchLyrics(song) (data/services/music_sources)
        │     ├── MusicSourceAdapter.fetchLyrics(config, song)   音源自己的歌词
        │     └── LyricsProvider.lookup(song)                     共享库（LRCLIB）
        ├── LibraryPaths.readLyrics / saveLyrics (data/services/library)
        └── LyricsDocument.parse (features/player/domain)
```

- 播放位置仍由 `PlaybackController` 独家持有，歌词只**读**位置，不写。
- 歌词文档（解析结果）是纯数据，留在 `features/player/domain`，不依赖 Flutter。
- service 不依赖 Riverpod，也不 import `features/`。

## 2. 现状与已知缺陷（2026-10-21 实测）

分层本身是对的，问题都在实现细节里。

| # | 缺陷 | 位置 | 症状 |
| --- | --- | --- | --- |
| D1 | 共享库兜底对本地曲目不生效 | `music_source_service.dart:191` | `sourceId` 为空就 `return null`，而本地扫描出来的歌 `sourceId` 是 null（`song_creator.dart:32`）→ Linux 桌面主场景永远显示「这首歌没有歌词」 |
| D2 | 失败被显示成「没有」 | `music_source_service.dart:204` | service 内部吞掉异常返回 null → `LyricsState.failed` 是死代码，断网与「确实没有」分不开，也没有重试的地方 |
| D3 | LRC 头部标签被当成歌词行 | `lyrics_document.dart:72` | `[ti:] [ar:] [al:] [by:] [length:] [offset:]` 全部排在歌词最前面显示；`[offset:]` 没生效，整体时间偏移 |
| D4 | 快切歌时歌词串台 | `lyrics_controller.dart:57` | A 的请求后到会覆盖 B 的状态，B 的歌词显示不出来 |
| D5 | 播放位置一跳就整块重建 | `lyrics_panel.dart:61` | `watch(position)` 让整个列表跟着重建；`indexAt` 还是 O(n) |
| D6 | 用 `addPostFrameCallback` 触发加载 | `lyrics_panel.dart:52` | 违反 AGENTS.md §1.2 |
| D7 | 歌词只在 `/now-playing` 独立路由 | `app_router.dart:61` | **不改**：歌词是播放页的能力，主窗口底栏点开播放页就够得着，不另开菜单项 |
| D8 | 没有手动指定歌词文件的入口 | — | 用户手上有 `.lrc` 但命名对不上，只能干等 |

## 3. 方案

### 3.1 歌词文档（`features/player/domain/lyrics_document.dart`）

一份 LRC 有三类东西：**头部标签**、**时间戳**、**正文**。分开对待。

- `LyricsLine` 增加 `timed` 标志：这一行带不带时间戳。不带时间戳的行 `time` 是 `Duration.zero`。
  - 现在的 `isTimed` 用 `time > Duration.zero` 判断，`[00:00.00]` 开头的整份歌会被当成没有时间戳——改用显式标志。
- 头部标签（`ti` `ar` `al` `au` `by` `re` `ve` `length`）**不显示**，但要认出来，不能当歌词行。
- `[offset:±毫秒]` 生效：`offset` 为正表示歌词提前，按 `时间戳 - offset` 计算。
- 增强 LRC 的逐字标签 `<00:12.00>` 从正文里去掉（逐字高亮不做，标签不能露出来）。
- 行的顺序：**有时间戳的行按时间升序在前，没有时间戳的行按原顺序在后**。
  - 纯文本歌词（整份都没有时间戳）保持原顺序，按正文展示。
  - 没有时间戳的行永远不会被高亮，也不参与定位。
- `indexAt(position)` 改成二分查找（O(log n)），只认有时间戳的行；**第一行还没唱到时返回 `-1`**（现在是 0，开唱前就高亮了第一行）。

### 3.2 取词（`data/services/music_sources/`）

`MusicSourceService.fetchLyrics` 的语义改成三段：

```text
1. 曲目标签里自带歌词          → 直接用
2. 音源自己的歌词              → 音源出错只记日志，不挡住第 3 段
3. 共享库（LRCLIB）           → 没有 sourceId 的本地曲目也走这里
```

- 第 3 段的异常**向上抛**：断网是「加载失败」，不是「没有歌词」。
- 第 2 段没有歌词是常态（`null`），不是错误。

`LrclibLyricsProvider` 的取词顺序：

1. `/api/get`（精确匹配 `track_name` + `artist_name` + `album_name` + `duration`）——非 200 一律往下走。
2. `/api/search`（原始标题 / 歌手 / 专辑）。
3. `/api/search`（歌手归一化后的名字：去掉 `feat.` `ft.` `remaster` `remix` 等后缀）——前两步都落空才试。

选哪一份：**带时间戳的优先，其次时长吻合的纯文本，最后才是时长对不上的**（`需求/音源设计.md` §4.4 已定的顺序，不改）。
时长容差从固定 3 秒放宽成「绝对 3 秒 **或** 相对 2%」，重录版与不同母带也能对上。

### 3.3 控制（`features/player/application/lyrics_controller.dart`）

控制器**自己看着播放器**：`AsyncNotifier` 的 `build` 里 `watch` 当前曲目，页面不碰 provider。

- 为什么不用 `initState` 里 `ref.read(...).load(...)`（旧写法）：Riverpod 不允许在 widget 生命周期（`build` / `initState` / `dispose` / `didUpdateWidget` / `didChangeDependencies`）里改 provider，实跑会抛「Tried to modify a provider while the widget tree was building」。取词由控制器发起，页面只负责显示。
- 状态：`AsyncValue<LyricsState>`。
  - `AsyncLoading` = 正在取词。
  - `AsyncError` = 取词失败（断网、服务不可用）。
  - `AsyncData` + `LyricsState`：`document` 有值 = 有歌词；`document` 为空 = 确实没有；`invalid` = 读者选的文件读不出歌词。
  - `LyricsState.songId` 记着歌词属于哪首歌：切歌刷新期间，屏幕上不能留着上一首的词。
- 会话记忆（`lyricsMemoryProvider`）记住的不只是歌词，还有「查过没有」与「读者的文件读不出」：没有歌词的曲子不会每开一次面板就重问一次网络。记忆比面板活得久（面板是 `autoDispose`）。
- 竞态（D4）：
  - 切歌：provider 依赖变了就重建，框架自己丢掉旧请求的结果。
  - 读者在请求回来的路上带了歌词：控制器给每次「读者带来的答案」换一个号（`_generation`），旧请求看到这个号变了就丢掉自己的答案。
- 三个动作：
  - `build()`：跟着当前曲目取词（命中记忆直接用）。
  - `reload(song)`：强制重查（清记忆 + 重建），给「重试」与「重新查找」用。
  - `attach(song, bytes)`：用读者指定的歌词文件，写到曲目旁边，立刻生效；返回文件里有没有歌词。
- 歌词文件有两个名字：`<歌名>.lrc`（app 匹配到的）与 `<歌名>.manual.lrc`（读者自己指定的）。
  - 读的时候**先读后者**，再读前者：读者明确选的，比 app 匹配到的更算数。
  - 写的时候：`<歌名>.lrc` 不存在就写它；已经存在就写 `<歌名>.manual.lrc`，**不覆盖读者自己的文件**（AGENTS.md：用户磁盘上已有的东西不动）。
- 落盘失败只记日志，不变成未捕获异常，也不把歌词藏起来。

### 3.4 界面（`features/player/presentation/`）

- `LyricsPanel` 自己从 `PlaybackController` 读当前曲目与播放位置，不再由调用方传歌。
- 面板只显示，不改 provider（见 3.3）。五种状态，各自有下一步：

  | 状态 | 显示 | 动作 |
  | --- | --- | --- |
  | 没有在放 | 图标 + 「还没有正在播放的曲目」 | — |
  | 加载中 | 转圈 + 「正在加载歌词」 | — |
  | 加载失败 | 错误图标 + 「歌词加载失败」 | 「重试」「选择歌词文件」 |
  | 文件读不出 | 图标 + 「这个文件里没有歌词」 | 「选择歌词文件」 |
  | 没有歌词 | 图标 + 「这首歌没有歌词」 | 「重新查找」「选择歌词文件」 |
  | 有歌词 | 歌词列表，当前行高亮并自动滚动 | — |

- 高亮位置由派生 provider（`activeLyricLineProvider`）算，**只有高亮行变了面板才重建**（D5）。
- 滚动由 `ref.listen` 驱动，不在 build 里做副作用。
- 去掉 `addPostFrameCallback`（D6）：触发取词的是控制器自己，不是页面。
- 「选择歌词文件」走 `file_picker`（已在依赖里），取字节交给 controller 解码与落盘。
  - 解码：UTF-8（去 BOM）→ 有坏字节再试 GBK（`charset` 包）。中文歌词文件常见 GBK。
- 歌词是**播放页的能力**，不是独立页面：主窗口底栏点开播放页，顶栏的歌词按钮在「曲目信息」和「歌词」之间切换。侧边栏没有歌词入口，也没有 `/lyrics` 路由。

## 4. 影响范围

**改动**

- `lib/features/player/domain/lyrics_document.dart`——解析规则、定位算法
- `lib/features/player/application/lyrics_controller.dart`——状态语义、竞态、缓存、三个动作、高亮行
- `lib/features/player/presentation/lyrics_panel.dart`——五种状态、动作、按行重建
- `lib/data/services/music_sources/music_source_service.dart`——三段取词与错误语义
- `lib/data/services/music_sources/lrclib_lyrics_provider.dart`——精确匹配、归一化、容差
- `lib/data/services/library/lyrics_text.dart`（新）——歌词文件的解码（UTF-8 / GBK）
- `lib/data/services/library/library_paths.dart` + `impl/library_paths_io.dart` + `impl/library_paths_stub.dart`——两个歌词文件的名字与读取顺序
- `lib/l10n/app_*.arb` + 生成的 `app_localizations*.dart`——新文案（四种语言同步）
- `pubspec.yaml` + `pubspec.lock`——`charset`（GBK 解码）

**文档**

- `docs/architecture.md`——状态归属与持久化表补歌词这一行
- `需求/音源设计.md` §4.4——取词顺序与错误语义对齐
- `AGENTS.md`——文档地图加一行

## 5. 测试策略

| 目标 | 场景 |
| --- | --- |
| `LyricsDocument.parse` | 头部标签不当歌词行；`offset` 正负都生效；`[00:00.00]` 仍算有时间戳；纯文本保持原顺序；混合时无时间戳的行排在后面且不高亮；一行多个时间戳；二分定位在首行之前返回 `-1` |
| `MusicSourceService.fetchLyrics` | 自带歌词直接用；音源有歌词优先；音源没有 → 共享库；**没有 sourceId 的本地曲目也走共享库**；音源出错 → 记日志后仍走共享库；共享库出错 → 异常抛给调用方 |
| `LrclibLyricsProvider` | 精确命中走 `/api/get`；精确未命中退回 `/api/search`；歌手归一化后命中；选带时间戳且时长吻合的；容差 2% 生效；非 200 当作未命中 |
| `LyricsController` | 四种状态各自可达；切歌后旧结果被丢弃；记忆命中不再请求；`reload` 跳过记忆；`attach` 落盘并生效；已有同名 `.lrc` 不被覆盖（改写 `.manual.lrc`）；落盘失败不影响状态；**面板挂在树上时不改 provider**（回归测试） |
| `LyricsPanel` | 四种状态各有对应的文字与动作；「重试」触发 reload；「选择歌词文件」把字节交给 controller；高亮行变化才滚动 |

**门禁**：`flutter analyze` 无 issue、`flutter test` 全绿、改过文案跑 `flutter gen-l10n` 并提交产物。

## 6. 风险与回退

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| `/api/get` 返回 503（实测 LRCLIB 对不存在的歌也回 503） | 精确匹配形同虚设 | 非 200 一律退回 `/api/search`；两级都失败才算「加载失败」 |
| 共享库对本地曲目开放后，请求量变大 | 慢 | 只在打开面板时请求；会话内缓存「查过没有」；结果写盘后不再请求 |
| 手动歌词文件覆盖读者自己的 `.lrc` | 读者文件丢失 | 已有同名文件时不覆盖，改写 `<歌名>.manual.lrc`，读取时按这个顺序找 |
| GBK 解码引入新依赖 | 构建变化 | `charset` 已在依赖树里（传递依赖），加直接依赖不引新包；解码失败退回 UTF-8 容错 |
| 歌词要做成能力还是页面 | 读者多绕一步 | 做成播放页里的能力（顶栏按钮切换），侧边栏不添入口 |

**回退**：改动集中在歌词链路的 8 个文件，逐个提交；任何一层不满意可以单独回退对应提交，不影响别的层。

## 7. 实施计划

1. **M1 文档解析**：头部标签、`offset`、显式 `timed`、二分定位、无时间戳行排后。
2. **M2 取词语义**：本地曲目也走共享库；失败与缺失分开。
3. **M3 控制**：竞态、缓存、重试、手动文件。
4. **M4 界面**：四态与动作、按行重建、去掉 post-frame callback。
5. **M5 命中率**：`/api/get` 精确匹配、歌手归一化、容差放宽。
6. **M6 播放页的歌词能力**：面板挂在播放页顶栏的歌词按钮上，不做独立页面、不加侧边栏入口。
7. **M7 收尾**：文案四语同步 + `gen-l10n`、文档同步、门禁。

每个里程碑按 TDD 走：先写会失败的测试，再写刚好能过的实现。
