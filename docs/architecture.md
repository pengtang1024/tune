# 架构契约

> AGENTS.md 的展开文档。改目录、加文件、动依赖前读这份。

## 目录结构

```text
lib/
├── main.dart                 # 只做 bootstrap：绑定、全局错误、ProviderScope
├── app/                      # MaterialApp.router、路由、主题、启动初始化
├── features/<f>/             # 按业务能力分包
│   ├── domain/               # 不可变状态与业务规则（不依赖 Flutter）
│   ├── application/          # controller / provider：状态的所有者
│   ├── data/                 # 该 feature 私有的持久化
│   └── presentation/         # widget / page：只读 provider，不含业务逻辑
├── shared/ui/                # 跨 feature 复用的 widget（不含业务状态）
├── core/                     # 通用能力：l10n、常量、扩展、窗口服务
├── data/services/            # 全局服务：播放、扫描、音源适配器、持久化
│   ├── mpris/                # 系统媒体控制的接口与快照模型
│   ├── tray/                 # 系统托盘的接口与菜单项模型
│   └── desktop/              # 默认播放器、单实例、启动参数
├── domain/models/            # 全局实体：Song、MusicSourceConfig
├── l10n/                     # ARB 源文件 + gen-l10n 产物（产物入库）
└── utils/                    # logger 等
```

## 依赖方向

```text
presentation → application → domain
       └────────→ data/services → domain/models
```

## 硬约束

1. `domain/`、`data/`、`core/` 不 import `features/`、`app/`、`shared/ui/`。
2. `features/x/presentation` 不 import `features/y/presentation`。跨页面组合放 `app/router` 或 `features/shell`；可复用 widget 下沉到 `shared/ui`。
   - 现存唯一例外：`lib/features/library/presentation/library_pane.dart` → `lib/features/search/presentation/online_search_sheet.dart`。这是待消除的历史例外，不要照抄扩散。
3. `features/x/application` 可以 import 别的 feature 的 `application` / `domain`（library 调 playback 就是这样），但不 import 别人的 `presentation`。
4. widget 只通过 provider 取状态、触发动作，不直接持有 service。
5. provider 与 controller 不持有 `BuildContext`；controller 需要文案时用 `AppStrings.instance`。
6. 页面之间的切换只有路由一处：外壳（`features/shell`）把路由的导航器交给页面区，不在页面区再切一次。切两次会同时留下两个导航器，而路由的 key 只属于其中一个。侧栏不是页面：播放队列由 `SidePanelHost` 在页面区内组合，不注册路由。内容区用遮罩挡住并移出焦点，壳层的底栏和侧栏在宿主外仍可操作；关闭走面板按钮、Esc、内容区遮罩、返回键或侧栏切页。详见 [queue-panel.md](queue-panel.md)。

## 状态归属

| 状态 | 唯一来源 | 职责 |
| --- | --- | --- |
| 播放 + 队列 | `PlaybackController` / `PlaybackState`（`features/player`） | 队列是 `PlaybackState` 的一部分，仓库里没有第二个队列容器 |
| 队列侧栏的显隐 | `CompactShell` 的本地 state / `NowPlayingPage` 的本地 state | 只是呈现状态，不持久化、不进 provider；队列内容仍归 `PlaybackController` |
| 音乐库 | `LibraryController` / `LibraryState`（`features/library`） | 加载、扫描、过滤；不负责播放 |
| 喜欢 | `FavoritesController` / `FavoritesState`（`features/favorites`） | 标了心的曲目；曲目本身还是音乐库里的那一首 |
| 歌词 | `LyricsController` / `LyricsState`（`features/player`） | 当前曲目的歌词与解析结果；控制器自己 `watch` 播放器的当前曲目来取词，页面只读不改；播放位置仍由 `PlaybackController` 独家持有，歌词只读它 |
| 设置 | `SettingsController` / `SettingsState`（`features/settings`） | 主题、语言、扫描目录、自动扫描、单曲与双击行为、桌面集成 |
| 音源 | `MusicSourcesController` / `MusicSourcesState`（`features/sources`） | 音源开关与配置 |
| 发现页 | `DiscoveryController` / `DiscoveryState`（`features/discovery`） | 音乐库、喜欢与反馈的派生视图；分段只在内存，不落盘 |
| 推荐反馈 | `DiscoveryFeedbackStore` / `DiscoveryArtistFeedbackStore`（`features/discovery`） | 单曲与歌手的「少推荐」标记，30 天过期；收藏与音乐库不受影响 |
| 播放记录 | `ListeningSignalStore` + `DiscoverySignalObserver`（`features/discovery`） | 可选的本地聚合；默认关闭，观察播放状态后结算 |
| 智能歌词的生成进度 | `SmartLyricsController` / `SmartLyricsRun`（`features/smart_lyrics`） | 只持有单曲/批量的运行进度；生成的**结果**经 `LyricsController` 进 `LyricsState`，不持有第二份歌词 |
| 智能歌词的任务、标记、抽样、核对 | `library.db` 的 `smart_lyrics_tasks` / `smart_lyrics_marks` / `smart_lyrics_sample` / `smart_lyrics_audit` 表（`SmartLyricsTaskStore` 等，`features/smart_lyrics/data`） | 批量队列、读者与系统的标记、分层抽样集、人工核对账；统计在数据库里算，按需取窗口 |

