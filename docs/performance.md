# 性能：诊断与修复方案

> 2026-10-24 实测，2026-10-25 补 D5，2026-10-28 补 D6/D7 与 D8。这一页是诊断与方案：
> D1–D8 都已修完，每一节写着修之前与修之后的数字，以及守住这条线的判据。

## 1. 结论

卡顿不是某一段代码写得慢，是七个问题、几类设计毛病叠在一起
（订阅粒度、同步计算、同步 I/O、整库驻留内存、每操作写放大）：

| # | 问题 | 一句话 | 影响面 |
| --- | --- | --- | --- |
| D1 | 播放位置与队列/模式混在同一份状态里，底栏与播放页订阅**整份**状态 | 已修：一次跳位置重建 297 → **18** 个 element | 播放全程 |
| D2 | MPRIS 快照每跳重建，其中一次同步 `existsSync()` 磁盘访问 | 已修：磁盘每首问一次，位置不再发布 | 播放全程 |
| D3 | 音乐库页订阅整份库状态 | 已修：一次扫描进度更新重建 2848 → **53** 个 element（工具条与进度线，列表行不再重建） | 扫描时 |
| D4 | 推荐引擎在 UI 线程同步算全库 | 已修：排序的稳定哈希预计算后，2 万首 129ms、5 万首 280ms，回到预算内 | 发现页 |
| D5 | 列表行自己带 8 个提示、每个提示一个 `OverlayPortal`，动作还是页面按钮 | 已修：一行 293 → **162** 个 element、空闲 overlay 8 → **0**；滚动一步 85ms → **23ms**；一次收藏重建 3751 → **87** 个 element | 音乐库滚动 |
| D6 | 曲库整库常驻内存，扫描时还要再建一份 | 已修：控制器只持 1000 行窗口，合并归数据库一家 | 常驻内存、扫描 |
| D7 | 每操作路径写放大：整表往返、无防抖、不节流、重扫重写整库 | 已修：重扫 0 写、改名 1 写、单键 UPSERT、节流与防抖 | 切歌/扫描/搜索/收藏 |
| D8 | 损坏标签的 GB 级帧声明把启动内存抬到 1.5GB | 已修：vendored 读包在 `Buffer.read` 按文件剩余收界，启动峰值 1578 → **316**MB | 启动、扫描 |

八个问题都已修完。下面每一节写着修法、判据与守住这条线的测试。

**这些不是新提的标准，项目自己已经写过：**

- `docs/lyrics.md` §2 的 D5 记着「播放位置一跳就整块重建」，当时只修了歌词面板
  （`activeLyricLineProvider`），底栏与播放页原样留着。D1 就是同一个毛病的另外两处。
- `docs/recommendation.md` §7.8 自己定了预算「1 万首曲目 100ms 内算完」。修之前
  实测 1 万首贴着 100ms、2 万首 247ms、5 万首 630ms，超预算 6 倍；
  稳定哈希预计算之后是 85ms / 143ms / 324ms，回到预算内。

发现页在 2026-10-24 有两轮重构：引擎拆成 `recommendation_*` 几个文件，把
「每个分段重排一次全序」改成「整库排一次 + 每段线性筛选」，打分换成归一化过的键；
随后把排序的稳定哈希改成排序前算一次（`RecommendationCandidate.tieBreak`）。
**D4 已修完**，见 §6。

## 2. 怎么测的

四个基准脚本在 `tool/perf/`，口径可复现：

```bash
flutter test tool/perf/recommendation_bench_test.dart   # D4：发现页计算耗时
flutter test tool/perf/rebuild_bench_test.dart           # D1：一次跳位置重建多少
flutter test tool/perf/library_bench_test.dart           # D3：扫描进度一步的代价
flutter test tool/perf/library_scroll_bench_test.dart    # D5：一行多重、滚动一步多久
```

- D1/D3 用 `debugOnRebuildDirtyWidget` 数「这一帧重建了多少 element」，
  用 `Stopwatch` 量一帧的 build + layout 耗时。
- D4 用合成的库直接调 `RecommendationEngine.recommend`，量一次完整计算。
- 环境：Flutter 3.47.7 / Dart 3.13.5，Linux x64，**debug 模式**（JIT）。
  release 会快几倍，但 D1/D3 的重建**次数**与 D4 的**冻结时长**不变——
  卡顿是次数与结构决定的，不是 JIT 决定的。

### 实测数字

真机上量过一次（profile 构建，VM service 的时间线，播放中取 5 秒窗口）：

