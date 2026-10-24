# 发现与推荐功能设计

> 设计稿，未实施。评审通过后再按第 9 节分阶段落地。
> 最后更新：2026-10-24。
>
> 上位文档：[架构契约](architecture.md)、[音源设计](../需求/音源设计.md)、
> [队列模型方案](../需求/队列模型方案.md)、[代码约定](conventions.md)、
> [测试与验证](verification.md)。

## 1. 结论

新增一个一级页面「发现」，回答「现在听什么」，但**不做猜测式黑盒推荐**：

- 推荐只从**读者自己的音乐库**里挑，不额外请求音源接口，不建立云端画像；
  远程曲目的封面仍按现有缓存策略加载。
- 主要依据是**喜欢、曲目元数据**（歌手、流派、年代）和**读者自己的操作**
  （不感兴趣、撤销）。播放记录是**可选、默认关闭**的本地增强，不是前置条件。
- 每一张推荐卡都能说清「为什么是这首」；同一天、同一输入的结果稳定，
  可手动刷新；喜欢变化、扫描、反馈变化时重算。
- 发现页只做「挑出来给读者看」，播放、队列、喜欢、下载仍走现有链路，
  不新增第二套播放状态。

推荐默认值：

| 决策 | 默认 | 理由 |
| --- | --- | --- |
| 入口 | 侧栏新增「发现」页 | 有空间放推荐理由、分段和反馈；不挤占音乐库 |
| 启动页 | 仍是 `/library` | 不改变现有读者的打开习惯 |
| 推荐范围 | 只从音乐库挑，不请求音源接口 | 本地优先、可解释、无隐私成本 |
| 播放记录 | 默认关闭，读者主动开启 | 不把「听过什么」当成默认收集的数据 |
| 在线推荐 | 本版不做 | 平台推荐接口不稳定，且容易变成「应用替读者挑口味」 |
| 自动续播 | 不做 | 队列内容只由读者的显式动作决定，见队列方案 3.9 |

## 2. 目标与非目标

### 2.1 目标

1. 音乐库有几十首以上时，读者打开发现页就能看到可播的推荐，
   不需要先想关键词。
2. 推荐结果可解释：每个分段有一句依据，每首曲子有具体理由；没有依据时
   不假装有。
3. 推荐结果可纠正：不感兴趣立即生效，可撤销；清除记录后回到只依据喜欢
   和元数据的状态。
4. 不改变播放、队列、喜欢、音源、下载的既有语义；发现页只是这些状态的
   一个只读投影。
5. 在 900×600 默认窗口和 760×520 最小窗口下都不溢出，支持桌面字号缩放。

### 2.2 非目标

- 不做协同过滤、云端画像、账号体系或跨设备同步。
- 不做用户可见的「播放历史」页；第 6.2 节的播放记录只是本地计数器，
  没有时间线、没有曲名、默认关闭。
- 不做自动 DJ / 无限续播；不替读者改队列。
- 不做在线「每日推荐」聚合。音源平台自己的每日推荐已经在扫描时进入音乐库，
  发现页把它们当普通曲目看。
- 不因为推荐而把远程曲目写入音乐库；推荐结果只存在于内存。
- 不做「不重复（播完就停）」等新播放模式。

## 3. 现状与约束

### 3.1 现有状态归属

| 状态 | 现有所有者 | 发现页怎么用 |
| --- | --- | --- |
| 音乐库曲目 | `LibraryController` / `LibraryState` | 只读；推荐候选池 |
| 喜欢 | `FavoritesController` / `FavoritesState` | 只读；种子和每日混音的「熟悉」部分 |
| 播放 + 队列 | `PlaybackController` / `PlaybackState` | 只读；可选播放信号的来源；播放动作仍调它 |
| 音源配置 | `MusicSourcesController` / `MusicSourcesState` | 只读；给来源分段和来源标识取名字 |
| 偏好 | `SettingsController` / `SettingsState` | 只读；发现页开关、播放记录开关 |
| 音源扫描 | `MusicSourceService` + `LibraryController` | 不新增调用；推荐不触发扫描 |

发现页不复制这些状态，只保存**派生结果**（分段与排序）。派生结果可以随时
从输入重算，不是第二份事实来源。

### 3.2 与既有约束的关系

- **「播放历史已移出主链路」**：本设计不恢复历史页。可选的播放记录是
  `uri → 计数` 的聚合，不存曲名、不存时间线、默认关闭、可一键清除，
  只用于本地排序。读者不开启时，推荐仍然可用，只是理由更少。
- **「应用不替读者挑口味」**：推荐不写入音源的关键词，不改变扫描配置，
  不自动按歌手去远端搜索。它只利用读者已有的库和显式喜欢。
- **单一事实来源**：喜欢仍只有 `FavoritesController`，播放仍只有
  `PlaybackController`；发现页不新增喜欢或播放状态的副本。
- **依赖方向**：`discovery/presentation → discovery/application → domain`；
  `application` 可以读别的 feature 的 application / domain，但不读别人的
  presentation。发现页的曲目卡不复用 `LibraryTrackCard`，避免
  `discovery/presentation → library/presentation` 的反向依赖。

### 3.3 三个必须先说清的事实

1. **没有歌手 / 专辑实体**。只有 `Song.artist`、`Song.album` 字符串。
   推荐按规范化后的字符串分组，不新建全局歌手表。
2. **`Song.dateAdded` 目前是「最近一次扫描看到的时间」，不是「首次入库时间」**。
   `SongCreator` 和 `SourceSongFactory` 每次都写 `DateTime.now()`，
   `Song.mergeWith` 也不保留旧值。直接拿它做「刚入库」会每天把整库都算成新的。
   本设计把它列为前置修正（第 7.7 节），在修正前不实现「刚入库」分段。
3. **队列历史不是播放历史**。`PlaybackState.history` 只记录当前队列里
   最近切过的曲目，换队列就清空，恢复时还会按当前队列过滤；
   不能拿它当推荐信号。需要信号时另建聚合存储（第 6.2 节）。

