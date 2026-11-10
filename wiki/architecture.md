# 整体架构

> 本文是 `docs/architecture.md` 的导览版；硬约束与扩展步骤以那份为准。

## 分层与依赖方向

```text
presentation → application → domain
       └────────→ data/services → domain/models
```

| 层 | 位置 | 职责 | 不做什么 |
| --- | --- | --- | --- |
| domain | `features/<f>/domain/`、`lib/domain/models/` | 不可变状态、业务规则、纯逻辑 | 不依赖 Flutter、不做 I/O |
| application | `features/<f>/application/` | controller / provider，状态的唯一所有者 | 不持有 `BuildContext`，不在 build 里写 provider |
| data | `features/<f>/data/`、`lib/data/services/` | 持久化与外部 I/O | 不依赖 Riverpod、不 import `features/` |
| presentation | `features/<f>/presentation/` | widget / page | 只 `ref.watch` 读、`ref.read(...notifier)` 写；不直接持有 service |

**硬约束**（`docs/architecture.md`）：

1. `domain/`、`data/`、`core/` 不 import `features/`、`app/`、`shared/ui/`。
2. `features/x/presentation` 不 import `features/y/presentation`；跨页面组合放 `app/router` 或 `features/shell`，复用 widget 下沉 `shared/ui`。
3. `features/x/application` 可以 import 别的 feature 的 `application` / `domain`（library 调 playback 就是这样），但不 import 别人的 `presentation`。
4. 页面切换只有路由一处：shell 直接放路由给的 `child`，过渡走 `CustomTransitionPage`（`test/app/shell_page_switch_test.dart` 守着这条线）。
5. 播放队列不是路由页：`QueuePanel` 由 `SidePanelHost` 在页面区内组合，显隐是 `CompactShell` 的本地 state。

## 路由结构

`lib/app/router/app_router.dart`，初始路由 `/library`，未知路径重定向回 `/library`。

| 路由 | 页面 | 导航器 |
| --- | --- | --- |
| `/library` | `LibraryPane` 音乐库 | ShellRoute（CompactShell 内） |
| `/discover` | `DiscoveryPane` 发现 | 同上 |
| `/favorites` | `FavoritesPane` 喜欢 | 同上 |
| `/sources` | `SourcesPane` 音源 | 同上 |
| `/settings` | `SettingsPane` 设置 | 同上 |
| `/now-playing` | `NowPlayingPage` 正在播放 | 根导航器（整窗覆盖） |
| `/marks` | `SmartLyricsMarksPage` 歌词标记 | 根导航器（整窗覆盖） |

## 状态归属（单一事实来源）

| 状态 | 唯一来源 | 职责 |
| --- | --- | --- |
| 播放 + 队列 | `PlaybackController` / `PlaybackState`（features/player） | 队列是 `PlaybackState` 的一部分，没有第二个队列容器 |
| 队列侧栏显隐 | `CompactShell` / `NowPlayingPage` 的本地 state | 纯呈现状态，不持久化、不进 provider |
| 音乐库 | `LibraryController` / `LibraryState`（features/library） | 加载、扫描、过滤；不负责播放 |
| 喜欢 | `FavoritesController` / `FavoritesState`（features/favorites） | 标了心的曲目 id 集合 |
| 歌词 | `LyricsController` / `LyricsState`（features/player） | 自己 watch 当前曲目取词；播放位置仍归 `PlaybackController` |
| 设置 | `SettingsController` / `SettingsState`（features/settings） | 主题、语言、扫描目录、播放行为、桌面集成 |
| 音源 | `MusicSourcesController` / `MusicSourcesState`（features/sources） | 音源开关、配置、权重、健康度 |
| 发现页 | `DiscoveryController` / `DiscoveryState`（features/discovery） | 音乐库、喜欢与反馈的派生视图；分段只在内存 |
| 推荐反馈 | `DiscoveryFeedbackStore` / `DiscoveryArtistFeedbackStore` | 单曲与歌手「少推荐」标记，30 天过期 |
| 播放记录 | `ListeningSignalStore` + `DiscoverySignalObserver` | 可选本地聚合，默认关闭 |
| 智能歌词进度 | `SmartLyricsController` / `SmartLyricsRun` | 只持有运行进度；结果经 `LyricsController` 进 `LyricsState` |
| 智能歌词任务/标记/抽样/核对 | `library.db` 的 `smart_lyrics_*` 表 | 统计在数据库里算，按需取窗口 |

## 性能架构（摘要）

- **快慢值分订阅**：`playbackOverviewProvider` 是从 `PlaybackState` 派生的慢值切片（队列、模式、音量），页面订它；播放位置（每秒数跳）由进度条那一小块自己订。
- **行级订阅**：列表行的收藏态、当前曲、播放态由行自己读；页面只订结构、顺序与筛选。
- **库按窗读取**：`LibraryState.songs` 只是 SQLite 的一个窗口（`windowSize = 1000`），列表底部按需取下一窗；保存是增量 upsert。
- **淘汰在数据库内**：按 `last_played → play_count → last_seen → date_added` 用窗口函数裁剪，`pinned = 1` 的收藏不参与排名。
- **UI 线程不做同步 I/O**：`existsSync()` 一类调用不进每秒走到的路径。