| | 修复前 | 修复后 |
| --- | --- | --- |
| UI 线程一帧（`Animator::BeginFrame`）p90 | 4.63ms | **1.38ms** |
| UI 线程一帧 中位 | 0.73ms | 0.88ms |
| `LAYOUT` p90 | 2.82ms | **0.62ms** |
| 超过 16.7ms 的帧 | 0 | 0 |

两个版本都没有掉帧——**release 下这一条路径本来就不是掉帧的主因**，
widget 测试里的 297 → 18 说的是「重建量」，不是「掉帧」。真机上省下的是
尾延迟（p90 从 4.63ms 到 1.38ms）。真正掉帧的地方在 D5 与发现页。

（量法：`flutter build linux --profile` 跑起来，从日志里拿到 VM service 的
地址，`getVMTimeline` 取时间线，按 `B`/`E` 事件配对求每帧时长。）

```text
D1  底栏（外壳 + 音乐库页）      一次跳位置重建 297 → 18 个 element，16.2 → 8.6ms
D1  正在播放页                  一次跳位置重建 304 → 20 个 element
D3  音乐库页 20000 首           一次扫描进度更新重建 2848 → 53 个 element，50.3 → 2.8ms
D4  发现页  1000 首              30ms
D4  发现页  5000 首              55ms
D4  发现页 20000 首             129ms
D4  发现页 50000 首             280ms
```

D4 的耗时分解（2 万首 / 5 万首）：

```text
修之前                修之后
总计 216ms / 585ms    总计 100ms / 253ms
  ├─ 候选构建 28/83       ├─ 候选构建 29ms /  80ms
  ├─ 打分     30/79       ├─ 打分     31ms /  82ms
  ├─ 排序   120/319  ←    └─ 排序     14ms /  24ms   ← 哈希预计算之后
  └─ 分段筛选 38/104         分段筛选 26ms /  67ms
```

### 位置跳得有多快

`just_audio` 的 `positionStream` 是 `steps: 800, minPeriod: 16ms, maxPeriod: 200ms`：

| 曲目长度 | 位置更新频率 |
| --- | --- |
| 3 分钟 | 5 次/秒 |
| 30 秒 | 27 次/秒 |
| 10 秒以内 | 60 次/秒（撞到 16ms 下限） |

也就是说：**播短曲的时候，底栏和播放页每秒重建 1.8 万个 widget**。

## 3. D1：播放位置带翻了整页

### 现象

播放时底栏与正在播放页持续掉帧；短曲、界面重（正在播放页带全屏径向渐变与封面投影）
时最明显。

### 根因

`PlaybackState` 里两类东西住在一起：

- **慢字段**：队列、当前曲目、播放状态、播放模式、音量、错误、缓存状态。几秒才变一次。
- **快字段**：`position`。5–60 次/秒。

凡是 `ref.watch(playbackControllerProvider)`（订阅**整份**状态）的 widget，
每一跳都整块重建：

- `lib/features/player/presentation/player_dock.dart:37`——底栏，永远在屏幕上。
- `lib/features/player/presentation/now_playing_page.dart:73`——正在播放页。

被顺带重建的还有底栏的阴影（blur 28）、播放页的径向渐变与封面投影：这些是
**重绘**成本，重建是它们的触发器。

### 修法

事实来源不动：播放位置仍然只有 `PlaybackController` 一个主人
（`docs/architecture.md` 已写明）。改的是**读法**——把两条订阅通道分开：

1. **慢切片**：新增一个只含慢字段的 provider（例如 `playbackOverviewProvider`，
   从同一份 `PlaybackState` 派生，不是第二份状态）。底栏骨架、播放页骨架、
   队列面板订阅它。位置变化时它不变 → 不重建。
2. **快切片**：进度那一小块（时间标签 + 滑块）单独成一个 widget
   （例如 `PlaybackProgressRow`），只订阅 `(position, duration)`。
   一次跳位置只重建它自己。

实际改了这些文件：

| 文件 | 改了什么 |
| --- | --- |
| `lib/features/player/domain/playback_overview.dart`（新） | 慢的那一半：`PlaybackOverview`，当前位置、队列、模式、音量、错误、缓存状态 |
| `lib/features/player/application/playback_overview_provider.dart`（新） | 从同一份 `PlaybackState` 派生慢切片；位置不在里面 |
| `lib/features/player/presentation/player_dock.dart` | 整份 watch → 慢切片；进度行拆成 `_DockProgress` |
| `lib/features/player/presentation/now_playing_page.dart` | 同上；`_ProgressRow` 单独看位置，`_Transport` 单独看状态 |
| `lib/features/player/presentation/audio_source_badge.dart` | 下载进度由徽标自己看，不再拖着整块界面 |
| `lib/features/queue/presentation/queue_panel.dart` | 选择器不再每一跳都走一遍队列找游标 |