## 4. 方案对比

### 方案 A：独立「发现」页（推荐）

在侧栏「浏览」分组新增 `/discover`，页面由若干推荐分段组成，
每段有理由、播放全部、加入队列和不感兴趣。

- 优点：空间足够；推荐理由和反馈有地方放；不干扰音乐库的搜索 / 筛选；
  将来加在线分段或更多推荐类型时只接新分段。
- 缺点：多一个一级入口；需要新页面、路由、文案和布局测试。

### 方案 B：音乐库顶部「为你推荐」条

在 `LibraryPane` 的工具栏和列表之间插一条横向推荐。

- 优点：不增加导航；读者打开音乐库就能看到。
- 缺点：音乐库已经有搜索、来源筛选、扫描状态和整列表入队，顶部再叠一层
  会更挤；推荐理由、反馈和「换一批」没有空间；推荐和库列表的滚动会互相干扰。
  也不适合以后扩展成多分段。

### 方案 C：自动续播 / 无限电台

当前队列播完后自动追加相似曲目。

- 优点：最贴近「一直有音乐」；不需要新页面。
- 缺点：直接改变队列语义，和队列方案「队列内容只由读者显式动作决定」
  冲突；读者很难预期下一首从哪来；需要更重的播放信号和冷却规则。
  本版不做。

### 方案 D：在线每日推荐聚合

打开页面时拉取各音源的每日推荐 / 排行 / 最新，聚合成一个列表。

- 优点：内容新鲜，冷启动容易。
- 缺点：依赖外部接口和账号；网易云每日推荐需要自建服务且未验证；
  无词浏览流会把「平台榜单」当成「为你推荐」；网络失败会让整页不可用；
  也容易变成应用替读者挑口味。可作为后续独立分段，不作为 v1 的主链路。

**选择 A。** 它把「推荐」限制在一个只读页面里，失败或不喜欢时可以整页退场，
不影响音乐库和播放器。

## 5. 产品设计

### 5.1 入口与导航

- 路由：`/discover`，`ShellRoute` 内，与 `/library`、`/favorites` 同级。
- 侧栏：「浏览」分组，顺序为 **发现 / 音乐库 / 喜欢**；图标用
  `Icons.explore_rounded` 或 `Icons.auto_awesome_rounded`，文案进 ARB。
- 启动位置仍是 `/library`，不把发现页设成首页。
- 旧深链接仍然回落到 `/library`；`/discover` 是新增合法路径。

### 5.2 页面结构

默认窗口 900×600，内容区约 555 宽。页面整体纵向滚动，分段内部横向滚动。

```text
┌ 发现 ─────────────────────────────────────────────────────┐
│ DISCOVER                                                  │
│ 今天听什么                                                │
│ 从你的音乐库和喜欢的曲目里挑的 · 只在本机计算      [↻] [i] │
│                                                           │
│ ┌ 今日混音 · 25 首 ─────────────────────────── [播放] ─┐ │
│ │ [封面拼贴]  熟悉的 + 新发现的                       │ │
│ │             根据你喜欢的 Nujabes、Jazz 和刚标心的歌  │ │
│ │             1. ...  2. ...  3. ...                  │ │
│ └───────────────────────────────────────────────────────┘ │
│                                                           │
│ 因为你喜欢 Nujabes                              [i] [更多] │
│ [卡片] [卡片] [卡片] [卡片] →                              │
│                                                           │
│ 换个口味：Jazz                                  [i] [更多] │
│ [卡片] [卡片] [卡片] [卡片] →                              │
│                                                           │
│ 刚入库                                          [i] [更多] │
│ [卡片] [卡片] [卡片] [卡片] →                              │
│                                                           │
│ 来自 Jamendo                                    [i] [更多] │
│ [卡片] [卡片] [卡片] [卡片] →                              │
└───────────────────────────────────────────────────────────┘
```

- 页头用现成的 `PageHeading`；`[↻]` 是刷新，`[i]` 打开「怎么推荐」说明浮层。
- 分段标题右侧的工具按钮只在悬停或键盘聚焦时出现，避免每段都有三个常驻按钮。
- 卡片宽度约 120，封面 112；900 宽时一行约 3–4 张，760 宽时约 3 张，
  多出的横向滚动。标题两行、歌手一行；卡片只给最小高度，字号放大时随内容
  长高，不裁字。
- 横向列表的容器按当前字号的卡片最小高度给空间；不写死像素高度。
- 分段之间用 `CompactTokens` 的间距，不新造尺寸。
- 页面只使用 `CompactSpinner`、`TuneTooltip`、`ArtworkThumb`、`FavoriteButton`、
  `SourceBadge`、`showTrackDetailSheet` 等共享件；曲目卡放在发现页自己的
  presentation 下，不 import 音乐库的 presentation。

### 5.3 分段

| 分段 | 内容 | 出现条件 | 默认数量 |
| --- | --- | --- | --- |
| 今日混音 | 标心的曲目（最多 20%）+ 新发现，按天稳定 | 候选 ≥ 5 | 25 |
| 因为你喜欢 X | 某位高权重歌手的未标心的曲目 | 该歌手有 ≥ 3 首候选，最多 2 段 | 8 / 段 |
| 换个口味 | 非头部流派或非头部歌手的探索曲目 | 有足够候选 | 8 |
| 刚入库 | 首次入库时间最近的曲目 | 前置修正完成且有候选 | 8 |
| 来自 X | 某个音源在库里的未标心的曲目 | 该来源有 ≥ 5 首候选，最多 2 段 | 8 |

- 全页去重：同一 `uri` 最多出现一次；优先级按上表从上到下。
- 小库时后面的分段可能被前面的分段吃空，这是预期；宁可少一段，也不重复凑数。
- 喜欢的曲目只允许出现在「今日混音」的熟悉部分和「刚入库」；不再出现在
  「因为你喜欢」「换个口味」「来自 X」，避免推荐的全是已经标心的歌。
