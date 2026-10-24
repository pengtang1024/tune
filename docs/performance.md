# 性能：诊断与修复方案

> 2026-10-24 实测。这一页只放诊断与方案，代码还没动；动之前先读这里的判据。

## 1. 结论

卡顿不是某一段代码写得慢，是四个问题、三类设计毛病叠在一起（订阅粒度、同步计算、同步 I/O）：

| # | 问题 | 一句话 | 影响面 |
| --- | --- | --- | --- |
| D1 | 播放位置与队列/模式混在同一份状态里，底栏与播放页订阅**整份**状态 | 5–60 次/秒，整页重建 300 个 element | 播放全程 |
| D2 | MPRIS 快照每跳重建，其中一次同步 `existsSync()` 磁盘访问 | 每秒 5–60 次同步 IO 落在 UI 线程 | 播放全程 |
| D3 | 音乐库页订阅整份库状态 | 扫描进度每 1% 重建整个可见列表 + 全库过滤重算 | 扫描时 |
| D4 | 推荐引擎在 UI 线程同步算全库，排序时每次比较都重算字符串哈希 | 2 万首 247ms、5 万首 630ms 的整段冻结 | 发现页 |

D1 是「现在」的常驻卡顿源：它每时每刻都在。D3、D4 是操作时的冻结。

**这些不是新提的标准，项目自己已经写过：**

- `docs/lyrics.md` §2 的 D5 记着「播放位置一跳就整块重建」，当时只修了歌词面板
  （`activeLyricLineProvider`），底栏与播放页原样留着。D1 就是同一个毛病的另外两处。
- `docs/recommendation.md` §7.8 自己定了预算「1 万首曲目 100ms 内算完」，实测 1 万首
  已经贴着 100ms、2 万首 247ms、5 万首 630ms，超预算 6 倍。

发现页在 2026-10-24 有一轮重构（引擎拆成 `recommendation_*` 几个文件），已经把
「每个分段重排一次全序」改成「整库排一次 + 每段线性筛选」，也把打分换成归一化过的键。
D4 剩下的是排序里的哈希，见 §6。

## 2. 怎么测的

三个基准脚本在 `tool/perf/`，口径可复现：

```bash
flutter test tool/perf/recommendation_bench_test.dart   # D4：发现页计算耗时
flutter test tool/perf/rebuild_bench_test.dart           # D1：一次跳位置重建多少
flutter test tool/perf/library_bench_test.dart           # D3：扫描进度一步的代价
```

- D1/D3 用 `debugOnRebuildDirtyWidget` 数「这一帧重建了多少 element」，
  用 `Stopwatch` 量一帧的 build + layout 耗时。
- D4 用合成的库直接调 `RecommendationEngine.recommend`，量一次完整计算。
- 环境：Flutter 3.47.7 / Dart 3.13.5，Linux x64，**debug 模式**（JIT）。
  release 会快几倍，但 D1/D3 的重建**次数**与 D4 的**冻结时长**不变——
  卡顿是次数与结构决定的，不是 JIT 决定的。

### 实测数字

```text
D1  底栏（外壳 + 音乐库页）      一次跳位置重建 297 个 element，16.2ms
D1  正在播放页                  一次跳位置重建 304 个 element
D3  音乐库页 20000 首           一次扫描进度更新重建 2848 个 element，50.3ms
D4  发现页  1000 首              35ms
D4  发现页  5000 首              71ms
D4  发现页 20000 首             247ms
D4  发现页 50000 首             630ms
```

D4 的耗时分解（当前实现，2 万首 / 5 万首）：