### 判据

- 一次跳位置重建的 element ≤ 20（修之前 297 / 304）。
- 底栏与播放页在没有跳位置时不再重建（订阅切片不变 → 框架不叫醒它们）。

**现状：已达标。** 底栏 18 个、播放页 20 个 element，一帧 8.6ms（修之前 16.2ms）。

## 4. D2：MPRIS 每跳一次快照，还顺手读了一次磁盘

### 现象

播放时 CPU 有稳定的背景占用；磁盘慢的机器上更明显。

### 根因

`lib/features/desktop/application/desktop_integration_controller.dart:137`
订阅整份播放状态，**每一跳**都：

1. 重建一份 MPRIS 快照（`MprisStateMapper.snapshotFor`）；
2. 解析封面地址——`_artUrlOf` → `ArtworkCache.coverFileFor` →
   `File.existsSync()`，**同步文件系统调用，落在 UI 线程**；
3. 调 `mpris.update()`（服务内部会 diff，只在真变了才发信号，这一步没问题）。

同一条链上还有 `PlaybackSessionRecorder.record()`：每跳跑一次（它自己用 5 秒
节流写盘，这部分没问题）。

### 修法

- **封面地址解析一次**：曲目不变，封面地址就不变。现在 `_artUrlOf` 每跳都要
  `existsSync()` 一次；改成在曲目切换时解析一次并缓存，播放路径上就没有同步 I/O。
- **只更新位置，不重建快照**：MPRIS 的 `Position` 是只读属性，客户端自己轮询
  `GetPosition`，服务里也特意把 position 排除在 `PropertiesChanged` 之外
  （见 `mpris_service_io.dart` 的注释）。所以每一跳只需要把新位置写进快照，
  **不用重建整份快照、更不用发信号**；慢字段（状态、曲目、音量、模式）变了才
  重建并发布。位置仍然要保持新鲜——客户端轮询读的就是这份快照。
- 播放位置变化不再产生 D-Bus 流量。

### 判据

- 播放中每秒 D-Bus `PropertiesChanged` 消息数 = 0（除非用户改了音量/模式）。
- UI 线程上不再有 `existsSync()`。

**现状：已达标。** 封面地址每首问一次磁盘（`MprisStateMapper` 记着上一首的答案），
位置只交给服务刷新、不发布。守住这两条的测试：
`test/app/desktop_mpris_publish_test.dart`、
`test/app/mpris_state_mapper_test.dart`。

## 5. D3：扫描进度每 1% 重建整个列表

### 现象

扫描音源时界面一顿一顿；音乐库越大越明显。

### 根因

`lib/features/library/presentation/library_pane.dart:50` 订阅整份库状态。
`LibraryController.reportProgress` 每 1% 发一次新状态 → 整页重建。

一次重建里还有两处 O(n)：

- `LibraryState.filteredSongs`：每次 build 重算，过滤时给每首曲子的
  title/artist/album 各做一次 `toLowerCase()`（2 万首 = 6 万次字符串分配）。
- `LibraryPane._availableSources`：每次 build 遍历全库建一个 Set。

### 修法

- **进度与列表分开**：扫描进度（`scanProgress` / `scanStatus` / `statusMessage`）
  给状态条自己订阅；列表只订阅「曲库 + 关键字 + 来源筛选」。
  扫描进度这一步就不该动列表。
- **过滤记忆化**：`filteredSongs` 按 `(songs, query, sourceFilter)` 记忆化，
  同一份输入不重算。

### 判据

- 一次扫描进度更新**不重建列表行**（修之前 2848 个 element 全是列表）。
- 过滤只在这一组输入变了的时候算一次。

**现状：已达标。** 一次进度更新重建 53 个 element，全是工具条与进度线；
列表行一个也不重建，一帧 2.8ms（修之前 50.3ms）。
过滤规则只有一份：`filteredSongsOf`（`features/library/domain/library_state.dart`），
页面与状态都走它。

## 6. D4：推荐引擎在 UI 线程同步算全库

### 现象

打开发现页、点刷新、点「不感兴趣」、标一个心——每次都冻一下，
库里曲目越多冻得越久。

### 根因与现状

引擎是同步的，没有 I/O：打开页面、点刷新、点「不感兴趣」、标一个心，
每次都要在 UI 线程上把全库算一遍。原来的开销分布（2 万首 / 5 万首）：

```text
总计 216ms / 585ms
  ├─ 候选构建   28ms /  83ms
  ├─ 打分       30ms /  79ms
  ├─ 排序      120ms / 319ms   ← 占比最大
  └─ 分段筛选   38ms / 104ms
```