- 直播流（`isLiveStream`）不参与任何推荐：没有固定时长，也没有「听完」的概念。
- 音乐库里被当前来源筛选或搜索词过滤掉的曲目**仍然参与**推荐；发现页不继承
  音乐库的临时筛选。
- 来源名不写死：用 `sourceLabelsOf` 从音源配置取名字；取不到名字的来源不分段。
  来源分段的顺序按音源配置的 `weight` 排，不按 id 或库里的出现顺序。

### 5.4 交互

| 动作 | 结果 |
| --- | --- |
| 单击卡片 | 走 `ListPlayback.play(song)`：设置里「单击替换队列」打开时替换，否则入队并立即播放 |
| 双击卡片 | 与音乐库一致：默认播放并标心；设置「双击只标心」打开时只标心 |
| 卡片红心 | `FavoritesController.toggle`，不改变播放 |
| 分段「播放」 | `PlaybackController.playQueue(该段曲目)`，显式替换队列 |
| 分段「加入队列」 | `PlaybackController.addAllToQueue(该段曲目)`，已在队列里的跳过，提示新增条数 |
| 卡片菜单「加入队列」 | 单曲 `addToQueue` |
| 卡片菜单「不感兴趣」 | 从发现页移除，写入本地反馈；底部提示可撤销 |
| 卡片菜单「查看详情」 | `showTrackDetailSheet` |
| 页头刷新 | 重算本地分段；今日混音换一个本会话的盐值 |
| 页头说明 | 打开「怎么推荐」浮层：用了哪些信号、数据在哪、怎么清除 |
| 空状态「扫描音乐」 | 跳转 `/library`；扫描仍由库页现有的扫描按钮触发，发现页不直接调扫描 |
| 空状态「连接音源」 | 跳转 `/sources` |

- 「不感兴趣」只影响发现页，不隐藏音乐库里的曲目，不取消红心，不停止播放。
- 撤销只撤销这一条反馈，不重算整页；如果该分段已空，撤销后恢复。
- 所有图标按钮走 `TuneTooltip`，所有文案走 ARB。

### 5.5 空状态、加载与错误

| 状态 | 页面 |
| --- | --- |
| 音乐库加载中 | `CompactSpinner.large()` 居中 |
| 音乐库为空 | `EmptyStateView`：标题「音乐库还是空的」，副标题「扫描本地音乐或连接一个音源，发现页才有东西可挑」，动作「扫描音乐」「连接音源」 |
| 音乐库加载失败 | `EmptyStateView` + 重试（invalidate `libraryControllerProvider`） |
| 有库但没有可推荐候选（全部不感兴趣 / 可用候选不足 5 首） | 标题「能推荐的都听过了」，副标题「去音乐库逛逛，或清掉不感兴趣」，动作「去音乐库」「清除反馈」 |
| 播放记录关闭 | 页头下方一条轻提示：「开启本地播放记录，推荐会更贴近你」+「开启」「了解」；可关闭 |
| 推荐计算异常 | 不把整页打崩：保留能算出的分段，页头显示一行错误 + 重试；全部失败才用空状态 |

### 5.6 设置

设置页新增「发现」分组，卡片放在独立文件
`lib/features/settings/presentation/settings_discovery_card.dart`，不继续
把 `settings_cards.dart` 撑大。

| 项 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| 本地播放记录 | 开关 | 关 | 只保存在本机，用来改善推荐；关闭后不再记录，推荐仍可用 |
| 清除推荐记录 | 按钮 | — | 删除播放记录和「不感兴趣」标记；不影响喜欢、音乐库、播放队列 |

- 开关文案必须写清「只在本机」「不影响喜欢」。
- 清除前弹确认框；清除后重算，若页面正打开则立即刷新。清除动作直接调用
  `ListeningSignalStore.clear` 与 `DiscoveryFeedbackStore.clear`，再
  `ref.invalidate(discoveryControllerProvider)`；不依赖页面控制器是否还活着。
- 设置页不提供「推荐数量」「推荐算法权重」这类调参项，避免把产品做成仪表盘。

## 6. 推荐模型

### 6.1 总体流程

```text
音乐库 + 喜欢 + 可选播放记录 + 不感兴趣
        │
        ▼
   TasteProfile（纯函数）
        │
        ▼
   候选过滤（去重、排除直播、排除不感兴趣）
        │
        ▼
   打分 + 多样性选择 + 全局去重
        │
        ▼
   DiscoveryState（分段 + 理由）
        │
        ▼
   DiscoveryPane（只读，负责文案与交互）
```

整个计算是同步纯函数，不碰网络、不碰磁盘；I/O 只在读取信号存储时发生。

### 6.2 信号

#### 基础信号（不额外收集）

| 信号 | 来源 | 强度 |
| --- | --- | --- |
| 喜欢 | `FavoritesState.ids` | 强正，3.0 |
| 喜欢的曲目中的歌手 | `Song.artist` | 由喜欢推导 |
| 喜欢的曲目中的流派 | `Song.genre` / `Song.genres` | 由喜欢推导，1.5 |
| 喜欢的曲目中的年代 | `Song.year` | 由喜欢推导，1.0 |
| 不感兴趣 | `DiscoveryFeedbackStore` | 强负，直接排除 30 天 |

#### 可选信号（默认关闭）

| 信号 | 来源 | 强度 |
| --- | --- | --- |
| 听完 | 可选观察器 | 1.0 / 次，45 天半衰 |
| 跳过 | 可选观察器 | -0.5 / 次，45 天半衰 |
| 最近听过的曲目 | 同上 | 近期降权，避免连续重复 |

播放记录只存聚合，不存时间线：

```json
{
  "version": 1,
  "tracks": {
    "tune://jamendo/123": {
      "listens": 3,
      "skips": 1,
      "listenedMs": 540000,
      "lastListenedAt": 1760000000000
    }
  }
}
```