- 状态只在 application 层修改；presentation 层只 `ref.watch` 读、`ref.read(...notifier)` 写。
- 纯逻辑下沉到 domain，I/O 下沉到 `data/services`；service 不依赖 Riverpod——`MusicSourceService` 是范例：它只编排 I/O，状态由 controller 持有。
- 播放副作用（统计、历史、通知）不写进 `PlaybackController` 的核心方法，由 app 级监听器订阅状态。

### 音源的类型与实例

音源是「类型 + 实例」：类型是代码里的适配器，实例是读者的一条配置。

| | 类型 | 实例 |
| --- | --- | --- |
| 是什么 | 适配器（`lib/data/services/music_sources/`） | `MusicSourceConfig`（一条配置） |
| 决定 | 怎么取歌、品牌名与图标、浏览流、要读者填哪些参数 | 取哪一个：名字、参数、开关、权重 |
| 标识 | `type` | `id`（内置沿用旧 id，用户实例是 `<type>-<序号>`） |

- 注册表是 `type → adapter` 的数据（`MusicSourceService`），可以注入，测试因此不用改全局状态。
- 名称、品牌图标与浏览流都按类型查，界面不按 id 硬编码。
- 每个实例有一个 `weight`：越大越靠前。本地音乐固定 `1000`；其他实例默认
  `featured` 为 `800`、读者添加为 `700`、需要凭据的为 `400`。`weight >= 500`
  在主列表，低于 `500` 折叠进「更多音源」；行尾菜单可以上移、下移、移入或移出
  更多音源。健康度再守一道门：它由可用、配置、扫描、新鲜、产出、速度、可靠、
  稳定、可播放、封面、元数据、活跃十二个维度合成 0–100 分，维度权重可在设置页的「音源 / 健康度权重」
  里调整；不支持、已关闭、配置不完整、最近扫描失败或有曲目但没有任何封面（低于
  `60` 分）也进更多音源，恢复后自动回来。主列表先按健康度分档（`85+` / `70–84` /
  `60–69`），档内按 `weight`；上下移动只在同一档内生效。分组与排序不按 id 硬编码。
- 内置实例的检索词一律留空：平台自己有浏览流（最新、排行、每日推荐），应用不替读者挑口味。
- 不执行读者带来的任何脚本：自定义音源只接受声明式的参数，没有表达式，也没有求值器。

## 桌面集成

桌面相关的外部输入都汇到 `features/desktop/application`，它们是适配器，不持有播放状态。

