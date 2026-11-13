# 主要模块职责

> 按 `lib/` 下的包逐一说明。每个 feature 内部都按 `domain → application → data → presentation` 分层。

## features/player —— 播放与歌词

播放是全局单例状态机，队列内嵌在播放状态里。

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `playback_controller.dart` | `PlaybackController`：播放/队列状态机，连接音频事件、恢复会话 |
| application | `playback_overview_provider.dart` | 慢值切片 provider（队列、模式、音量），防位置高频重建整页 |
| application | `lyrics_controller.dart` | 歌词加载：watch 当前曲目取词、解析、读者指定歌词落盘 |
| application | `audio_source_resolver.dart` | 决定一首歌从哪播：本地副本 → 缓存 → 直播流 → 网络 |
| application | `track_prefetcher.dart` | 预取下一首（仅缓存，不决定播放） |
| application | `list_playback.dart` | 列表点击播放策略：替换队列或加入队列并播放（随设置） |
| application | `playback_session_recorder.dart` | 播放会话持久化：队列切歌/编辑时写，进度每 5 秒写 |
| domain | `playback_state.dart` | `PlaybackState`：状态、进度、音量、模式、队列、当前 URI、历史、错误 |
| domain | `play_mode.dart`、`playback_source.dart`、`lyrics_document.dart` | 播放模式枚举、播放来源、歌词文档模型 |
| data | `playback_session_store.dart` | `queue` / `queue_meta` 表的读写 |
| presentation | `player_dock.dart` | 底部播放条 |
| presentation | `now_playing_page.dart`、`lyrics_panel.dart`、`now_playing_track_info.dart` | 正在播放页（整窗路由）与歌词面板 |

## features/library —— 音乐库

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `library_controller.dart` | 加载、扫描、排序、筛选；窗口化读取 SQLite |
| application | `dead_songs_controller.dart` | 失效曲目（文件不在/地址刷不出）的标记与清理 |
| application | `playback_notes_provider.dart` | 启动时把会话笔记接进播放链路 |
| domain | `library_state.dart`、`library_filter.dart`、`library_sort.dart`、`library_category.dart`、`library_facets.dart`、`library_album.dart` | 库状态、筛选、排序、分类树、分面、专辑 |
| data | `library_storage.dart` + `impl/library_storage_io.dart` | `LibraryStorage` 接口 → `SqliteLibraryStorage`（`songs` 表窗口读写、视图 JSON） |
| presentation | `library_pane.dart` | 音乐库页（含在线搜索入口，历史例外见架构文档） |
| presentation | `library_toolbar.dart`、`library_header.dart`、`library_column_header.dart` | 页头、工具条、列头 |
| presentation | `library_columns_view.dart`、`library_albums_view.dart`、`library_category_view.dart` | 列表 / 专辑 / 分类三种视图 |
| presentation | `library_filter_panel.dart`、`library_filter_chips.dart` | 九组筛选面板与生效 chip |
| presentation | `library_track_card.dart`、`library_row_actions.dart`、`library_row_tail.dart` | 曲目行与其动作 |

## features/favorites —— 喜欢

喜欢是音乐库的一层视图，状态只有曲目 id 集合。

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `favorites_controller.dart` | `FavoritesController`：`contains/mark/toggle`，带写锁防并发 |
| domain | `favorites_state.dart` | `FavoritesState`：`ids: Set<String>` |
| data | `favorites_store.dart` | `favorites` 表读写（旧 `favorite_tracks` 首启导入） |
| presentation | `favorites_pane.dart` | 喜欢页：列出库内被标曲目，页头报库外标记数 |

## features/discovery —— 发现与推荐

全部在本机计算，不请求音源接口。设计细节见 `docs/recommendation.md`。

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `discovery_controller.dart` | 汇总库、喜欢、反馈、队列、音源健康度，调推荐引擎 |
| domain | `recommendation_engine.dart` | `RecommendationEngine.recommend`：候选 → 打分 → 排序 → 分段 |
| domain | `recommendation_scoring.dart`、`taste_profile.dart`、`recommendation_sequencer.dart` 等 | 打分、口味画像、排序器、每日混音、探索段 |
| data | `discovery_feedback_store.dart`、`listening_signal_store.dart` | 「少推荐」标记（30 天过期）、可选播放记录 |
| presentation | `discovery_pane.dart` 等 | 分段渲染：今日混音卡、歌手/流派/新鲜/探索段 |

## features/sources —— 音源管理

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `music_sources_controller.dart` | 加载配置、规范化权重、健康历史；开关与排序 |
| domain | `music_sources_state.dart` | `MusicSourcesState`：`sources`、`lastScanAt`、`healthHistory` |
| presentation | `sources_pane.dart`、`music_sources_section.dart` | 音源页：主列表 + 「更多音源」折叠、健康度权重入口 |

适配器本体在 `lib/data/services/music_sources/`（见下文「全局服务层」）。

## features/settings —— 设置

分区导航 + 六区预设 + 自定义 sheet + 搜索与恢复默认（`docs/settings-redesign.md`）。

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `settings_controller.dart` | 从偏好存储读出全部设置并持有 |
| domain | `settings_state.dart` | 主题、语言、扫描路径、播放行为、健康度权重、智能歌词配置 |
| presentation | `settings_pane.dart` | 左分区导航 + 右设置内容 |
| presentation | `settings_*_card.dart` | 各分区卡片：外观/音乐库/播放/歌词/发现/桌面/更新/许可证 |

## features/smart_lyrics —— 智能歌词