- 键是 `Song.uri`，不是曲名；远程地址刷新不会丢信号。
- 最多保留 2000 条，按 `lastListenedAt` 淘汰最旧。
- 观察器只读 `PlaybackController` 的公开状态，不修改播放控制器：
  记录切歌前的 `position`，达到阈值算一次「听完」，没达到算「跳过」；
  阈值是 `min(45s, 时长 × 50%)`，时长未知时用 45 秒；直播流不记录。
- 只在前一首处于播放状态时结算；恢复会话后一直暂停、或读者主动暂停后切歌，
  都不算跳过。达到阈值但没播完也记一次「听完」。
- 写在应用级观察器里（`AppInitializer` 启动），不塞进 `PlaybackController`
  的核心方法；关闭开关后不再写，已有记录保留到读者点「清除」。
- 存储损坏、版本不认识、读取失败都当作空信号，不挡住发现页。

### 6.3 口味画像

`TasteProfile` 只保存归一化后的权重，不保存曲目列表：

```dart
class TasteProfile {
  final Map<String, double> artists; // 规范化歌手名 → 0..1
  final Map<String, double> genres;  // 规范化流派名 → 0..1
  final Map<int, double> decades;    // 1970 / 1980 … → 0..1
  final int favoriteCount;
  final int listenCount;

  factory TasteProfile.from({
    required List<Song> library,
    required Set<String> favoriteUris,
    Map<String, TrackListening> listening = const {},
  });

  bool get isEmpty => artists.isEmpty && genres.isEmpty && decades.isEmpty;
}
```

- 歌手名、流派名做 `trim().toLowerCase()` 后作为键；展示时用曲目里的原值，
  流派再用 `genreLabel` / `genresLabel` 翻译（见 [流派本地化](genre-localization.md)）。
  流派优先读 `genres` 列表，为空时回退到 `genre`；`year` 为 0 或空时不参与年代。
- 喜欢权重不衰减；播放权重按 45 天半衰；跳过只扣到 0 为止，不产生负分。
- 每个维度除以该维度的最大值归一化；没有信号的维度不参与打分。
- 喜欢页里标了但不在库里的曲目没有 `Song`，不参与画像；等它进入音乐库后
  自动生效。这是现有「库外的喜欢」语义的自然结果。

### 6.4 候选与过滤

- 候选 = `LibraryState.songs`，不额外请求网络。
- 过滤掉：`uri` 为空、直播流、已不感兴趣且未过期、以及本轮已经选过的 `uri`。
- 同一 `uri` 在库里已经由 `LibraryController` 合并成一条（本地副本 + 在线来源），
  发现页不再做第二次合并。
- 跨来源的同一录音如果 `uri` 不同（例如同一首歌在两个音源各有一条），
  v1 不合并：它们本来就是两条不同的来源记录，合并需要标题/时长/版本判断，
  容易把现场版和录音室版混在一起。
- 来源分段的候选只取 `sourceId != null && sourceId != 'local'` 的曲目。

### 6.5 打分

对一个有画像的读者，候选曲目 `s` 的分数：

```text
score(s) =
    0.40 * artistAffinity(s)
  + 0.25 * genreAffinity(s)
  + 0.15 * eraAffinity(s)
  + 0.10 * novelty(s)          // 没听过 / 听得少
  + 0.10 * freshness(s)        // 首次入库越近越高，前置修正后才启用
  - 0.15 * recentPenalty(s)    // 最近听过，且开启播放记录
```

- 某个维度没有信号时，该维度权重按剩余维度重新归一化，避免「没有流派」
  的库被硬压成低分。
- `novelty`：没有播放记录时按「未标心」给 1.0；有记录时按 `listens` 递减，
  最低 0.2。
- `freshness`：30 天线性衰减到 0；没有可靠的首次入库时间时不参与。
- `recentPenalty`：最近 7 天听过 1.0，7–30 天线性衰减到 0；只在播放记录开启时。
- 今日混音预留最多 20% 的「熟悉锚点」给标心的曲目，名额内优先选最久没听的
  （未标心候选不足 5 首时例外）；其他分段直接排除已标心的曲目。
- 分数相同用 `fnv1a(uri + 每日种子)` 稳定排序，不依赖 `Random` 的运行时状态。

### 6.6 多样性与去重

- 每个分段内：同一歌手最多 2 首，同一专辑最多 2 首；今日混音可放宽到
  同一歌手 3 首、同一专辑 2 首。
- 全页去重：一首曲子只出现一次；分段按第 5.3 节的优先级消费候选。
- 没有专辑名（空字符串）时不按专辑限流，避免把所有无专辑曲目算成同一张。
- 歌手名规范化后为空（本地文件没有标签）时不建立「因为你喜欢」分段，
  也不因为空歌手聚成一堆。

### 6.7 分段生成

#### 今日混音

1. 先按分数选未标心的曲目，目标 25 首。
2. 如果标心的曲目 ≥ 1，替换其中最多 20% 为喜欢的曲目，优先选最久没听的
   （没有播放记录时按稳定哈希取）。
3. 对预计会单独成段的头部歌手（见下一节），今日混音最多取 1 首，
   把其余候选留给「因为你喜欢 X」；避免小库时后一段刚出现就被吃空。
4. 用歌手/专辑上限做贪心选择；不够 5 首就不出这个分段，改用「从音乐库挑的」
   兜底分段。
5. 如果未标心候选不足 5 首，取消 20% 上限，直接从标心的曲目里选，理由统一为
   `favorite`；这时页面说的是「从你标心的歌里挑的」，不假装是发现。
6. 种子：`fnv1a(dateKey + profileSignature + librarySize + refreshSalt)`。
   `dateKey` 是本地日期（`yyyy-MM-dd`）；`profileSignature` 是头部歌手/流派
   权重量化后的串；`refreshSalt` 只在本会话内递增，重启回到当天的稳定结果。
   同一天同一输入的结果稳定；喜欢变化、扫描、反馈变化时结果会跟着重算，
   这是有意的。刷新只在本次停留期间有效，重新进入页面回到当天的稳定结果。