| 位置 | 职责 |
| --- | --- |
| `lib/features/desktop/application/desktop_integration_provider.dart` | 装配 controller，并跟随设置与语言的变化 |
| `lib/features/desktop/application/desktop_integration_controller.dart` | 总装：起服务、订阅播放状态、把设置与语言的变化同步给托盘 |
| `lib/features/desktop/application/desktop_window.dart` | 窗口的显示、隐藏与退出 |
| `lib/features/desktop/application/mpris_state_mapper.dart` | 播放状态 → MPRIS 快照 |
| `lib/features/desktop/application/tray_integration.dart` | 托盘菜单、提示与动作 |
| `lib/features/desktop/application/playback_mpris_backend.dart` | MPRIS 命令 → `PlaybackController` 的动作 |
| `lib/features/desktop/application/opened_files_handler.dart` | 桌面交来的文件 → 扫描 → 入库并播放 |
| `lib/data/services/mpris/` | MPRIS 接口与快照模型（无平台依赖） |
| `lib/data/services/impl/mpris/` | MPRIS 的 D-Bus 实现 |
| `lib/data/services/tray/` | 托盘接口与菜单项模型 |
| `lib/data/services/impl/tray/` | 托盘的 StatusNotifierItem + dbusmenu 实现 |
| `lib/data/services/desktop/` | 默认播放器、单实例、启动参数、音频 MIME 列表 |
| `lib/data/services/impl/desktop/` | 上面这些在 Linux 上的实现 |

硬约束：

- 播放状态仍只有 `PlaybackController` 一个来源；桌面集成只读它、只调它的公开动作。
- service 不依赖 Riverpod，不 import `features/`；平台差异按 `*_io.dart` / `*_stub.dart` 成对实现。
- MPRIS、托盘、单实例都走**会话总线**（`DBusClient.session()`），不是系统总线。
- 详细的协议与验收见 [桌面集成方案](../需求/桌面集成方案.md)。

## 持久化

偏好与本地数据各有各的地方，同一份数据只有一份。

| 数据 | 落在哪 | 谁写 |
| --- | --- | --- |
| 偏好（主题、语言、扫描目录、音源开关） | `<应用支持目录>/settings/`，一个偏好一个文件 | `FilePersistenceService`（`lib/data/services/impl/preference_store_io.dart`） |
| 喜欢的曲目 | `library.db` 的 `favorites` 表（旧 `favorite_tracks` 首次启动导入） | `FavoritesStore`（`lib/features/favorites/data/favorites_store.dart`） |
| 推荐反馈 | `<应用支持目录>/settings/`，键 `discovery_feedback_v1` | `DiscoveryFeedbackStore`（`lib/features/discovery/data/discovery_feedback_store.dart`） |
| 歌手推荐反馈 | `<应用支持目录>/settings/`，键 `discovery_artist_feedback_v1` | `DiscoveryArtistFeedbackStore`（同一文件） |
| 播放记录 | `library.db` 的 `listening_signals` 表（旧 `discovery_listening_v1` 首次启动导入） | `ListeningSignalStore`（`lib/features/discovery/data/listening_signal_store.dart`） |
| 播放会话（队列、游标、模式、历史） | `library.db` 的 `queue` / `queue_meta` 表（旧 `playback_queue_v1` 首次启动导入） | `PlaybackSessionStore`（`lib/features/player/data/playback_session_store.dart`） |
| 播放进度 | `library.db` 的 `queue_meta` 表（旧 `playback_position_v1` 首次启动导入） | `PlaybackSessionStore` |
| 音乐库索引 | `<应用支持目录>/library/library.db`（SQLite） | `SqliteLibraryStorage`（`lib/features/library/data/impl/library_storage_io.dart`） |
| 下载的曲目 | `<音乐库>/<歌手>/<专辑>/<歌名>/<歌名>.<格式>` | `HttpSongDownloadService` |
| 副本标记 | 曲目所在目录，`<歌名>.tune` | `CopyMarker`（`lib/data/services/library/copy_marker.dart`） |
| 封面图 | `<音乐库>/.tune/artwork/` | `FileArtworkCache`（`lib/data/services/impl/artwork_cache_io.dart`） |
| 歌词 | 曲目所在目录，`<歌名>.lrc`（读者指定的写 `<歌名>.manual.lrc`） | `LyricsController` → `LibraryPaths` |
| 智能歌词的机器稿与对照 | 曲目所在目录，`<歌名>.smart.lrc`（票池共识稿，读取顺序永远垫底）与 `<歌名>.smart.json`（翻译/音译对照，键入词稿日期——词稿重生成即作废） | `SmartLyricsService` / `SmartLyricsContrastController` → `LibraryPaths` |