**排序那一项已经修好**：比较函数
`RecommendationSelection.compareAnchors` 原来每次比较都重算两个
`stableHashOf('${uri}|$seed')`——字符串插值 + FNV 逐字符哈希，于是
`O(n log n)` 次哈希与同等的字符串分配（2 万首约 57 万次比较、57 万次插值）。
现在稳定键在排序前算一次（`RecommendationCandidate.tieBreak`），排序只比整数，
哈希次数降到 `O(n)`：**2 万首从 120ms 降到 16ms，5 万首从 319ms 降到 25ms**。

剩下的开销按占比：候选构建（每首解析流派、切分、归一化）与分段筛选
（六个分段各扫一遍全库），都是 O(n) 一次遍历，常数还有压的空间，
但已经不是「卡顿」级别。

### 判据

- 1 万首 ≤ 100ms（文档预算），2 万首 ≤ 200ms，5 万首 ≤ 500ms。
- 排序一项在 2 万首 ≤ 20ms。
- 发现页的刷新按钮点了之后不冻结界面（计算不在 UI 线程，或已经快到无感）。

**现状：已达标。** 1 万首约 75ms、2 万首 129ms、5 万首 280ms。
预算内的库不需要 `Isolate.run`；真要再压，先压候选构建与分段筛选，
不要急着引入并发。

## 7. D5：一行 293 个 element（已修）

### 现象

音乐库列表滚动时掉帧。行是列表里最重的东西：每一行都带封面、若干事实
条与两三个动作。

### 根因

实测一行 **293 个 element**，其中：

| | 每行 |
| --- | --- |
| `TuneTooltip`（每个带一个 `OverlayPortal`） | 8 个 |
| `Semantics` | 36 个 |
| `RichText`（文字） | 11 个 |
| 合计 | 293 个 |

滚动一步（120 像素）大约新建 2–3 行，也就是 600–900 个 element。
`TuneTooltip` 站在 `RawTooltip` 上（这是有意的：开着提示换主题时提示要当场
跟着换，框架的 `Tooltip` 做不到），而 `RawTooltip` 每个都带一个
`OverlayPortal`——提示的卡片是懒的，portal 不是。

### 修法

1. **提示归一个层**：`HintLayer` 挂在 navigator 上面，全应用只有一张提示
   卡片。行里的 `TuneTooltip` 本身就是三件套触发器（`MouseRegion` +
   `Listener` + 读屏标签），不再各自持有一个 `RawTooltip` 和 portal。
   卡片在 overlay 里读主题，所以「开着的提示跟着换主题」照旧成立；没有
   `HintLayer` 的独立 widget 测试退回 `RawTooltip`。
2. **列宽由视口算一次**：`LibraryRowMetrics` 在列表的 `LayoutBuilder` 里
   解析一次（宽度 + 文字缩放 → 三列是否放得下、行高），行只读结果，不再
   每行跑一次 `LayoutBuilder`。文字缩放为 1 时列表拿 `itemExtent`，滚动
   不必先量未建的行。
3. **行内动作换密集原语**：`DenseIconAction` 保留墨迹、悬停、焦点、
   Enter/Space、读屏的按钮语义，丢掉页面按钮的 Material 盒子。
   一个动作 **52 → 24** 个 element（`IconButton` 单独就要 47 个）。
4. **选中标记不改变行的形状**：播起来的那一行只多画一条 2 像素的标记，
   这条边并进行已有的边框，颜色从透明换成主色。少了这一条，第一次点击
   播放会把行拆了重建，双击的第二次点击落进新的点击区，曲目被播放而不是
   被收藏——`compact_layout_test` 里那条双击测试就是撞在这里。
5. **图标不再各带一层盒子**：`IconGlyph` 把 `Icon` 的六个 element
   （`Semantics`、`ExcludeSemantics`、`SizedBox`、`Center`、`RichText` 与
   自身）压成一个 `RichText`。图标本来就是装饰，控制它的按钮与提示
   已经有名字；空语义标签让读屏跳过私用区字符。
6. **提示只剩一个 element**：`TuneTooltip` 就是触发器本身
   （`HintTrigger` 的类型别名），不再在门面里再包一层触发器。
7. **谁的值谁订阅**：行自己听「是否收藏、是否当前曲、是否在播」，页面
   不再听整份收藏与整份健康报告；一次收藏只重建一行，不再重建整个视口。

### 修之后

同一台机器、同一份 20000 首的合成库、1920×1080、debug（JIT）：

| | 修之前 | 修之后 |
| --- | ---: | ---: |
| 一行的 element | 293 | **162** |
| 一行空闲时持有的 `OverlayPortal` | 8 | **0** |
| 滚动一步（120 像素）中位 | 85ms | **23ms** |
| 一次收藏重建的 element | 3751 | **87** |