#### 因为你喜欢 X

- 取画像里权重最高的 2 位歌手，要求各自有 ≥ 3 首未标心候选。
- 每段 8 首，按分数排序，应用歌手/专辑上限。
- 标题用歌手原名；理由种类是 `artist`，由界面翻译，不在状态里拼字符串。
- 某位歌手的候选不足 3 首就跳过，不硬凑。

#### 换个口味

- 优先选画像里**非前二**的流派；没有足够流派时选「非前二歌手」的曲目。
- 画像为空时不装作有口味：这一段退化为「换换耳朵」，从不同歌手、
  不同专辑里做稳定抽样；仍然保持歌手/专辑上限。
- 目标是「和日常口味相邻但不同」：同流派不同歌手，或不同流派但同年代。
- 8 首；如果候选不足 3 首，整段隐藏。
- 标题由理由决定，例如「换个口味：Jazz」或「换换耳朵」；不写「探索未知」
  这种空话。

#### 刚入库

- 依赖第 7.7 节的首次入库时间修正；未修正前不出现。
- 取最近 30 天首次入库的曲目，按时间倒序，排除已不感兴趣；8 首。
- 喜欢的曲目可以出现：这是「新到的东西」，不是「猜你喜欢」。

#### 来自 X

- 按 `sourceId` 分组，保留候选 ≥ 5 首的来源，最多 2 段。
- 每段 8 首，优先未标心、没听过的曲目；同歌手/专辑上限仍然生效。
- 来源顺序沿用音源配置里的权重顺序；来源名从 `sourceLabelsOf` 取，
  不按 id 硬编码。
- 这是「把你已经连上的音源再翻一遍」，不是平台实时榜单；文案不要写成
  「每日推荐」。

### 6.8 推荐理由

状态里只放结构化理由，界面负责翻译：

```dart
enum RecommendationReasonKind {
  favorite,
  artist,
  genre,
  era,
  fresh,
  unheard,
  source,
  fallback,
}

class RecommendationReason {
  final RecommendationReasonKind kind;
  final String? artist;
  final String? genre;
  final int? decade;
  final String? sourceId;
  final double confidence;
}
```

| 种类 | 什么时候用 | 界面文案示例 |
| --- | --- | --- |
| `favorite` | 今日混音里的熟悉锚点 | 你标了心 |
| `artist` | 歌手贡献最大 | 因为你喜欢 Nujabes |
| `genre` | 流派贡献最大 | 你喜欢 Jazz |
| `era` | 年代贡献最大 | 回到 2000 年代 |
| `fresh` | 首次入库新 | 刚入库 |
| `unheard` | 没听过且无更强信号 | 还没听过 |
| `source` | 来源分段 | 来自 Jamendo |
| `fallback` | 没有可靠信号 | 从你的音乐库挑的 |

- 只有播放记录开启且达到阈值时才用「常听」「最近常听」；只靠喜欢时用
  「你喜欢」，不虚构收听行为。
- 每张卡片的理由放在 `TuneTooltip` 里；分段标题下写一句总依据。
- 页头 `[i]` 打开说明浮层，列出「用了喜欢 / 播放记录 / 不感兴趣」和
  「只在本机计算」，并提供「清除推荐记录」。

### 6.9 冷启动

| 情况 | 页面表现 |
| --- | --- |
| 空库 | 扫描 / 连接音源空状态 |
| 有库、无标心、无播放记录 | 今日混音（全部未标心）+「换换耳朵」+「刚入库」（前置修正后）；不出现「因为你喜欢」；顶部提示「标几首喜欢的歌，推荐会更准」 |
| 有喜欢的曲目、无播放记录 | 今日混音 + 1–2 个歌手分段 + 换个口味；理由只用标心与元数据 |
| 只有 1–4 首候选 | 不硬凑分段：显示「从音乐库挑的」小列表 + 去音乐库入口 |
| 全部候选被标心 | 今日混音取消 20% 上限，从标心的曲目里选；提示「去音乐库标几首别的歌」 |
| 全部候选被不感兴趣 | 空状态 + 清除反馈 |

### 6.10 反馈与撤销

- `DiscoveryFeedbackStore` 存 `uri → { kind, createdAt }`，默认 30 天过期。
- v1 只有 `notInterested` 一种；「少推荐这位歌手」留到后续，避免一次做出
  两级黑名单。
- 「不感兴趣」只出现在未标心卡片上；已标心的曲目要先去红心，避免「标了心又拉黑」。
  如果读者之后又把某首标心，顺手清掉它的不感兴趣记录。
- 读取时顺手清理过期记录；写入后立即从当前分段移除并重算该段。
- 撤销删除对应记录并重算；不做「全局撤销栈」。
- 清除推荐记录同时清空反馈和播放记录；不影响喜欢。

## 7. 架构设计

### 7.1 目录

```text
lib/features/discovery/
├── domain/
│   ├── discovery_state.dart          # 页面状态：加载 / 分段 / 错误
│   ├── discovery_section.dart        # 分段模型
│   ├── recommended_track.dart        # 曲目 + 分数 + 理由
│   ├── recommendation_reason.dart    # 结构化理由
│   ├── taste_profile.dart            # 画像构建（纯函数）
│   ├── recommendation_engine.dart    # 打分、选曲、去重（纯函数）
│   └── track_listening.dart          # 聚合播放信号模型
├── application/
│   ├── discovery_controller.dart     # 编排输入、调用引擎、状态
│   └── discovery_signal_observer.dart# 应用级播放观察器（可选）
├── data/
│   ├── listening_signal_store.dart   # 播放记录 JSON
│   └── discovery_feedback_store.dart # 不感兴趣 JSON
└── presentation/
    ├── discovery_pane.dart           # 页面骨架与输入装配
    ├── discovery_section_view.dart   # 分段标题 + 横向列表
    ├── daily_mix_card.dart           # 今日混音大卡
    ├── recommendation_card.dart      # 方形曲目卡
    ├── discovery_reason_label.dart   # 理由 → 文案
    └── discovery_empty_state.dart    # 空 / 无候选 / 失败
```

