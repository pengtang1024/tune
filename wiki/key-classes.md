# 关键类与函数

> 按「入口 → 状态机 → 服务接口 → 领域模型」组织。方法只列公开 API，完整签名以代码为准。

## 入口与启动

### `main()` — [lib/main.dart](file:///home/pt/Work/IdeaProjects/tune/lib/main.dart)

bootstrap 序列：

1. `registerThirdPartyLicenses()` 注册第三方许可证。
2. 挂全局错误捕获（`FlutterError.onError` / `PlatformDispatcher.instance.onError`）进 `Log.error`。
3. `_claimThePlayerPlace(container)`：经 `singleInstanceServiceProvider` 抢占总线上的播放器位置；抢不到则把命令行文件转发给已运行的实例并退出。
4. `runApp(UncontrolledProviderScope(container, child: TuneApp()))`。
5. 启动两个智能歌词后台循环：`smartLyricsLeakCheckControllerProvider.start()`（空闲查漏）与 `smartLyricsAutoFillControllerProvider.start()`（自动补齐，默认开）。

### `TuneApp` — [lib/app/app.dart](file:///home/pt/Work/IdeaProjects/tune/lib/app/app.dart)

- `appInitializationProvider`（`FutureProvider<void>`）：跑 `AppInitializer.initialize(ref)`，再 `_scheduleStartupScan`（开了自动扫描就在后台扫，不挡首帧）。
- 初始化完成后才构建 `MaterialApp.router`（避免播放器读到空会话丢队列）。
- `builder` 链：`LocalizationBridge` → 文本缩放 clamp（1.0–1.3）→ `HintLayer`（全应用唯一提示卡片宿主）。

### `AppInitializer.initialize` — [lib/config/app_initializer.dart](file:///home/pt/Work/IdeaProjects/tune/lib/config/app_initializer.dart)

按序初始化：偏好存储 → 数据库 → 喜欢 → 播放记录 → 播放会话 → 音频播放器 → 扫描器 → 桌面集成 → 发现页信号观察。

## 播放状态机

### `PlaybackController` — [lib/features/player/application/playback_controller.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/application/playback_controller.dart)

- provider：`playbackControllerProvider`（`StateNotifierProvider<PlaybackController, PlaybackState>`），构造时注入音频、下载、流地址解析、会话存储。
- `snapshot`：对外只读状态入口。
- `enqueueAndPlay(Song)`：加入队列并立即播放（列表/搜索结果点击）。
- `next()` / `previous()` / `seekTo()` / `setVolume()`：切歌、回退、进度跳转、音量。
- `setPlayMode()`：顺序 / 随机 / 重复切换。

### `PlaybackState` — [lib/features/player/domain/playback_state.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/domain/playback_state.dart)

字段：播放状态、进度、音量、播放模式、**队列**（队列没有第二个容器）、当前 URI、历史、错误、缓存进度。

### `playbackOverviewProvider` — [lib/features/player/application/playback_overview_provider.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/application/playback_overview_provider.dart)

从 `PlaybackState` 派生的慢值切片（`PlaybackOverview`）：队列、模式、音量。页面订它，进度条自己订位置——订阅整份状态的界面会被位置带着整块重建。

### `LyricsController` — [lib/features/player/application/lyrics_controller.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/application/lyrics_controller.dart)

- provider：`lyricsControllerProvider`（`AsyncNotifierProvider.autoDispose`）；`lyricsMemoryProvider` 是会话级歌词缓存。
- 自己 watch 播放器的当前曲目来取词，页面只读不改。
- `reload()`：重新加载；`attach()`：附加读者指定的歌词文件并写盘（`.manual.lrc`）。

### 播放辅助

| 类 | 方法 | 职责 |
| --- | --- | --- |
| `AudioSourceResolver` | `sourceFor(Song) → PlaybackSource` | 本地副本 → 缓存 → 直播流 → 网络的解析顺序 |
| `TrackPrefetcher` | `prefetch()` | 按队列、模式、远程/直播状态预取下一首（失败回退网络播放） |
| `ListPlayback` | `play()` / `playFrom()` | 列表点击行为，由 `settingsControllerProvider` 的 `replaceQueueOnClick` 驱动 |
| `PlaybackSessionRecorder` | `read()` / `readVolume()` / `start()` | 会话基线读取与记录启动 |

## 音乐库

### `LibraryController` — [lib/features/library/application/library_controller.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/application/library_controller.dart)