`flutter test tool/perf/library_scroll_bench_test.dart` 可复现；它现在和应用
一样先挂 `HintLayer`，否则量的是应用不会画出来的树。

### 第二轮：197 → 162

第一轮之后行里还剩五类开销，占大头的仍是动作与提示。第二轮没有动产品
内容，只把「同一个东西被画了两遍」的地方收掉：

| 修法 | 省下的 element |
| --- | ---: |
| `IconGlyph` 取代 `Icon`（一行六个图标） | 22 |
| 提示门面与触发器合成一个元素（八个提示） | 8 |
| `MetaBadge` 不再给自己的图标加方框（两个事实） | 2 |
| 封面从 `Container` 的五层换成 `ClipRRect` + `ColoredBox` + `SizedBox` | 2 |
| 选中标记并进已有边框，去掉常驻 `Stack` | 1 |
| 合计 | 35 |

列表还关掉了每行的 `AutomaticKeepAlive`：行没有要保活的状态，默认的包装
只会给每行挂一个监听。

一行现在是 162：三个动作 72（每个 24，提示算在里面）、其余五个提示
20（每个 4）、行的底子 70（序号、封面、三列文字、两个事实、时长、
点击区与边框）。

### 一次收藏不再重建一页

行里的值归行自己听：每个行只订阅「是否收藏、是否当前曲、是否在播」
这三个值，页面不再订阅整份收藏；源顺序只订阅一个可比较的 key，顺序
没变就不重建。实测一次收藏从 **3751** 个 element 降到 **87**（一行），
滚动与播放时不再牵动整个视口。`library_rebuild_test.dart` 守着这条线。

### 为什么停在 162

设计稿最初的目标是 ≤150。本地典型 162、带音源 182，已经离它不远；
再往下只剩两种做法：

- 去掉标题/艺人/专辑的提示：截断的文字就没法读全了；
- 把动作的墨迹/焦点或行的点击反馈省掉：回到「页面按钮」或「看不见的
  按钮」。

两者都是产品取舍，不是性能优化，所以没有顺手做。判据按实测值定在
170（本地典型）/ 190（带音源或多事实）。

### 判据

- 一行 ≤ 170 个 element（本地典型 162）；带音源或多事实的行 ≤ 190（现在 182 / 176）。
- 一个行内动作 ≤ 25 个 element（现在 24；本体 19；页面按钮 52）。
- 一次收藏重建 ≤ 120 个 element（现在 87，只有一行）。
- 空闲时 0 个提示 overlay。
- 滚动一步 ≤ 30ms（debug；profile 见 §2 的帧数据口径）。

## 8. D6：整库常驻内存（已修）

### 现象

内存占用随曲库线性涨、扫描时翻着涨，扫描完不回落；库里几万首时进程内存吓人。

### 根因

`LibraryState.songs` 把**整库**的 `Song` 对象常驻在控制器状态里，扫描还要再建一份：

1. 扫描结果先在控制器里整库合并成新列表——旧列表、新列表与合并副本
   同时活着；
2. 合并完再整体写回存储，旧的全量文档与新的并行存在；
3. 之后每次 `scan` / `addSongs` / `loadMore` 都重建并替换整份列表。

库 2 万首时，堆上至少三份全量列表同时存在；RSS 跟着库大小走，没有上限。

### 修法

**库不入内存，内存只留一页。** 曲库的权威从控制器状态挪回数据库：

1. 扫描结果不再在内存里合并成全量列表，而是**分批 upsert 进库**
   （`LibraryStorage.ingest`，一批 500 行，批间让出事件循环）；
2. `LibraryState.songs` 始终是从数据库读出的一个窗口（`windowSize = 1000`），
   `loadMore` 往下翻；控制器里不再有「全库列表」这个东西；
3. 死掉的合并逻辑一并删除（`_sameLibrary`、`_mergeResults`、`_dedupe`、
   `_keepFirstSeen`）——合并语义只剩数据库一家，见 D7 的 `mergedCandidate`；
4. 行的去留也归数据库：`deactivateUncovered` 按两条规则收窄——本地行按
   「本次扫描的目录前缀」收窄（列举失败不误伤库），远程行按「音源启用
   集合」收窄（禁用即出列）。行留在磁盘上，音源重新打开就回来。

### 判据

- `LibraryState.songs` ≤ 窗口大小（1000）+ 一批进来的行；重扫不换窗口：
  `test/app/library_source_merge_test.dart`
  「a scan that brings the library back keeps the window it had」
  （同一份列表实例，页面不重建）。
- 控制器里没有第二份合并实现：`test/app/fake_library_storage.dart` 包装
  真的 in-memory 库，控制器测试跑的是真 SQL 语义。

