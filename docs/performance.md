# 性能：诊断与修复方案

> 2026-10-24 实测，2026-10-25 补 D5。这一页是诊断与方案：D1–D5 都已修完，
> 每一节写着修之前与修之后的数字，以及守住这条线的判据。

## 1. 结论

卡顿不是某一段代码写得慢，是四个问题、三类设计毛病叠在一起（订阅粒度、同步计算、同步 I/O）：

| # | 问题 | 一句话 | 影响面 |
| --- | --- | --- | --- |
| D1 | 播放位置与队列/模式混在同一份状态里，底栏与播放页订阅**整份**状态 | 已修：一次跳位置重建 297 → **18** 个 element | 播放全程 |
| D2 | MPRIS 快照每跳重建，其中一次同步 `existsSync()` 磁盘访问 | 已修：磁盘每首问一次，位置不再发布 | 播放全程 |
| D3 | 音乐库页订阅整份库状态 | 已修：一次扫描进度更新重建 2848 → **53** 个 element（工具条与进度线，列表行不再重建） | 扫描时 |
| D4 | 推荐引擎在 UI 线程同步算全库 | 已修：排序的稳定哈希预计算后，2 万首 129ms、5 万首 280ms，回到预算内 | 发现页 |
| D5 | 列表行自己带 8 个提示、每个提示一个 `OverlayPortal`，动作还是页面按钮 | 已修：一行 293 → **196** 个 element、空闲 overlay 8 → **0**；滚动一步 85ms → **24ms** | 音乐库滚动 |

四个问题都已修完。下面每一节写着修法、判据与守住这条线的测试。

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
   卡片。行里的 `TuneTooltip` 只装一个三件套触发器（`MouseRegion` +
   `Listener` + 读屏标签），不再各自持有一个 `RawTooltip` 和 portal。
   卡片在 overlay 里读主题，所以「开着的提示跟着换主题」照旧成立；没有
   `HintLayer` 的独立 widget 测试退回 `RawTooltip`。
2. **列宽由视口算一次**：`LibraryRowMetrics` 在列表的 `LayoutBuilder` 里
   解析一次（宽度 + 文字缩放 → 三列是否放得下、行高），行只读结果，不再
   每行跑一次 `LayoutBuilder`。文字缩放为 1 时列表拿 `itemExtent`，滚动
   不必先量未建的行。
3. **行内动作换密集原语**：`DenseIconAction` 保留墨迹、悬停、焦点、
   Enter/Space、读屏的按钮语义，丢掉页面按钮的 Material 盒子。
   一个动作 **52 → 29** 个 element（`IconButton` 单独就要 47 个）。
4. **选中标记不改变行的形状**：播起来的那一行只多画一条 2 像素的标记，
   外层的 `Stack` 常驻。少了这一条，第一次点击播放会把行拆了重建，双击的
   第二次点击落进新的点击区，曲目被播放而不是被收藏——`compact_layout_test`
   里那条双击测试就是撞在这里。

### 修之后

同一台机器、同一份 20000 首的合成库、1920×1080、debug（JIT）：

| | 修之前 | 修之后 |
| --- | ---: | ---: |
| 一行的 element | 293 | **196** |
| 一行空闲时持有的 `OverlayPortal` | 8 | **0** |
| 滚动一步（120 像素）中位 | 85ms | **24.4ms** |

`flutter test tool/perf/library_scroll_bench_test.dart` 可复现；它现在和应用
一样先挂 `HintLayer`，否则量的是应用不会画出来的树。

### 为什么停在 196 而不是 150

设计稿的目标是 ≤150（`docs/performance-row-design.md`）。196 拆开是：

| | 每行 |
| --- | ---: |
| 行的底子（序号、封面、三列文字、事实条、时长） | 74 |
| 八个提示（门面、触发器、悬停与长按的监听，每个约 4 个） | 32 |
| 三个动作（每个 29，含它自己的提示） | 90 |

把提示全砍掉是 164，把动作全砍掉是 106——**150 在保留提示和动作时到不了**。
再往下只有两种做法：

- 去掉标题/艺人/专辑的提示：截断的文字就没法读全了；
- 把动作的提示或墨迹/焦点省掉：回到「页面按钮」或「看不见的按钮」。

两者都是产品取舍，不是性能优化，所以没有顺手做。判据按实测值定在 200。

### 判据

- 一行 ≤ 200 个 element（现在 196），空闲时 0 个提示 overlay。
- 一个行内动作 ≤ 30 个 element（现在 29；页面按钮 52）。
- 滚动一步 ≤ 30ms（debug；profile 见 §2 的帧数据口径）。

## 8. 三条硬规则（已写进 AGENTS.md §1.3）

1. **快值与慢值分两条订阅通道。** 一份状态里既有 5 Hz 的值又有 0.1 Hz 的值时，
   读它的界面必须按频率分开订阅；只订阅自己真正要显示的那部分。
   订阅粒度是**读取口**的事，不是状态归属的事——状态仍然只有一个主人。
2. **派生计算要么有预算，要么挪出 UI 线程。** 同步计算的耗时要写进文档
   （像 `recommendation.md` §7.8 那样），超预算就换算法或换线程，不靠「读者不会
   有这么大的库」这种假设。
3. **UI 线程不做同步 I/O。** `existsSync()`、`readAsBytesSync()` 这类调用不进
   播放路径；桌面集成这类「每跳都会走」的路径上尤其不能有。

AGENTS.md §1.3「性能：订阅粒度与计算预算」是这三条的正式版本，
外加一条「状态仍然只有一个主人」。

### 不要做的事

- 不要因为「少重建」给 `PlaybackState` 再加第二份 position（比如让 widget 自己存
  一个进度）——那会变成第二份事实来源，直接违反 `docs/architecture.md`。
- 不要用 `Future.delayed` / `addPostFrameCallback` / `setState` 把重建问题盖住
  （AGENTS.md §1.2 已经禁了）。
- 不要把「进度条」整块搬进 `PlaybackState` 之外的新状态对象——它就该是
  `PlaybackState` 的一个字段，只是读法要分开。

## 9. 落地顺序与风险

五件事互相独立，可以分开做、分开验（都已完成）：

| 顺序 | 做什么 | 收益 | 状态 |
| --- | --- | --- | --- |
| 1 | D1 订阅粒度 | 播放全程的卡顿（最大头） | 已修：297 → 18 个 element |
| 2 | D2 MPRIS | CPU 背景占用、去掉 UI 线程同步 IO | 已修：磁盘每首问一次，位置不发布 |
| 3 | D3 音乐库页 | 扫描时的卡顿 | 已修：2848 → 53 个 element，列表行不再重建 |
| 4 | D4 推荐引擎 | 发现页冻结 | 已修：排序哈希预计算，2 万首 247ms → 129ms |
| 5 | D5 列表行 | 音乐库滚动 | 已修：293 → 196 个 element，8 → 0 个空闲 overlay，滚动一步 85 → 24ms |

回退：每一件都是独立改动，`git revert` 即可，没有数据迁移，没有存储格式变化。

## 10. 相关文档

- `docs/architecture.md`：状态归属与「播放位置由 `PlaybackController` 独家持有」。
- `docs/lyrics.md` §2 D5：同一个毛病在歌词面板上的先例（已修）。
- `docs/recommendation.md` §7.8 与 §9.5 第 7 条：发现页的性能预算与验收标准。
- `docs/verification.md`：门禁。
- `docs/performance-row-design.md`：D5 的设计稿（归谁、预算、迁移顺序）。
- `tool/perf/`：四个基准脚本，本文所有数字都出自它们。