- **一个偏好一个文件**：两个进程同时开 app 时各写各的，不会互相抹掉。旧的整份 JSON 存储已经换掉，老的数据由 `LegacyPreferenceMigration` 搬一次。
- **播放会话与进度分开存**：队列只在切歌/编辑时写，进度每 5 秒单独写，避免为了几秒钟的进度反复重写整条队列。恢复时一律停在暂停态，规则见 [playback-session.md](playback-session.md)。
- **封面图落盘**：文件名是地址的稳定哈希，同一个地址只存一份，重启不用重拉；只有屏幕上看得到的封面才会去下载。
- **桌面的媒体卡片读本机文件**：`mpris:artUrl` 给的是封面缓存里的那个文件（`ArtworkCache.coverFileFor`），不是网络地址——桌面只管显示，不会替应用去抓图，地址取不到时卡片上就是一个空格。缓存的布局只有 `ArtworkCache` 知道。
- **Web 不再是目标平台**：Web 构建保留工程入口，但音乐库不落盘（`library_storage_stub.dart` 是空实现），曲目只在当前会话里；偏好仍走浏览器存储。
- **音乐库索引存在 SQLite**：桌面把索引写在 `<应用支持目录>/library/library.db`。首次启动时如果旧版的 `scanned_songs.json` 还在，会导入数据库并改名为 `.migrated`。索引和音源的扫描时间必须落在同一个存储里：只存扫描时间而不存索引，下次打开就会跳过所有音源，索引也就空了。
- **库按窗读取**：超过 1000 首时首帧只读第一窗，列表底部按需从 SQLite 取下一窗；保存是增量 upsert，写一窗不会删掉窗口外的行。
- **淘汰在数据库里完成**：设了「每来源最多保留」后，保存完新窗口就让 SQLite 按 `last_played`（最近播放）→ `play_count`（播放次数）→ `last_seen`（最近出现）→ `date_added` 排序，用窗口函数删掉超出上限的行；`pinned = 1` 的收藏完全不参与排名。全库不需要加载进内存来排序，几万到几十万行都能在数据库内裁剪。播放成功会写 `last_played`，扫描会更新 `last_seen`。
- **应用 id 定下来就别再改**：Linux 上应用支持目录名就是应用 id（`~/.local/share/<id>`），改 id 等于换了一个空目录，老数据不会再被读到。

## 音乐库的目录

app 写进磁盘的文件都放在**音乐库**里：平台自己的音乐目录（Linux `~/Music`、macOS / Windows `~/Music`、Android `/storage/emulated/0/Music`），也就是 `MusicScannerConfig.getDefaultMusicPaths()` 给的那几个。设置里可以改成别的目录（`library_folder` 偏好），默认就是音乐库。

目录的形状由 `LibraryPaths`（`lib/data/services/library/library_paths.dart`）说了算，别处不要自己拼路径：

```text
<音乐库>/
├── .tune/artwork/<哈希前两位>/<哈希>.img   # 只浏览过、没下载的曲目的封面
├── <歌手>/<专辑>/<歌名>/
│   ├── <歌名>.mp3                          # 下载的音频
│   ├── <歌名>.jpg                          # 封面
│   ├── <歌名>.lrc                          # 匹配到的歌词
│   ├── <歌名>.manual.lrc                   # 读者自己指定的歌词
│   └── <歌名>.tune                         # 副本标记：这首歌来自哪个音源
└── ...
```