**现状：已达标。** 控制器里没有任何全量列表路径；合并只有数据库一家
（`lib/features/library/application/library_controller.dart`）。

## 9. D7：每个操作都在重写整库（已修）

### 现象

切歌、搜索、收藏、扫描时卡一下，库越大越明显。磁盘与 CPU 的占用都落在
「每操作」路径上，不是播放路径上（播放路径由 D1/D2 守着）。

### 根因

六处写放大：

1. **queue_meta 全表往返**：`savePosition` 把队列元数据整表读出、改一个键、
   整表写回；每次落位置都是一次全表往返。
2. **收听记录全表重写**：写一条收听记录要读全表、改一行、全表回写。
3. **搜索没有防抖**：每敲一个字符做一次全表 reload；输入「周杰伦」
   = 3 次全量窗口重建。
4. **下载进度不节流**：每 1% 一次状态重建，界面跟着抖。
5. **tag 解析一个文件一个 worker**：2 万首 = 2 万个 isolate 的生成与销毁，
   扫描的 CPU 花在调度上比花在解析上还多。
6. **ingest 行形态不一致**：首轮扫描把行写成原始形态，下一轮合并时
   `mergeWith` 才把本地文件路径补到行上——重扫必须把整库重写一轮才稳定；
   反过来，纯本地行的同源改名又被 `mergeWith` 的「文件侧当 track」选择
   吃掉，改名永远落不了库。

### 修法

写路径全部改成「按键、按需、按批」：

| 修法 | 内容 |
| --- | --- |
| SQLite 日志模式 | WAL + `synchronous=NORMAL`：提交不再每次全量 fsync |
| `queue_meta` | 单键 UPSERT + `deleteQueueMetaKeys`；`savePosition` 只写 position 两个键 |
| 收听记录 | 单行 UPSERT（`saveListeningEntry` / `deleteListening`）+ 内存 map 原地更新 |
| 搜索 | 180ms 防抖 + reload 世代守卫（`_reloadGeneration`），过期结果不落地 |
| 下载进度 | 10Hz 节流（首个事件直通、`progress == 1` 必达） |
| tag 解析 | 固定 worker 池：一批 200 个文件、至多 8 个 worker |
| ingest 行形态 | `mergedCandidate`：落库前自合并归一，同一次扫描永远落在同一形态上 |

### ingest 的行形态（最后一项展开）

- 行**首次落库**就是归一形态：本地文件行把路径落在 `localPath` 上
  （`song.mergeWith(song)` 只做这一件事，且幂等）。
- 存量行与扫描相遇，**只由存量行补扫描不知道的事实**（流地址、副本的
  文件事实）；**纯本地行**（没有音源身份的行）就是本次扫描自己的上一
  形态，扫描是权威——改名得以传播。
- 带音源身份的行保持合流固定点：任何一侧重扫都落在已存的行上，零写入。

### 实测（2 万首，in-memory 库，2026-10-28 一次性脚本）

| | 修之前 | 修之后 |
| --- | ---: | ---: |
| 首次 ingest | 196ms / 20000 写 | 215ms / 20000 写 |
| 重扫（同事实） | 287ms / 20000 写 | **119ms / 0 写** |
| 改名一首 | 0 写（改名被吃掉） | **1 写** |

修之前重扫要整库重写一轮（形态归一那轮），且**改名永远落不了库**：
纯本地行的扫描带着文件，`mergeWith` 让存量行当 track 侧，存量的文本
赢了扫描的文本。修后重扫零写、改名一写。

### 决定不做

- **把歌词/genres/performers/sourceData 移出 songs 表的 json 列**：
  收益是行体积与解码时间，代价是 schema churn 与详情面板全链路异步化；
  D6 窗口化之后解码只发生在 1000 行窗口上，收益不抵。
- **`albumSummaries` 加封面列**：延后，等专辑视图有性能证据再加。

### 判据

- 重扫同事实 0 写：`test/services/library_database_test.dart`
  「an ingest that brings the same facts back writes nothing」。
- 同源改名 1 写：同文件「an ingest rewrites only the row whose facts
  changed」；两侧固定点「an ingest merges the copies another source
  brings」（任一侧重扫都是 0 写）。
- 队列与位置只写该写的键：`test/app/playback_session_test.dart`
  「the queue and position are written when the player closes」。
- 收听记录单行落库：`test/services/listening_signal_store_test.dart`
  「a listened track is summarized」。

**现状：已达标。** 863 个测试全绿，六处写放大全部按上表收掉。

## 10. D8：一个损坏的标签把启动内存抬到 1.5GB（已修）

### 现象

