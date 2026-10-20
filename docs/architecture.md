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