- **一首歌一个目录**：音频、封面、歌词放在同一个目录里，别的播放器打开这个目录就知道这是一首歌。
- **副本标记**：app 下载的音频旁边放一个 `<歌名>.tune`，里面是这首歌的规范地址（`tune://<音源>/<曲目 id>`）。扫描时读到它，就知道这个文件是某首远程曲目的副本，而不是一首独立的曲子——于是音乐库里那首歌只有一条，同时标着「本地」和「在线」。
- **老副本要补标记**：app 是后来才写标记的，之前下载的副本旁边是空的。扫描之前，存储按曲目自己的目录找一遍这些副本，找到就补上标记（`SongDownloadService.markCopiesOf`），下一次扫描就能合成一条。
- 用户磁盘上已有的曲子不动，app 只把歌词写在它旁边（`<歌名>.lrc`），封面和音频不覆盖用户自己的文件。
  - 读者自己指定的歌词写进 `<歌名>.manual.lrc`，不覆盖读者已有的 `<歌名>.lrc`；读的时候先读读者指定的那一份。
- 目录名经过 `safeFileName`（`lib/utils/file_name.dart`）：路径分隔符和 Windows 不允许的字符被换掉，名字短到任何文件系统都收得下。
- 单个目录不放太多东西：曲目按歌手 / 专辑 / 歌名分层，封面缓存按哈希前两位分桶。
- 音乐库是 app 对磁盘上音乐的索引，属于 app 的数据；用户的音乐文件从不搬动。

## 曲目事实（track facts）

一首歌的已知信息只有一处来源，别处要标识就从这里取，不要自己拼一份。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/track_fact.dart` | 事实模型：名字、值、图标、色调、谁写的、是不是一段话 |
| `lib/shared/ui/track_facts.dart` | 文件类事实：位置、时长、格式、音质、码率、采样率、大小、媒体类型；来源编号 |
| `lib/shared/ui/track_metadata_facts.dart` | 元数据事实：专辑、年份、流派、音轨、碟片、语言、许可、歌词、演奏者、添加时间、简介、正在播放 |
| `lib/shared/ui/track_fact_strip.dart` | 行内标识条 |
| `lib/shared/ui/track_detail_sheet.dart` | 点击后的详情面板：事实、地址与写出来的正文 |
| `lib/shared/ui/track_addresses.dart` | 详情面板里的四条地址：本机文件路径、在线地址、封面地址、规范身份；各自的语气色与动作 |
| `lib/shared/ui/track_detail_block.dart` | 详情面板里写出来的正文：简介、歌词、原始数据、请求头 |
| `lib/shared/ui/meta_badge.dart` | `MetaChip`（带框的图标 chip，写着事实的主，名字在 tooltip 里）、`MetaBadge`（纯图标 + tooltip）与 `ChipGroup`（带着长值与动作的 chip 组） |
| `lib/shared/ui/icon_glyph.dart` | `IconGlyph`：密集行里的图标字形，只有一个 `RichText`，不带 `Icon` 的盒子；图标是装饰 |
| `lib/shared/ui/source_badge.dart` | `SourceBadge`：音源标识，纯图标 + tooltip，固定大小 |
| `lib/shared/ui/source_icon.dart` | 图标按类型查；目录里没有的类型按种类兜底 |
| `lib/shared/ui/favorite_button.dart` | `FavoriteButton`：红心，标与取消标；不是事实，是控件 |

同一份事实按三档呈现，读者想要多少信息就看到多少：

1. 列表行（曲库 / 队列 / 搜索结果）：只画图标，文字留给 tooltip。
2. 正在播放页：画图标 + 值，名字留给 tooltip。
3. 详情面板：事实排成 chip（chip 上写着事实的主，名字在提示气泡里），地址是 chip 组，简介、歌词、原始数据与请求头各写一块。

详情面板里的事实是一排 **chip**：一个事实一个 chip，图标说这是哪一个，颜色说它属于哪
一类，chip 上写着事实的**主**（时长、大小、格式、日期、位置），事实的名字在提示气泡
里。chip 排成几行，不排成一列——排成一列就是一张表，读起来比 chip 慢；语言写出来的词
有长有短，chip 的宽跟着主走，两三行是正常的。

有主副内容的事实，副也等在提示气泡里：音源的主是它叫自己的名字（`Wikimedia Commons`），
副是应用叫它什么（`自由授权媒体`）。

四条地址不写出来：地址比一行长，写出来就拉成一条。每条地址是一个 **chip 组**
（`ChipGroup`），两半连在一起，像按钮组那样是一个东西：宽的一半写自己的名字
（文件路径、在线地址、封面地址、规范身份），小的一半是动作。名字半穿它所属那一
类的语气色（文件路径是本机的，中性；两条远端地址是次色；规范身份是应用自己给它
的名字，三色），动作半穿外壳的强调色。动作按地址的种类来：本机的文件是**打开**
（桌面知道用什么程序打开它），远端的地址是**复制**。鼠标移上去才看见真正的地
址。地址写成读者写的样子：`file://` 与 `%20` 这类符号换成正常的写法
（`lib/shared/utils/readable_address.dart`）。

