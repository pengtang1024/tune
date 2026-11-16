# 健康度能不能决定“进不进音乐库”

> 状态：设计（已实施） · 适用版本 1.45.1 · 最后核对 2026-11-17

> 现在健康度只是一张评分表：它给每个来源打分、给推荐降权，但从不影响音乐库里有什么。
> 这份方案把“分低的来源默认不进库”做成一条可控、可回退、有性能预算的规则。

## 目录

- [1. 目标](#1-目标)
- [2. 现状与两个前置问题](#2-现状与两个前置问题)
- [3. M1 事实改为库内聚合](#3-m1-事实改为库内聚合)
- [4. M2 门槛与例外](#4-m2-门槛与例外)
- [5. M3 过滤落在 SQL](#5-m3-过滤落在-sql)
- [6. M4 可观测与回退](#6-m4-可观测与回退)
- [7. 性能预算与验收](#7-性能预算与验收)
- [8. 明确不做](#8-明确不做)
- [9. 里程碑](#9-里程碑)

## 1. 目标

- 健康度低于门槛的来源，曲目**默认不进音乐库**：不出现在列表、计数、专辑墙、搜索与筛选项里。
- 它们的曲目仍然**可访问**：在音源页可见、可播放、可「只看这个来源」，也能一键把某个来源放回库里。
- 默认值替读者做判断，但读者随时能推翻；关掉开关即恢复原状，**不需要重扫、不改库**。

## 2. 现状与两个前置问题

健康度现在的形状（`lib/features/sources/domain/source_health.dart`）：九个维度加权成 0–100，
`healthy` 是 ≥60。`sourceHealthReportsProvider` 把它们算出来，音源页展示、发现页拿分数降权。

要让它决定“进不进库”，先得修两个前置问题，否则规则会建立在错的数上：

1. **事实是从 1000 行窗口里数的。** `sourceHealthFactsOf(library.songs)` 只读
   `LibraryState.songs` 这一个窗口（`windowSize = 1000`）。一个 5000 首的来源只被数到 1000 行，
   换成按标题排序就换一批行进窗口 —— 同一来源的健康度会随排序波动。
2. **过滤会自己喂自己。** 一旦按分数隐藏来源，事实又只从“未隐藏的行”里数，
   藏得越多事实越差、分数越低、藏得更多。必须先把事实的来源改成与展示无关的库内聚合。

## 3. M1 事实改为库内聚合

- `LibraryStorage` 新增 `Future<Map<String, SourceHealthFacts>> sourceFacts()`：一条
  `SELECT source_id, COUNT(*), SUM(可播放), SUM(封面), SUM(艺人), SUM(专辑), SUM(年代)` 的
  `GROUP BY source_id`，收藏用 `favorites` 表 join 出 `activity`。
- 结果写进 `LibraryState.sourceFacts`（来源数 ≤ 50，一份小 map），`sourceHealthReportsProvider`
  改读它，`sourceHealthFactsOf(songs)` 退化为“无聚合时的兜底”。
- 重算时机：扫描结束、来源增删、收藏变化（走现有节流）。**不进每帧路径。**

## 4. M2 门槛与例外

新增 `lib/features/sources/domain/source_visibility.dart`，纯函数，唯一的判断处：

```dart
Set<String> hiddenSourceIdsOf({
  required Map<String, SourceHealthReport> reports,
  required Set<String> pinned,
  double threshold = 0.55,
  String? playingSourceId,
});
```

永不隐藏的对象（写死在函数里，页面上不能各写一套）：

- 本地来源；
- `hasTracks == false` 或事实缺失（`unknown`）的来源 —— 没有证据不等于有罪；
- 正在播放的来源，以及被读者手动「始终显示」的来源（`pinned`）；
- 音乐库为空时全部显示。

## 5. M3 过滤落在 SQL

- `LibraryFilter` 增加 `Set<String> excludeSources`，**不写进 `view.json`**（它是派生规则，
  不是读者偏好）；每次 gate 变化时由控制器注入。
- `library_filter_sql.dart` 追加一条谓词：`AND source_id NOT IN (?, …)`，
  走已有的 `idx_songs_source`（`app_database.dart:76`）。
- `countQuery` / `facets` / `missingDurationCount` 用**同一个**谓词，页头数字必须与列表一致；
  `albumSummaries` 也从过滤后的行算，否则会留下空专辑。
- 来源集合变化才触发一次窗口重查（复用 `_reloadForFilter`），不给每行加判断。

## 6. M4 可观测与回退

- 页头：`已隐藏 N 首 · 来自 M 个来源`，点开跳到音源页；只在 `N > 0` 时出现。
- 音源页：被隐藏的来源整行置灰，带「显示此来源」按钮（写 `pinned`）。
- 设置 · 健康度卡片：一个「按健康度隐藏低分来源」开关 + 门槛三档（严格 0.65 / 默认 0.55 / 宽松 0.45）。
- 关掉开关 = 立即恢复全量：只清 `excludeSources`，不动数据库、不重扫。

## 7. 性能预算与验收

| 路径 | 预算 | 依据 |
| --- | --- | --- |
| `sourceFacts()` 一次聚合 | 5,000 行 ≤ 50 ms | 同量级的 facets 实测 386 ms 是五万行同步计算；这条只做计数 |
| gate 重算 | O(来源数)，≤ 50 次比较 | 纯内存 |
| 过滤后的窗口重查 | 与现有筛选同一路径 | 已有 1000 行窗口与 `idx_songs_source` |
| 行预算 | 不回归 170 / 190 | `test/app/row_budget_test.dart` 原样通过 |

验收：

- 藏起来的来源，其曲目不出现在列表、计数、专辑墙、搜索；
- 音源页仍能列出并播放它们；点「显示此来源」后立刻回到列表；
- 聚合在扫描后只跑一次（用日志与计时断言）；
- 关掉开关后总数与开关前一致。

## 8. 明确不做

- 不删数据、不改库结构、不动扫描策略；
- 不改推荐的降权逻辑（`healthFactor` 已经是另一条独立口径）；
- 不做“按单曲健康度隐藏”（健康度是来源级事实，曲目级没有独立证据）。

## 9. 里程碑

1. M1：`sourceFacts()` + provider 改读聚合 + 事实不再随排序波动（无 UI 变化）；
2. M2：gate 纯函数 + 单测（阈值、四类例外、pinned）；
3. M3：SQL 谓词 + 计数一致 + 专辑墙一致；
4. M4：页头提示、音源页置灰与「显示此来源」、设置开关；
5. 一次发 1.46.0（feat → minor）。

## 相关文档

- [健康度：unknown 应该算负面](health-unknown.md) — 未知维度为什么按 0.25 计
- [音源设计](../需求/音源设计.md) — 健康度的维度、权重与排序
- [数据模型](data-model.md) — `songs` / `favorites` 的列与索引
- [性能](performance.md) — 列表与查询的既有预算