新增文件都控制在 200 行内；`discovery_pane.dart` 只做装配，分段和卡片各自
拆文件。`settings_discovery_card.dart` 放在设置 feature 下，避免设置页
import 发现页的 presentation。

### 7.2 依赖方向

```text
DiscoveryPane
  └── DiscoveryController
        ├── LibraryController        （只读）
        ├── FavoritesController      （只读）
        ├── SettingsController       （只读）
        ├── MusicSourcesController   （只读来源 id 顺序）
        ├── ListeningSignalStore     （可选，只读）
        ├── DiscoveryFeedbackStore   （读写反馈）
        └── RecommendationEngine     （纯函数）

DiscoverySignalObserver
  ├── PlaybackController             （只读公开状态）
  ├── SettingsController             （是否记录）
  └── ListeningSignalStore           （只写聚合）

RecommendationEngine
  └── Song + TasteProfile            （无 I/O、无 Flutter、无 Riverpod）
```

- `domain/` 不 import `features/`、`app/`、`shared/ui/`、Riverpod。
- `application/` 可以 import 其他 feature 的 `application` / `domain`，
  不 import 任何 `presentation`。
- `presentation/` 只 import 本 feature 的 application / domain 与
  `shared/ui`；来源名通过 `sourceLabelsOf` 从音源 application 取，
  这是现有的跨 feature 读法，和音乐库一致。
- 不修改 `PlaybackController`、`LibraryController`、`FavoritesController`、
  `MusicSourceService` 的核心语义；第 7.7 节的 `dateAdded` 修正除外。

### 7.3 状态归属

| 状态 | 所有者 | 生命周期 |
| --- | --- | --- |
| 推荐分段 / 排序 | `DiscoveryController` | 页面级，离开即释放，可重算 |
| 播放聚合 | `ListeningSignalStore` | 持久化，读者可清除 |
| 不感兴趣 | `DiscoveryFeedbackStore` | 持久化，30 天过期 |
| 喜欢 | `FavoritesController` | 不变 |
| 音乐库 | `LibraryController` | 不变 |
| 播放 / 队列 | `PlaybackController` | 不变 |
| 发现开关 | `SettingsController` | 持久化 |
| 来源顺序 | `MusicSourcesController` | 不变，只读 |

发现页不把 `Song` 列表另存一份到磁盘；分段是派生视图，不是事实来源。

### 7.4 控制器

`DiscoveryController` 用 `AutoDisposeAsyncNotifier<DiscoveryState>`，
与在线搜索的临时面板同一模式：

- `build` 读取 `LibraryController` 的 `(isLoading, hasValue, songs)`、
  `FavoritesState.ids`、来源 id 顺序、设置开关和反馈存储，构建画像并计算分段。
- 用 `select` 只订阅需要的切片，避免扫描进度每变一次就重算：
  `ref.watch(libraryControllerProvider.select((v) => (v.isLoading, v.valueOrNull?.songs)))`。
- 不 watch 整个 `MusicSourcesController`；只 select 来源 id 的当前顺序
  （配置里已按 `weight` 排好）传给引擎，来源名由 presentation 取。
- 反馈写入后立即重算并更新状态；撤销同理。
- 反馈与播放记录在 controller 生命周期内只读一次盘，写入后同步内存副本；
  喜欢切换导致的重算不重复读盘。
- `refresh()` 递增会话内的 `_salt`，重算；不写盘。
- 计算异常记录日志并返回可用的空状态，不让页面抛红屏。
- 不持有 `BuildContext`，不读 `context.loc`；错误用 `DiscoveryFailure`
  枚举，推荐理由用结构化模型，翻译全部留给 presentation。

### 7.5 播放观察器

- `AppInitializer` 在持久化、播放器初始化后启动
  `discoverySignalObserverProvider`；它内部 `ref.listen` 设置开关，
  读者后来打开开关也能生效。
- 观察器只监听 `PlaybackController` 的状态变化；在 `currentUri` 变化时
  读取上一首的 `position` / `duration` / `status`，结算一次。
- 写入合并后延迟落盘（例如 5 秒 debounce），应用退出时 flush；
  单次写失败只记日志，不影响播放。
- 关闭开关后不再写；不清除已有数据，清除由设置里的按钮负责。

### 7.6 持久化

| Key | 内容 | 谁写 | 何时 |
| --- | --- | --- | --- |
| `discovery_listening_v1` | 聚合播放记录（可选） | `ListeningSignalStore` | 观察器结算后 |
| `discovery_feedback_v1` | 不感兴趣标记 | `DiscoveryFeedbackStore` | 读者点「不感兴趣」/ 撤销 |
| `discovery_use_listening_history` | 开关 | `SettingsController` | 设置页 |
| `discovery_hint_dismissed` | 是否关掉「开启记录」提示 | `SettingsController` | 读者点关闭 |

- 两个 JSON 都带 `version`；版本不认识时按空处理，不迁移、不猜测。
- 写入失败只记日志；发现页仍可用。
- 不缓存推荐结果到磁盘；没有「推荐缓存」这个第三份状态。

### 7.7 前置修正：`dateAdded` 的语义

当前 `dateAdded` 每次扫描都会变成 `DateTime.now()`，所以它不能表达
「首次入库」。推荐里的「刚入库」依赖这个语义。建议在实现发现页之前做一次
小修正：

- 在 `LibraryController` 把扫描结果写回库时，按 `uri` 取上一版曲目：
  同一个 `uri` 保留**较早**的 `dateAdded`；新曲目才用本次扫描的时间。