每次启动，t≈4.4–4.8s 处 RSS 从 ~320MB 一跳到 **1.5–1.6GB**，有时几秒回落、
有时滞留 30 秒以上。空库也一样（库本身不背锅），VM 里 5 万个
`_OneByteString` 合计 **1.23GB**，full GC 之后仍然存活——是「有持有者的
瞬时大块」，不是碎片也不是泄漏。

### 根因

曲库里的 `2014-02-12 Bigwords.mp3`（文件 4,146,688 字节）的 ID3v2 标签
损坏：合法的 tag 头声明 51,142 字节，内部却有一个 id 为 `\x00COM` 的坏帧，
帧头声明 size=**1,291,845,632**（~1.2GB）。上游读包
`audio_metadata_reader 1.8.1`（当时已是最新版）的 `Buffer.read(size)` 对
声明大小无条件 `Uint8List(size)`，不做文件边界校验——4MB 的文件按声明
分配了 1.2GB 的零填充缓冲，再解码成一个常驻大字符串。FLAC
（`buffer.read(block.length)`）与 MP4（`buffer.read(box.payloadSize)`）
共用同一个无界读，属同一类 bug；RIFF/AIFF 的解析器倒是自己做了
`remainingBytes` 防护，说明包里本就有这个原语（`readAtMost`），只是
ID3v2/FLAC/MP4 没用上。

### 修法

上游没有修复，把包复制到 `vendor/audio_metadata_reader`（MIT，保留
LICENSE，走 `dependency_overrides` 接入），在 `Buffer.read` 一处收界：
读取前把 `size` 收到 `remainingBytes`（文件真实剩余）内，非正数请求返回
空列表。只影响分配大小，不改变各解析器的游标推进；这一处补丁同时修掉
mp3/flac/mp4 整类「声明超界」问题。补丁清单与升级步骤见
`vendor/audio_metadata_reader/VENDORED.md`。回归测试在
`test/services/song_creator_test.dart`：自造一个帧声明 1.29GB 的损坏文件，
断言解析完成且 RSS 增量 < 100MB（修之前是 +1.2GB）。

顺手把 `JustAudioMediaKit.bufferSize` 从默认 32MB 下调到 8MB
（`demuxer-max-bytes` 与 `demuxer-max-back-bytes` 各取一份）：本地小文件
的播放开销实测与此无关（4MB 的曲子整个装得进 8MB 缓存，30MB 的 84 分钟
m4a 播放期 RSS 也稳定在 ~355MB 不涨），这条只给**长网络流**封顶——最坏
情况从 64MB 降到 16MB。

### 实测（真实数据副本，release 构建，`/proc/<pid>/status` 采样）

| 指标 | 修之前 | 修之后 |
| --- | --- | --- |
| 启动峰值 RSS | 1578MB（t≈4.4s，持续 3s–30s+） | **316MB**（曲线全程无跳变） |
| 坏文件单文件解析 | +1237MB 且 3s 不回落（1636ms） | **+8MB**（30ms） |
| 稳态 RSS | 320–355MB | **306–316MB** |

稳态的构成（smaps 按 mapping 聚合，NVIDIA + Impeller/JIT 的机器）：
NVIDIA/LLVM 图形栈 ~123MB、flutter engine + AOT 代码 ~42MB、Dart 堆
~34MB、内置字体（Noto Sans/Serif SC-VF）~35MB（文件映射，可回收）、
glibc 堆 ~60MB。**「稳态 200MB」在这台机器上达不到**：光图形栈加引擎
就有 ~205MB，是任何 Flutter Linux 应用的地板。两件没做的事如实记录：

- glibc 的 malloc arena 按 CPU 数劈堆，`MALLOC_ARENA_MAX=2` 一次性消融
  实测省 ~28MB（[heap] 60 → 32MB）。这是 libc 环境调优不是应用代码，
  要进的话走启动期 `mallopt` 并单独验证，本轮不做。
- 字体是设计语言的一部分（Serif 是壳层 display 字级），且为文件映射页
  可回收，不砍。

GPU 栈的口径（2026-10-28 消融）：这台机器是 NVIDIA 独显 + Intel 核显双
卡，但核显被 `vfio-pci` 接管（直通给虚拟机），宿主机没有它的渲染节点。
强制走 Mesa（`__EGL_VENDOR_LIBRARY_FILENAMES=50_mesa.json`）只会落到
llvmpipe 软渲染，RSS 反升到 404MB——不是核显的真实数字。纯核显（Mesa
ANV/iris）机器上，NVIDIA 专属驻留（`nvidiactl` 48MB + `eglcore` 10MB +
`gpucomp` 18MB ≈ 76MB）会消失，同构建稳态按此外推 ~230MB。应用**不自选
GPU**：Flutter 没有这个 API，Linux 上由会话与 glvnd 决定（`prime-run`、
`DRI_PRIME`），覆盖用户的选择得不偿失；核显机器自然继承轻驱动栈。