两样东西不是 chip：简介那样的一段话（`TrackFact.paragraph`）写出来，不进 chip——挤进
一个 chip 里会把整排 chip 撑变形；来源编号那样的**键**（`TrackFact.identifier`）只留一
个图标，键在提示气泡里——有的音源拿一整句话当键，它是查的东西，不是读的东西。

地址只有四处来源，都在 `Song` 上：`Song.localFile` 是本机的文件（没有就是空），
`Song.onlineAddress` 是播放用的网络地址（本地曲子没有），`Song.coverAddress` 是封面的地址
（远端是网络地址，本地是封面文件），`Song.identity` 是 app 认识这首曲目的名字（本地曲目的名字
就是它的路径，不另写一行）。详情面板不自己拼路径。

写出来的正文只有四处：简介、歌词、原始数据（音源给的整包数据）与请求头
（播放时带的头，带密钥的那一个只写三个点）。

**音源也一样**：行里只画一个固定大小的图标（`SourceBadge`），品牌名与本地化名都在 tooltip 里，详情面板的「来源」那条事实把它们写全。图标不随名字长短变形，一行曲子的宽窄不再被音源名字牵着走。

**喜欢不是事实，是控件**：红心（`FavoriteButton`）在行尾、队列、在线搜索的结果行、正在播放页的顶栏与底栏的播放卡片上，以及曲目详情面板的右上角，它自己就是那个动作，所以它不写进事实条。喜欢的状态只有一处来源——`FavoritesController`（`features/favorites`）——曲目模型里没有这一项。详情面板是共用的一段界面，它不认识「喜欢」这个概念，所以由调用它的人把状态和动作告诉它。

曲目的身份是它的地址（`Song.uri`）：本地曲子就是文件路径，在线曲目是 `tune://<音源>/<编号>`。重新扫描之后地址不变，所以标不会丢。

喜欢页是音乐库的一层视图：它列出库里被标过的曲子。标在库外的曲子——在线搜索里标了但还没扫进来的，或者音源关掉了——记在存储里，页面上列不出来。这种时候页头报的是标过的总数，页面上另起一行说明有几首不在库里，空状态也不会再说「还没有喜欢的曲子」。

## chip 的样子

全应用的 chip 只有一种写法：**图标说话，颜色说类别，主写在 chip 上，名字进 tooltip，细节进详情面板**。规范在 [chips.md](chips.md)，这里只列谁拥有什么。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/meta_badge.dart` | `MetaBadge`（纯图标 + tooltip）、`MetaChip`（带框的图标 chip，写着主）、`ChipGroup`（带着长值与动作的 chip 组）与事实的语气色 |
| `lib/shared/ui/source_badge.dart` | `SourceBadge`：音源标识，纯图标 + tooltip，固定大小 |
| `lib/shared/ui/source_mark.dart` | 图标按类型查；颜色按音源的类别（`sourceToneOf`） |
| `lib/shared/ui/live_badge.dart` | 直播标记，底栏与正在播放页共用一份 |
| `lib/shared/utils/readable_address.dart` | 地址写成读者读得懂的样子：去掉 `file://`，把 `%20` 写成空格 |

## 提示（tooltip）