- 这是唯一一处规则；`Song.mergeWith` 不另写一份时间规则。
- 详情面板「添加时间」随之变成真正的首次入库时间。
- 测试：同一库连扫两次，`dateAdded` 不变；新增曲目拿到新时间；
  远程曲目地址刷新不改变 `dateAdded`。

已经存在的库没有历史首次入库时间，修正后只能从「修正时的上一次扫描时间」
开始保留；不会凭空补出几年前的入库时间。这比继续每天重置要准确，文档和
详情面板都不承诺更早的时间。

如果评审不想动音乐库，发现页 v1 就**不出现「刚入库」分段**，其余分段不受影响。
这是一个可单独决策的前置项，不阻塞发现页主体。

### 7.8 性能

- 打分是 O(n) 一次遍历 + 每段 O(k·n) 的贪心选择；k 是分段数量，n 是库大小。
  目标：1 万首曲目在桌面端 100ms 内算完；先用同步计算，实测超限再考虑
  `Isolate.run`，不提前引入并发。
- 页面只在打开时计算；离开后 `AutoDispose` 释放。
- 不做后台轮询，不监听扫描进度，不为推荐单独触发网络。
- 卡片封面走现有 `ArtworkThumb` 的缓存；横向列表用 `ListView.builder`。

## 8. 数据模型

```dart
class DiscoveryState {
  final bool isLoading;
  final List<DiscoverySection> sections;
  final DiscoveryFailure? failure; // 枚举，由界面翻译
  final DateTime? generatedAt;
  final String? dateKey;        // yyyy-MM-dd，用于判断是否跨天
}

enum DiscoveryFailure { libraryUnavailable, computationFailed }

class DiscoverySection {
  final DiscoverySectionKind kind;
  final RecommendationReason reason;
  final List<RecommendedTrack> tracks;
}

class RecommendedTrack {
  final Song song;
  final double score;
  final RecommendationReason reason;
  final bool fromFavorites;
}

enum DiscoverySectionKind { dailyMix, artist, explore, fresh, source, fallback }
```

- `failure` 只用于错误状态；分段标题、空状态和卡片理由都由 presentation
  按当前语言拼，不在状态里存翻译后的字符串。
- `RecommendedTrack` 持有 `Song` 引用，不复制字段；音乐库刷新后旧引用
  随状态一起重算。
- 分段顺序稳定：`dailyMix → artist → explore → fresh → source → fallback`。

### 8.1 引擎接口

```dart
class RecommendationEngine {
  const RecommendationEngine();

  DiscoveryOutput recommend({
    required List<Song> library,
    required Set<String> favoriteUris,
    required TasteProfile profile,
    required Set<String> dismissedUris,
    required List<String> sourceOrder,
    required String dateKey,
    int refreshSalt = 0,
    bool allowFresh = false,
  });
}
```

`DiscoveryOutput` 只含分段和理由，不含 Flutter 类型；测试直接构造 `Song`
和画像，不启动 Riverpod、不读写磁盘。

## 9. 影响范围与实施计划

### 9.1 新增文件

```text
lib/features/discovery/domain/discovery_state.dart
lib/features/discovery/domain/discovery_section.dart
lib/features/discovery/domain/recommended_track.dart
lib/features/discovery/domain/recommendation_reason.dart
lib/features/discovery/domain/taste_profile.dart
lib/features/discovery/domain/recommendation_engine.dart
lib/features/discovery/domain/track_listening.dart
lib/features/discovery/application/discovery_controller.dart
lib/features/discovery/application/discovery_signal_observer.dart
lib/features/discovery/data/listening_signal_store.dart
lib/features/discovery/data/discovery_feedback_store.dart
lib/features/discovery/presentation/discovery_pane.dart
lib/features/discovery/presentation/discovery_section_view.dart
lib/features/discovery/presentation/daily_mix_card.dart
lib/features/discovery/presentation/recommendation_card.dart
lib/features/discovery/presentation/discovery_reason_label.dart
lib/features/discovery/presentation/discovery_empty_state.dart
lib/features/settings/presentation/settings_discovery_card.dart
```

### 9.2 修改文件

| 文件 | 改动 |
| --- | --- |
| `lib/app/router/app_router.dart` | 注册 `/discover`，加入合法路径 |
| `lib/features/shell/presentation/app_sidebar.dart` | 「浏览」分组加「发现」 |
| `lib/features/settings/domain/settings_state.dart` | 发现相关偏好（播放记录开关、提示是否关闭） |
| `lib/features/settings/application/settings_controller.dart` | 读写开关 |
| `lib/features/settings/presentation/settings_pane.dart` | 插入发现设置卡 |
| `lib/config/app_initializer.dart` | 启动可选播放观察器 |
| `lib/l10n/app_zh_CN.arb` 等四份 + 生成产物 | 发现页文案 |
| `lib/features/library/...`（可选） | 第 7.7 节 `dateAdded` 修正 |
| `docs/architecture.md`（实现后） | 状态归属与持久化表补一行 |
| `README.md` / `README_en.md`（实现后） | 功能列表补「发现」 |

`PlaybackController`、`LibraryController`、`FavoritesController`、
`MusicSourceService` 在 v1 不需要改（`dateAdded` 修正除外）。

### 9.3 里程碑

| 阶段 | 内容 | 可验证结果 |
| --- | --- | --- |
| M0 | 前置决策 + `dateAdded` 修正（可选） | 连扫两次时间不变；测试通过 |
| M1 | 纯领域层：画像、打分、分段、理由、去重 | 引擎单测全绿，不依赖 Flutter |
| M2 | 发现页只读版：路由、侧栏、卡片、空状态、播放/入队 | 能看、能播、能加入队列；900/760 布局不溢出 |
| M3 | 反馈：不感兴趣、撤销、清除 | 反馈落盘，重启后仍生效 |
| M4 | 可选播放记录 + 设置卡 + 提示 | 关闭时不写；开启后理由出现「常听」 |
| M5（后续） | 显式「在线找更多这位歌手」 | 只在读者点按钮时联网；不自动 |