诊断与判据见 `docs/performance.md`。

## 持久化地图

| 数据 | 落在哪 | 谁写 |
| --- | --- | --- |
| 偏好（主题、语言、扫描目录、音源开关） | `<应用支持目录>/settings/`，**一个偏好一个文件** | `FilePersistenceService` |
| 喜欢的曲目 | `library.db` 的 `favorites` 表 | `FavoritesStore` |
| 推荐反馈 / 歌手反馈 | `settings/`，键 `discovery_feedback_v1` / `discovery_artist_feedback_v1` | `DiscoveryFeedbackStore` / `DiscoveryArtistFeedbackStore` |
| 播放记录 | `library.db` 的 `listening_signals` 表 | `ListeningSignalStore` |
| 播放会话（队列、游标、模式、历史） | `library.db` 的 `queue` / `queue_meta` 表 | `PlaybackSessionStore` |
| 播放进度 | `queue_meta` 表，每 5 秒单独写 | `PlaybackSessionStore` |
| 音乐库索引 | `<应用支持目录>/library/library.db`（SQLite） | `SqliteLibraryStorage` |
| 音乐库视图（排序、筛选） | `<应用支持目录>/library/view.json` | `LibraryStorage.saveView` |
| 下载的曲目 | `<音乐库>/<歌手>/<专辑>/<歌名>/<歌名>.<格式>` | `HttpSongDownloadService` |
| 副本标记 | 曲目目录内 `<歌名>.tune`（含 `tune://<音源>/<id>`） | `CopyMarker` |
| 封面图 | `<音乐库>/.tune/artwork/<哈希前两位>/<哈希>.img` | `FileArtworkCache` |
| 歌词 | 曲目目录内 `<歌名>.lrc` / `<歌名>.manual.lrc` / `<歌名>.smart.lrc` + `.smart.json` | `LyricsController` / `SmartLyricsService` → `LibraryPaths` |

要点：

- **一偏好一文件**：两个进程同时开 app 各写各的，不会互相抹掉；旧的整份 JSON 由 `LegacyPreferenceMigration` 搬一次。
- **会话与进度分开存**：队列只在切歌/编辑时写，进度每 5 秒写，避免为几秒进度重写整条队列；恢复时一律停在暂停态（`docs/playback-session.md`）。
- **封面按地址哈希落盘**：同一地址只存一份；只有屏幕上看得见的封面才去下载；MPRIS 媒体卡片读的就是缓存里的本机文件。
- **应用 id 不能改**：Linux 应用支持目录名就是应用 id，改 id 等于换空目录。

## 音乐库磁盘目录

目录形状由 `LibraryPaths`（`lib/data/services/library/library_paths.dart`）统一决定，别处不拼路径：

```text
<音乐库>/
├── .tune/artwork/<哈希前两位>/<哈希>.img   # 浏览过但没下载的封面
├── <歌手>/<专辑>/<歌名>/
│   ├── <歌名>.mp3          # 下载的音频
│   ├── <歌名>.jpg          # 封面
│   ├── <歌名>.lrc          # 匹配到的歌词
│   ├── <歌名>.manual.lrc   # 读者自己指定的歌词（优先读）
│   ├── <歌名>.smart.lrc    # 智能歌词票池共识稿（读取顺序垫底）
│   ├── <歌名>.smart.json   # 翻译/音译对照（键入词稿日期）
│   └── <歌名>.tune         # 副本标记
└── ...
```

- 一首歌一个目录：音频、封面、歌词在一起，别的播放器打开也认得。
- 副本标记让「远程曲目的本地副本」在库里只有一条，同时标着「本地」和「在线」。
- 用户磁盘上已有的曲子不动，app 只在旁边写歌词；目录名过 `safeFileName` 清洗。

## 桌面集成架构

桌面相关的外部输入汇到 `features/desktop/application`（适配器，不持有播放状态）：

| 位置 | 职责 |
| --- | --- |
| `desktop_integration_provider.dart` | 装配 controller，跟随设置与语言变化 |
| `desktop_integration_controller.dart` | 总装：起服务、订阅播放状态、同步托盘 |
| `desktop_window.dart` | 窗口显示、隐藏与退出 |
| `mpris_state_mapper.dart` | 播放状态 → MPRIS 快照 |
| `tray_integration.dart` | 托盘菜单、提示与动作 |
| `playback_mpris_backend.dart` | MPRIS 命令 → `PlaybackController` 动作 |
| `opened_files_handler.dart` | 桌面交来的文件 → 扫描 → 入库并播放 |

播放状态仍只有 `PlaybackController` 一个来源；MPRIS、托盘、单实例都走**会话总线**（`DBusClient.session()`）。