界面上没写出来的说明只有一条路走，样子也只有一处定义。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/tune_tooltip.dart` | `TuneTooltip`：应用里用的提示名，等价于 `HintTrigger`（类型别名），没有文案就不显示 |
| `lib/shared/ui/hint_layer.dart` | `HintLayer`：全应用只有一张提示卡片 |
| `lib/shared/ui/hint_trigger.dart` | `HintTrigger`：提示的触发器，只说关键词、矩形与等待时间，不持有卡片 |
| `lib/app/theme/compact_theme.dart` | `tooltipTheme`：提示的样子——主题自己的一张卡片（`surfaceContainerHighest` + `onSurface` + `outline`，亮色是纸色卡片，暗色是深色卡片）、圆角、投影、停留时间 |

- widget 不直接用 `Tooltip`；图标按钮用 `TuneTooltip(message: ..., child: IconButton(...))`，两者走同一份主题。
- `HintLayer` 挂在 navigator 上面（`lib/app/app.dart`），卡片在 overlay 里读主题，所以主题切换时**还开着的提示也会当场换成新主题的卡片**；行里只装触发器，不装 `OverlayPortal`。`TuneTooltip` 与 `HintTrigger` 是同一个元素，不再套两层。
- 没有 `HintLayer` 的独立 widget 测试：`TuneTooltip` 退回 `RawTooltip`，行为一样。
- 提示文案走 l10n，不要写死。

## 底部浮层（sheet）

底部浮层只有一条路走：`lib/shared/ui/compact_sheet.dart` 的 `showCompactSheet`。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/compact_sheet.dart` | `showCompactSheet`：贴底、只占自己高度的浮层 |

- 浮层只占它自己的高度，窗口其余的地方留给遮罩，所以点浮层以外的地方（上方、左右都行）都能关掉它。浮层撑满窗口的话，空白的地方会把这些点击吃掉，读者只剩浮层两侧的窄条可以关。
- 浮层的高度有上限：内容比窗口高的时候，浮层自己在里面滚动，窗口上方始终留着 `CompactTokens.sheetBarrierGap` 的一截遮罩可以点。没有这一截，浮层就把遮罩盖满了，读者只能靠键盘关它。
- 宽度上限走 `CompactTokens.sheetWidth`，圆角走 `CompactTokens.sheetRadius`。

## 扩展路径

### 注册一个音源类型

1. 实现 `MusicSourceAdapter`：`lib/data/services/music_sources/music_source_adapter.dart`。
2. 在 `lib/data/services/music_sources/music_source_service.dart` 的注册表里注册这个 `type`。
3. 在 `lib/data/services/music_sources/source_type_catalogue.dart` 加一条：类型名、
   本地化名、一句说明、类别，以及它能不能被添加。
4. 要做成内置实例，再在 `lib/data/services/music_sources/built_in_music_sources.dart`
   加一条预置配置，名称走 `AppStrings`。
5. 在 `lib/l10n/*.arb` 补名称与描述（见 [i18n.md](i18n.md)）。
6. 品牌名音源还要补一条本地化名（chip 上的小字，见 `需求/多语言设计.md` 的「音源的两个名字」）。
7. 按需补 `test/app/localization_sources_test.dart` 的词汇。

播放器与音乐库 UI 不需要改：一个类型可以被多个实例共用，界面对实例一视同仁。

### 加一个页面 / 页签

1. 在 `features/` 下建包，按 domain → application → presentation 的顺序。
2. 在 `lib/app/router/app_router.dart` 注册路由；页签用 `sectionPage`，过渡由路由自己管。
3. 只接这一处新入口，不要顺着别人的页面改一圈。
4. 页面切换的动作交给路由：页面区不再另做一套切换（见「硬约束」第 6 条）。
5. 如果只是播放器的附属面板（例如播放队列），不要注册路由；用 `shared/ui/side_panel_host.dart` 在页面区内组合，见 [queue-panel.md](queue-panel.md)。

**页签的过渡属于路由，不属于 shell。** `go_router` 的导航器带着一个全局 key，
shell 里如果同时留着旧页签和新页签（`AnimatedSwitcher` + `KeyedSubtree`），
一棵树里就有两个同 key 的导航器：Flutter 会把树拆开一帧，屏幕上那一页当场少一块。
所以 shell 直接放路由给的 `child`，淡入淡出走 `CustomTransitionPage`。
`test/app/shell_page_switch_test.dart` 守着这条线。

### 加一条文案

见 [i18n.md](i18n.md)。