### 判据

- `flutter test test/services/song_creator_test.dart`：损坏帧回归测试
  （RSS 增量 < 100MB），每次改动 tag 解析路径都要过。
- 真实库启动：RSS 曲线在 t=10s 内单调平滑、无 >60MB 的跳变；坏文件在库
  里时启动峰值不得回到 GB 量级。
- 升级 `audio_metadata_reader` 前先读本节的根因与
  `vendor/audio_metadata_reader/VENDORED.md` 的补丁清单。

## 11. 四条硬规则（已写进 AGENTS.md §1.3）

1. **快值与慢值分两条订阅通道。** 一份状态里既有 5 Hz 的值又有 0.1 Hz 的值时，
   读它的界面必须按频率分开订阅；只订阅自己真正要显示的那部分。
   订阅粒度是**读取口**的事，不是状态归属的事——状态仍然只有一个主人。
2. **派生计算要么有预算，要么挪出 UI 线程。** 同步计算的耗时要写进文档
   （像 `recommendation.md` §7.8 那样），超预算就换算法或换线程，不靠「读者不会
   有这么大的库」这种假设。
3. **UI 线程不做同步 I/O。** `existsSync()`、`readAsBytesSync()` 这类调用不进
   播放路径；桌面集成这类「每跳都会走」的路径上尤其不能有。
4. **列表行的值由行自己订阅。** 行的收藏、当前曲与播放状态由行读；页面只
   订阅结构、顺序与筛选。一次收藏只重建那一行（`library_rebuild_test.dart`）。

AGENTS.md §1.3「性能：订阅粒度与计算预算」是这四条的正式版本，外加
「状态仍然只有一个主人」，以及 D6/D7 落地时的两条：库不入内存、
每操作路径不做写放大。

### 不要做的事

- 不要因为「少重建」给 `PlaybackState` 再加第二份 position（比如让 widget 自己存
  一个进度）——那会变成第二份事实来源，直接违反 `docs/architecture.md`。
- 不要用 `Future.delayed` / `addPostFrameCallback` / `setState` 把重建问题盖住
  （AGENTS.md §1.2 已经禁了）。
- 不要把「进度条」整块搬进 `PlaybackState` 之外的新状态对象——它就该是
  `PlaybackState` 的一个字段，只是读法要分开。

## 12. 落地顺序与风险

八件事互相独立，可以分开做、分开验（都已完成）：

| 顺序 | 做什么 | 收益 | 状态 |
| --- | --- | --- | --- |
| 1 | D1 订阅粒度 | 播放全程的卡顿（最大头） | 已修：297 → 18 个 element |
| 2 | D2 MPRIS | CPU 背景占用、去掉 UI 线程同步 IO | 已修：磁盘每首问一次，位置不发布 |
| 3 | D3 音乐库页 | 扫描时的卡顿 | 已修：2848 → 53 个 element，列表行不再重建 |
| 4 | D4 推荐引擎 | 发现页冻结 | 已修：排序哈希预计算，2 万首 247ms → 129ms |
| 5 | D5 列表行 | 音乐库滚动 | 已修：293 → 162 个 element，8 → 0 个空闲 overlay，滚动一步 85 → 23ms，一次收藏重建 3751 → 87 |
| 6 | D6 库不入内存 | 常驻内存随库不封顶 | 已修：控制器只持 1000 行窗口，合并归数据库一家 |
| 7 | D7 每操作写放大 | 切歌/搜索/收藏/扫描的卡顿与磁盘写 | 已修：重扫 0 写、改名 1 写、单键 UPSERT、防抖与节流 |
| 8 | D8 损坏标签的 GB 级帧声明 | 启动、扫描的内存峰值 | 已修：vendored 读包收界，峰值 1578 → 316MB |

回退：每一件都是独立改动，`git revert` 即可，没有数据迁移，没有存储格式变化。

## 13. 相关文档

- `docs/architecture.md`：状态归属与「播放位置由 `PlaybackController` 独家持有」。
- `docs/lyrics.md` §2 D5：同一个毛病在歌词面板上的先例（已修）。
- `docs/recommendation.md` §7.8 与 §9.5 第 7 条：发现页的性能预算与验收标准。
- `docs/verification.md`：门禁。
- `docs/performance-row-design.md`：D5 的设计稿（归谁、预算、迁移顺序）。
- `tool/perf/`：四个基准脚本，本文所有数字都出自它们。