票池共识管线（`docs/smart-lyrics.md`）：人写票 + 本地 whisper / SenseVoice + OpenAI 兼容通道，共识稿落 `.smart.lrc`。

| 子层 | 关键文件 | 职责 |
| --- | --- | --- |
| application | `smart_lyrics_controller.dart` | 单曲/批量运行进度（`SmartLyricsRun`） |
| application | `smart_lyrics_auto_fill_controller.dart` | 自动补齐循环（默认开，main.dart 启动） |
| application | `smart_lyrics_leak_check_controller.dart` | 空闲时向人写票池免费再问的周期循环 |
| application | `smart_lyrics_batch_controller.dart`、`smart_lyrics_contrast_controller.dart`、`smart_lyrics_marks_controller.dart` | 批量队列、翻译/音译对照、标记页 |
| domain | `smart_lyrics_config.dart`、`channel_health.dart`、`smart_lyrics_task.dart`、`smart_lyrics_mark.dart` 等 | 配置、通道健康度、任务、标记、抽样、改词 |
| data | `smart_lyrics_task_store.dart` 等 | `smart_lyrics_tasks/marks/sample/audit` 四张表 |
| presentation | `marks_page.dart`（`/marks` 路由）、`settings_smart_lyrics_*` | 标记页与设置卡片 |

## features/search —— 在线搜索

| 文件 | 职责 |
| --- | --- |
| `application/online_search_controller.dart` | 跨音源搜索：防抖、分页 |
| `domain/online_search_state.dart` | 搜索状态 |
| `presentation/online_search_sheet.dart` | 底部浮层（走 `showCompactSheet`），结果行可直接标喜欢 |

## features/queue —— 播放队列面板

| 文件 | 职责 |
| --- | --- |
| `presentation/queue_panel.dart` | 非模态侧栏：增删、拖拽重排、点播、清空；不注册路由 |
| `presentation/queue_track_row.dart` | 队列曲目行 |

## features/shell —— 壳层

| 文件 | 职责 |
| --- | --- |
| `presentation/compact_shell.dart` | 左导航 + 页面区 + 底部播放条；队列侧栏显隐、Esc/返回关闭 |
| `presentation/app_sidebar.dart` | 左侧导航（宽/窄两档，断点 `CompactTokens.sidebarCompactBreakpoint`） |

## features/desktop —— 桌面集成

`application/` 下是适配器集合（不持有播放状态）：桌面集成总装、窗口管理、托盘、MPRIS 映射、启动文件处理。详见 [architecture.md](architecture.md) 的「桌面集成架构」。

## 全局服务层（lib/data/services）

service 不依赖 Riverpod，只编排 I/O；状态全在 controller。

| 服务 | 接口 → 实现 | 职责 |
| --- | --- | --- |
| 音频播放 | `AudioPlayerService` → `JustAudioPlayerService` | 播放/暂停/跳转/音量/速度/事件流；Linux 走 media_kit + 系统 libmpv |
| 音乐扫描 | `CrossPlatformMusicScanner`（`music_scanner_config.dart` 给配置） | 本地目录扫描、元数据读取（`audio_metadata_reader`，vendor 补丁防恶意帧） |
| 音源适配 | `MusicSourceAdapter` × 20 个类型 + `MusicSourceService` 注册表 | 取歌、浏览流、播放地址刷新、歌词；注册表可注入 |
| 持久化 | `PersistenceService` → `FilePersistenceService` | 一偏好一文件；旧 JSON 由 `LegacyPreferenceMigration` 迁移 |
| 数据库 | `AppDatabase`（`database/`） | SQLite 表定义与读写：`songs`、`favorites`、`queue`、`queue_meta`、`listening_signals`、`smart_lyrics_*` |
| 封面缓存 | `ArtworkCache` → `FileArtworkCache` | URL 稳定哈希落盘，只下载看得见的封面 |
| 下载 | `SongDownloadService` → `HttpSongDownloadService` | 并发合并、进度、取消；按 URI 哈希映射文件 |
| 智能歌词引擎 | `SmartLyricsEngine` × 3（whisper 本地 / sherpa 本地 / OpenAI 兼容） | 转录通道抽象；`SmartLyricsService.generate` 编排票池共识 |
| 桌面接口 | `mpris/`、`tray/`、`desktop/` 接口 → `impl/` 下 D-Bus 实现 | 会话总线上的 MPRIS、StatusNotifierItem 托盘、单实例 |
| 更新 | `update/` | 从 GitHub release 检查与下载新版本 |
| 流地址 | `StreamUrlResolver`（由 `MusicSourceService` 实现） | 远程曲目播放地址刷新 |

## shared / core / utils

| 包 | 职责 |
| --- | --- |
| `shared/ui/`（30 个文件） | 跨 feature 复用 widget：曲目事实 chip（`track_fact*`、`meta_badge`）、提示层（`hint_layer`/`tune_tooltip`）、底部浮层（`compact_sheet`）、侧栏宿主（`side_panel_host`）、封面缩略图等；不含业务状态 |
| `shared/utils/` | 可读地址（去 `file://`、解码 `%20`）等 |
| `core/l10n/` | `AppStrings` 单例、流派词典与标签、语言环境标签、本地化桥 |
| `core/services/` | 窗口管理服务 |
| `core/constants/`、`core/config/` | 偏好键常量、平台常量 |
| `providers/` | 跨层共享 provider：封面缓存、持久化 |
| `utils/` | `Log`（debug/info/error 三级）、`safeFileName`、稳定 key |