M1/M2 是可运行的骨架；M3 是推荐可用的必要条件（否则无法纠正），
建议和 M2 一起作为 v1 交付。M4 可以单独开关，M5 不在本版范围。

### 9.4 测试

**领域层** `test/domain/recommendation_engine_test.dart`：

- 空库 → 空结果；
- 有库无标心 → 只有今日混音 / 换口味 / 刚入库，没有歌手分段；
- 一位歌手 3 首 → 出现歌手分段；2 首 → 不出现；
- 喜欢的曲目不会进入歌手分段；未标心候选足够时，今日混音中标心的曲目不超过 20%；
- 同歌手/同专辑上限；全局去重；
- 直播流被排除；
- 不感兴趣被排除，撤销后恢复；
- 同一天同样输入结果稳定；不同日期或刷新盐值结果变化；
- 缺流派、缺年份、空歌手不崩；
- 1 万首的耗时断言（宽松上限，避免 CI 抖动）。

**画像** `test/domain/taste_profile_test.dart`：

- 喜欢权重、播放权重、跳过扣分、45 天半衰；
- 归一化、空信号、负分夹到 0；
- 喜欢但不在库里的 uri 不参与。

**存储** `test/services/listening_signal_store_test.dart` /
`discovery_feedback_store_test.dart`：

- 读写往返、版本、损坏 JSON、过期清理、2000 条上限；
- 开关关闭时观察器不写；清除后为空。

**控制器** `test/app/discovery_controller_test.dart`：

- 音乐库加载中 / 空 / 失败；
- 喜欢变化后重算；
- 扫描进度变化不触发重算（用 `select` 守住）；
- 反馈写入、撤销、清除；
- 播放记录关闭时不读存储。

**界面** `test/app/discovery_page_test.dart`：

- 分段渲染、理由文案、空状态；
- 单击 / 双击 / 红心 / 加入队列 / 播放全部；
- 不感兴趣 + 撤销；
- 760×520 与 1.3 倍字号不溢出；
- 新页面在 `test/app/localization_render_test.dart` 里照现有页面一条用例，
  渲染真实界面读树；`tool/layout_shots_test.dart` 增加 `/discover` 三套截图。

**回归**：

- `flutter analyze` 无问题；
- `flutter test` 全绿；
- 现有音乐库、队列、喜欢、音源测试不变；
- 改了 ARB 后 `flutter gen-l10n` 并提交生成产物。

### 9.5 验收标准

1. 900×600 下打开发现页，首屏至少有一个可播放分段，无溢出。
2. 每张卡片都能说明理由；没有信号时用「从你的音乐库挑的」，不虚构。
3. 播放动作与音乐库一致：尊重「单击替换队列」设置；分段播放显式替换队列。
4. 「不感兴趣」立即消失，撤销可恢复，重启后仍生效。
5. 关闭播放记录后不产生新记录；清除后推荐回到只依据喜欢和元数据。
6. 打开发现页不额外请求音源接口（v1）；远程封面仍按现有缓存策略加载，
   点击远程曲目播放时才会用到网络。
7. 1 万首库的推荐计算在桌面端 100ms 量级；页面滚动不卡顿。
8. `flutter analyze` + `flutter test` 全绿，四个语言环境文案齐全。

## 10. 风险与回退

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| 冷启动推荐很空 | 中 | 中 | 空状态明确引导扫描/标心；不硬凑假分段 |
| 推荐重复、像复读机 | 中 | 中 | 全页去重、歌手/专辑上限、每日种子、手动刷新 |
| 读者觉得被监视 | 中 | 高 | 默认不记录播放；只存 uri 计数；说明浮层 + 一键清除 |
| 大库计算卡顿 | 低 | 中 | `select` 切片、纯函数、1 万首基准；超限再上 isolate |
| 流派/标签脏，推荐跑偏 | 高 | 中 | 缺失维度不参与；流派用 `genreLabel` 展示；不把流派当唯一依据 |
| 喜欢太少，歌手分段不出现 | 高 | 低 | 允许没有歌手分段；今日混音和换口味兜底 |
| 跨来源同曲重复 | 中 | 低 | v1 按 uri 去重；不冒险按标题合并 |
| 推荐结果与音乐库筛选不一致 | 低 | 低 | 文档写明发现页使用全库；页头说明 |
| 设置项越加越多 | 低 | 低 | 只保留「播放记录」和「清除」两项 |
| 反馈误触无法恢复 | 低 | 中 | 立即撤销 snackbar；30 天后自动过期 |

**回退**：发现页是纯增量功能。删除 `/discover` 路由和侧栏入口即可让页面
不可达；两个存储键留着不影响启动。没有修改播放、队列、喜欢、音源的核心语义，
回退不需要迁移数据。

## 11. 待确认

1. **入口**：接受在侧栏新增「发现」一级页吗？备选是音乐库顶部推荐条（方案 B），
   但空间和扩展性更差。
2. **播放记录**：接受默认关闭、需要读者主动开启吗？如果希望开箱即用，
   可以默认开启，但必须同时保留说明和清除入口。
3. **在线推荐**：v1 只从音乐库挑、不请求音源接口，是否满足预期？如果必须要有
   「每日推荐」，建议作为 M5 的独立分段，而不是混进本地推荐。
4. **`dateAdded` 修正**：是否同意先修「首次入库时间」？不同意的话，
   v1 去掉「刚入库」分段。
5. **启动页**：保持 `/library`，还是把 `/discover` 设为默认？建议保持音乐库。

## 12. 明确不做

- 不做用户可见的播放历史页、收听报告、年度总结。
- 不做云端协同过滤、账号、跨设备画像。
- 不做自动续播、无限电台、自动替换队列。
- 不做在线每日推荐聚合（本版）。
- 不做按标题/时长的跨来源去重。
- 不做「少推荐这位歌手」「不推荐这个流派」等多级黑名单（后续）。
- 不做推荐结果持久化缓存；每次打开按当前输入重算。