```text
总计 216ms / 585ms
  ├─ 候选构建   28ms /  83ms
  ├─ 打分       30ms /  79ms
  ├─ 排序      120ms / 319ms   ← 占比最大
  └─ 分段筛选   38ms / 104ms
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

要动的文件：

| 文件 | 改什么 |
| --- | --- |
| `lib/features/player/application/playback_controller.dart` | 旁边加慢切片 provider（同一个 controller 派生） |
| `lib/features/player/presentation/player_dock.dart` | 整份 watch → 慢切片；进度拆出去 |
| `lib/features/player/presentation/now_playing_page.dart` | 同上；`_ProgressRow` / `_Transport` 拆成只订自己的 widget |
| `lib/features/player/presentation/lyrics_panel.dart` | 已经用 `activeLyricLineProvider`，不用动 |

### 判据

- 一次跳位置重建的 element ≤ 20（现在 297 / 304）。
- 底栏与播放页在没有跳位置时不再重建（订阅切片不变 → 框架不叫醒它们）。

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

- 一次扫描进度更新重建的 element ≤ 30（现在 2848）。
- `filteredSongs` 在同一份输入下只算一次（用计数器断言，或基准脚本对比）。

## 6. D4：推荐引擎在 UI 线程同步算全库

### 现象

打开发现页、点刷新、点「不感兴趣」、标一个心——每次都冻一下，
库里曲目越多冻得越久。

### 根因

引擎已经改成「整库排一次序 + 每段线性筛选」（`RecommendationSelection.sortByScore`），
打分也已经改用归一化过的键（`artistWeightKey` / `genreWeightKey`）——**这两处已经不是
瓶颈**。剩下的热点按占比：

1. **排序占一半以上**（2 万首 120ms、5 万首 319ms）。原因在比较函数
   `RecommendationSelection.compareAnchors`：每次比较都重算两个
   `stableHashOf('${uri}|$seed')`——字符串插值 + FNV 逐字符哈希，于是
   `O(n log n)` 次哈希与同等的字符串分配。2 万首约 57 万次比较、57 万次插值。
2. **候选构建**（28ms / 83ms）：每首解析流派、切分、归一化。
3. **打分**（30ms / 79ms）：每首算新鲜度与理由。
4. **分段筛选**（38ms / 104ms）：六个分段各扫一遍全库。

### 修法

按 `docs/recommendation.md` §7.8 自己写的顺序来：先优化同步计算，超限再上 isolate。

1. **稳定键预计算**：候选建好时算一次 `stableHashOf('$uri|$seed')`（O(n) 次），
   排序只比整数。哈希次数从 `O(n log n)` 降到 `O(n)`，
   排序这一项应从 120ms 降到 10ms 量级。
2. **仍超预算再上 `Isolate.run`**：文档 §7.8 已经写了「实测超限再考虑
   `Isolate.run`，不提前引入并发」——1 万首已经贴着 100ms 的预算，
   2 万首就是那个「超限」。

### 判据

- 1 万首 ≤ 100ms（文档预算），2 万首 ≤ 200ms，5 万首 ≤ 500ms。
- 排序一项在 2 万首 ≤ 20ms。
- 发现页的刷新按钮点了之后不冻结界面（计算不在 UI 线程，或已经快到无感）。

## 7. 三条硬规则（建议写进 AGENTS.md）

1. **快值与慢值分两条订阅通道。** 一份状态里既有 5 Hz 的值又有 0.1 Hz 的值时，
   读它的界面必须按频率分开订阅；只订阅自己真正要显示的那部分。
   订阅粒度是**读取口**的事，不是状态归属的事——状态仍然只有一个主人。
2. **派生计算要么有预算，要么挪出 UI 线程。** 同步计算的耗时要写进文档
   （像 `recommendation.md` §7.8 那样），超预算就换算法或换线程，不靠「读者不会
   有这么大的库」这种假设。
3. **UI 线程不做同步 I/O。** `existsSync()`、`readAsBytesSync()` 这类调用不进
   播放路径；桌面集成这类「每跳都会走」的路径上尤其不能有。

### 不要做的事

- 不要因为「少重建」给 `PlaybackState` 再加第二份 position（比如让 widget 自己存
  一个进度）——那会变成第二份事实来源，直接违反 `docs/architecture.md`。
- 不要用 `Future.delayed` / `addPostFrameCallback` / `setState` 把重建问题盖住
  （AGENTS.md §1.2 已经禁了）。
- 不要把「进度条」整块搬进 `PlaybackState` 之外的新状态对象——它就该是
  `PlaybackState` 的一个字段，只是读法要分开。

## 8. 落地顺序与风险

四件事互相独立，可以分开做、分开验：

| 顺序 | 做什么 | 收益 | 风险 |
| --- | --- | --- | --- |
| 1 | D1 订阅粒度 | 播放全程的卡顿（最大头） | 低：只改读法，不改状态归属 |
| 2 | D2 MPRIS | CPU 背景占用、去掉 UI 线程同步 IO | 低：Position 本来就是客户端轮询 |
| 3 | D3 音乐库页 | 扫描时的卡顿 | 低 |
| 4 | D4 推荐引擎 | 发现页冻结 | 低：预计算哈希后比较的值与顺序完全一致，分段结果不变 |

回退：每一件都是独立改动，`git revert` 即可，没有数据迁移，没有存储格式变化。

## 9. 相关文档

- `docs/architecture.md`：状态归属与「播放位置由 `PlaybackController` 独家持有」。
- `docs/lyrics.md` §2 D5：同一个毛病在歌词面板上的先例（已修）。
- `docs/recommendation.md` §7.8 与 §9.5 第 7 条：发现页的性能预算与验收标准。
- `docs/verification.md`：门禁。
- `tool/perf/`：三个基准脚本，本文所有数字都出自它们。