- 加载、扫描、排序、筛选的唯一入口；`autoScan(localPaths)` 是启动自动扫描。
- `LibraryState.songs` 始终是 SQLite 的一个窗口（1000 行）；`setSort` / `setFilter` 后写一次 `view.json`。

### `LibraryStorage` → `SqliteLibraryStorage` — [lib/features/library/data/impl/library_storage_io.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/data/impl/library_storage_io.dart)

- 窗口读取、增量 upsert、视图 JSON 读写；淘汰用 SQLite 窗口函数在库内完成。

## 其余 feature controller

| 类 | provider | 关键方法 / 字段 |
| --- | --- | --- |
| `FavoritesController` | `favoritesControllerProvider`（NotifierProvider） | `contains` / `mark` / `toggle`；`_writing` 防并发写 |
| `FavoritesState` | — | `ids: Set<String>`；`contains`、`count` |
| `MusicSourcesController` | `musicSourcesControllerProvider`（AsyncNotifierProvider） | `build`：加载配置、规范化权重、读健康历史 |
| `MusicSourcesState` | — | `sources`、`lastScanAt`、`healthHistory`；`byId` / `enabled` / `hasEnabledRemote` |
| `SettingsController` | `settingsControllerProvider`（StateNotifierProvider） | 构造时从偏好存储读主题/语言/扫描路径/全部开关 |
| `SettingsState` | — | 主题、语言、扫描路径、播放行为、健康度权重、智能歌词配置 |
| `DiscoveryController` | `discoveryControllerProvider`（AutoDisposeAsyncNotifierProvider） | `build` 汇总库/喜欢/反馈/队列/健康度后 `_compute` |
| `OnlineSearchController` | search/application | 跨音源搜索、防抖、分页 |

## 推荐引擎

### `RecommendationEngine` — [lib/features/discovery/domain/recommendation_engine.dart](file:///home/pt/Work/IdeaProjects/tune/lib/features/discovery/domain/recommendation_engine.dart)

`recommend(...)` 接收 library / favorites / profile / dismissed / queue / health / source order，流程：

```text
构建候选 → 打分（recommendation_scoring）→ 排序（recommendation_sequencer）
→ 生成 daily mix / artist / favorite / fresh / explore / source 分段
→ DiscoveryOutput
```

队列里的曲目降权、健康度低的音源降权、被「少推荐」的单曲与歌手排除。

## 服务接口（data/services）

### `AudioPlayerService` → `JustAudioPlayerService`

接口契约：播放、暂停、继续、停止、跳转、音量、速度、当前进度/时长、事件流、释放资源。
实现基于 `just_audio` / `just_audio_media_kit`，处理 Linux 后端初始化、错误转义、本地/远程地址选择。

### `MusicSourceAdapter` — [lib/data/services/music_sources/music_source_adapter.dart](file:///home/pt/Work/IdeaProjects/tune/lib/data/services/music_sources/music_source_adapter.dart)

每个音源类型必须提供：`sourceType`、配置校验、浏览模式、分页/预览支持、扫描、刷新播放地址、获取歌词。

已注册类型（`SourceTypeCatalogue`）：`local`、`openverse`、`jamendo`、`internet_archive`、`ccmixter`、`podcast_rss`、`subsonic`、`audius`、`radio`、`wikimedia`、`jellyfin`、`librivox`、`emby`、`plex`、`funkwhale`、`audiobookshelf`、`direct_url`、`m3u`、`json_api`、`graphql`。

### `MusicSourceService` — [lib/data/services/music_sources/music_source_service.dart](file:///home/pt/Work/IdeaProjects/tune/lib/data/services/music_sources/music_source_service.dart)

- 维护 `type → adapter` 注册表（可注入，测试不改全局状态）、`MusicSourceStore`、`LyricsProvider`。
- 实现 `StreamUrlResolver.refresh(Song)`：刷新远程曲目播放地址（网易云、Subsonic、播客、Jellyfin 支持单曲刷新）。

### `AppDatabase` — [lib/data/services/database/app_database.dart](file:///home/pt/Work/IdeaProjects/tune/lib/data/services/database/app_database.dart)

- 表：`songs`、`favorites`、`queue`、`queue_meta`、`listening_signals`、`smart_lyrics_tasks`、`smart_lyrics_marks`、`smart_lyrics_sample`、`smart_lyrics_audit`。
- `load()` 读活跃歌曲窗口；`save()` 批量 upsert `songs`。

