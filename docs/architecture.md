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

## 状态归属

| 状态 | 唯一来源 | 职责 |
| --- | --- | --- |
| 播放 + 队列 | `PlaybackController` / `PlaybackState`（`features/player`） | 队列是 `PlaybackState` 的一部分，仓库里没有第二个队列容器 |
| 音乐库 | `LibraryController` / `LibraryState`（`features/library`） | 加载、扫描、过滤；不负责播放 |
| 设置 | `SettingsController` / `SettingsState`（`features/settings`） | 主题、语言、扫描目录、自动扫描 |
| 音源 | `MusicSourcesController` / `MusicSourcesState`（`features/sources`） | 音源开关与配置 |

- 状态只在 application 层修改；presentation 层只 `ref.watch` 读、`ref.read(...notifier)` 写。
- 纯逻辑下沉到 domain，I/O 下沉到 `data/services`；service 不依赖 Riverpod——`MusicSourceService` 是范例：它只编排 I/O，状态由 controller 持有。
- 播放副作用（统计、历史、通知）不写进 `PlaybackController` 的核心方法，由 app 级监听器订阅状态。

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
| 音乐库索引 | `<应用支持目录>/library/scanned_songs.json` | `LibraryStorage`（`lib/features/library/data/library_storage.dart`） |
| 下载的曲目 | `<音乐库>/<歌手>/<专辑>/<歌名>/<歌名>.<格式>` | `HttpSongDownloadService` |
| 封面图 | `<音乐库>/.tune/artwork/` | `FileArtworkCache`（`lib/data/services/impl/artwork_cache_io.dart`） |
| 歌词 | 曲目所在目录，`<歌名>.lrc` | `LyricsController` → `LibraryPaths` |
| 插件脚本 | `<应用支持目录>/music_plugins/` | `MusicPluginStore` |

- **一个偏好一个文件**：两个进程同时开 app 时各写各的，不会互相抹掉。旧的整份 JSON 存储已经换掉，老的数据由 `LegacyPreferenceMigration` 搬一次。
- **封面图落盘**：文件名是地址的稳定哈希，同一个地址只存一份，重启不用重拉；只有屏幕上看得到的封面才会去下载。
- Web 没有文件系统，偏好走浏览器存储（`preference_store_stub.dart`），封面每次现取。
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
│   └── <歌名>.lrc                          # 匹配到的歌词
└── ...
```

- **一首歌一个目录**：音频、封面、歌词放在同一个目录里，别的播放器打开这个目录就知道这是一首歌。
- 用户磁盘上已有的曲子不动，app 只把歌词写在它旁边（`<歌名>.lrc`），封面和音频不覆盖用户自己的文件。
- 目录名经过 `safeFileName`（`lib/utils/file_name.dart`）：路径分隔符和 Windows 不允许的字符被换掉，名字短到任何文件系统都收得下。
- 单个目录不放太多东西：曲目按歌手 / 专辑 / 歌名分层，封面缓存按哈希前两位分桶。
- 音乐库是 app 对磁盘上音乐的索引，属于 app 的数据；用户的音乐文件从不搬动。

## 曲目事实（track facts）

一首歌的已知信息只有一处来源，别处要标识就从这里取，不要自己拼一份。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/track_fact.dart` | 事实模型：名字、值、图标、色调 |
| `lib/shared/ui/track_facts.dart` | 文件类事实：位置、格式、音质、码率、采样率、大小 |
| `lib/shared/ui/track_metadata_facts.dart` | 元数据事实：专辑、年份、流派、音轨、碟片、语言、许可、歌词、收藏、演奏者、添加时间、简介、正在播放 |
| `lib/shared/ui/track_fact_strip.dart` | 行内标识条 |
| `lib/shared/ui/track_detail_sheet.dart` | 点击后的详情面板 |
| `lib/shared/ui/track_path_row.dart` | 详情面板里的文件路径与复制 |
| `lib/shared/ui/meta_chip.dart` | `MetaChip`（带文字）与 `MetaBadge`（纯图标 + tooltip） |

同一份事实按三档呈现，读者想要多少信息就看到多少：

1. 列表行（曲库 / 队列 / 搜索结果）：只画图标，文字留给 tooltip。
2. 正在播放页：画图标 + 值，名字留给 tooltip。
3. 详情面板：画图标 + 名字 + 值，并给出文件路径。

## 提示（tooltip）

界面上没写出来的说明只有一条路走，样子也只有一处定义。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/tune_tooltip.dart` | `TuneTooltip`：唯一的提示 widget，没有文案就不显示 |
| `lib/app/theme/compact_theme.dart` | `tooltipTheme`：提示的样子——主题自己的一张卡片（`surfaceContainerHighest` + `onSurface` + `outline`，亮色是纸色卡片，暗色是深色卡片）、圆角、投影、停留时间 |

- widget 不直接用 `Tooltip`；图标按钮用 `TuneTooltip(message: ..., child: IconButton(...))`，两者走同一份主题。
- 提示站在 `RawTooltip` 上，卡片在 overlay 里读主题，所以主题切换时**还开着的提示也会当场换成新主题的卡片**。
- 提示文案走 l10n，不要写死。

## 底部浮层（sheet）

底部浮层只有一条路走：`lib/shared/ui/compact_sheet.dart` 的 `showCompactSheet`。

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/compact_sheet.dart` | `showCompactSheet`：贴底、只占自己高度的浮层 |

- 浮层只占它自己的高度，窗口其余的地方留给遮罩，所以点浮层以外的地方（上方、左右都行）都能关掉它。浮层撑满窗口的话，空白的地方会把这些点击吃掉，读者只剩浮层两侧的窄条可以关。
- 宽度上限走 `CompactTokens.sheetWidth`，圆角走 `CompactTokens.sheetRadius`。

## 扩展路径

### 加一个音源

1. 实现 `MusicSourceAdapter`：`lib/data/services/music_sources/music_source_adapter.dart`。
2. 在 `lib/data/services/music_sources/music_source_service.dart` 的 `_adapters` 里注册。
3. 在 `lib/data/services/music_sources/built_in_music_sources.dart` 加条目，名称走 `AppStrings`。
4. 在 `lib/l10n/*.arb` 补名称与描述（见 [i18n.md](i18n.md)）。
5. 品牌名音源还要补一条本地化名（chip 上的小字，见 `需求/多语言设计.md` 的「音源的两个名字」）。
6. 按需补 `test/app/localization_sources_test.dart` 的词汇。

播放器与音乐库 UI 不需要改。

### 加一个页面 / 页签

1. 在 `features/` 下建包，按 domain → application → presentation 的顺序。
2. 在 `lib/app/router/app_router.dart` 注册路由。
3. 只接这一处新入口，不要顺着别人的页面改一圈。

### 加一条文案

见 [i18n.md](i18n.md)。