### `PersistenceService` → `FilePersistenceService`

`init`、字符串/整型/布尔/双精度/列表读写、`remove`、`clear`、获取所有键。实现一偏好一文件。

### `ArtworkCache` → `FileArtworkCache`

- `imageFor`：读/下载/缓存封面；`coverFileFor`：返回本地封面路径（MPRIS 媒体卡片用）。
- 文件名是地址稳定哈希，按哈希前两位分桶。

### `SongDownloadService` → `HttpSongDownloadService`

`isSupported`、`storedFileFor`、`markCopiesOf`（给老副本补 `.tune` 标记）、`download`、`cancel`、`dispose`；并发下载合并 + 进度 + 取消。

### `SmartLyricsEngine` — [lib/data/services/smart_lyrics/smart_lyrics_engine.dart](file:///home/pt/Work/IdeaProjects/tune/lib/data/services/smart_lyrics/smart_lyrics_engine.dart)

转录通道抽象：`id`、`transcribe`、`runTranscription`、`dispose`、`requestCancel`。
实现：`WhisperLocalEngine`（本地 whisper）、`SherpaLocalEngine`（SenseVoice）、`OpenAiCompatibleEngine`。

### `SmartLyricsService` — [lib/data/services/smart_lyrics/smart_lyrics_service.dart](file:///home/pt/Work/IdeaProjects/tune/lib/data/services/smart_lyrics/smart_lyrics_service.dart)

`generate()` 编排整条管线：人写票 → 机器转写 → 知识票 → 票池共识 → 审计 → 落盘（`.smart.lrc` + `.smart.json`）。

## 领域模型

### `Song` — [lib/domain/models/song.dart](file:///home/pt/Work/IdeaProjects/tune/lib/domain/models/song.dart)

不可变全局实体。身份是 `uri`：本地曲目是文件路径，在线曲目是 `tune://<音源>/<编号>`。

| 分组 | 字段 |
| --- | --- |
| 基本 | `id`、`title`、`artist`、`album`、`duration`、`uri`、`dateAdded` |
| 元数据 | `genre`、`genres`、`year`、`trackNumber/Total`、`discNumber/totalDisc`、`performers`、`language`、`license`、`description` |
| 音质 | `bitrate`、`sampleRate`、`size`、`type` |
| 歌词 | `lyrics`、`hasLyrics`（扫描时写一次） |
| 来源 | `sourceId`、`externalId`、`streamUrl`、`artworkUrl`、`sourceData`、`httpHeaders` |
| 形态 | `isLiveStream`（直播不缓存、无进度）、`localPath`（远程曲目的本地副本路径）、`albumArtPath` |

派生地址（详情面板四条地址的唯一来源）：`localFile`、`onlineAddress`、`coverAddress`、`identity`。

### `MusicSourceConfig` — [lib/domain/models/music_source.dart](file:///home/pt/Work/IdeaProjects/tune/lib/domain/models/music_source.dart)

一条音源实例配置：`type`（适配器类型）+ `id`（实例标识，用户实例是 `<type>-<序号>`）+ 名称、参数、开关、`weight`。
权重规则：本地固定 1000；featured 800；读者添加 700；需要凭据 400。`weight >= 500` 在主列表，低于 500 进「更多音源」；健康度低于 60 也进更多音源。

## 共享 UI 基元（shared/ui）

| 类 | 职责 |
| --- | --- |
| `MetaChip` / `MetaBadge` / `ChipGroup`（`meta_badge.dart`） | 全应用唯一的 chip 写法：图标说话、颜色说类别、主写 chip 上、名字进 tooltip |
| `SourceBadge` / `IconGlyph` / `LiveBadge` | 音源标识、密集行图标字形、直播标记 |
| `HintLayer` / `TuneTooltip`（= `HintTrigger`） | 全应用一张提示卡片 + 触发器；widget 不直接用 `Tooltip` |
| `showCompactSheet`（`compact_sheet.dart`） | 唯一的底部浮层入口：贴底、只占自身高度、四周遮罩可点关 |
| `SidePanelHost`（`side_panel_host.dart`） | 非模态侧栏宿主：只遮内容区，底栏侧栏仍可用 |
| `TrackDetailSheet` + `track_fact*.dart` | 曲目详情面板与事实模型（三档呈现：行内图标 → 正在播放页图标+值 → 详情 chip） |
| `FavoriteButton` | 红心控件（不是事实）；状态只来自 `FavoritesController` |
