# 列表行的性能设计（D5）

> 2026-10-25。D1–D4 已闭环；这一页只谈 D5：音乐库列表滚动时，
> 一行 293 个 element、8 个提示各自带一个 `OverlayPortal`。
> 这一页是设计与实施记录：提案在先，数字在落地后按实测改写。
>
> **实施记录**：D5 已落地，实测一行 162 个 element、空闲 0 个 overlay、
> 滚动一步 85 → 23ms；一次收藏重建 3751 → 87 个 element。最初写的
> ≤150 是拿掉全部提示后的数字；在保留提示与三个动作时到不了，拆解与
> 理由见 [`performance.md`](performance.md) §7。

## 1. 目标

把「滚进一行要新建什么」从

- **293 个 element / 行**
- **8 个 overlay / 行**

降到

- **≤150 个 element / 行**（原目标；按实测改为 200，依据见 §8）
- **空闲 0 个 overlay**（整个视口最多 1 张提示卡片）

同时守住四条现行约束：

1. 提示开着换主题，卡片当场跟着换（`docs/conventions.md`「提示」）。
2. 键盘焦点、Enter/Space、读屏标签不回退。
3. 播放/队列/收藏仍然只有一个事实来源（`docs/architecture.md`）。
4. 20k 首 profile 滚动：p99 ≤16.7ms，jank 帧 <1%。

## 2. 现状不是「widget 慢」，是四处归属错了

| 现在归谁 | 应该归谁 | 代价 |
| --- | --- | --- |
| 行自己用 `LayoutBuilder` 发现宽度 | 视口解析一次 `LibraryRowMetrics` | 每行一次 layout 回调、断点分散 |
| 每个提示自己持有 `RawTooltip` + `OverlayPortal` | 视口一个 `HintLayer` | 一行 8 个 overlay、8 个 Listener |
| 行用 `IconButton`（页面按钮） | `DenseIconAction` 密集原语 | 3 个按钮约 170 个 element |
| 行内各自决定文案/空值/格式 | presenter 一次解析（可选） | 重复分支、行难测 |

实测（20000 首，debug，120px 拖拽 3 次中位）：

| 变体 | element/行 | 拖拽 |
| --- | ---: | ---: |
| 现状 | 293 | 85ms |
| 去掉 8 个提示 | 237 | 73ms |
| 动作换 `InkResponse`（保留提示） | 218 | 76ms |
| 去掉整块动作区 | 123 | 58ms |
| 两者都去掉 | 88 | 48ms |

结论：动作区是大头，提示是第二；element 数与耗时不成正比。
所以**帧时间优先，element 只作守卫**——D1 已经证明过重建量不等于掉帧。

## 3. 设计原则

1. **视口管几何**：宽度断点、行高、可滚动区域由视口解析，行只消费。
2. **窗口管提示**：触发器只表达「这里有一条提示」，不持有卡片和 overlay。
3. **密集行用密集原语**：列表动作走 `DenseIconAction`，页面按钮留在页面。
4. **行是纯组合**：无 I/O、无计时器、无 overlay 生命周期、无第二份状态。
5. **预算是架构**：行、动作、提示、帧各有数字，测试守，不靠自觉。
6. **先量后改**：先分 `BUILD / LAYOUT / PAINT / RASTER`，再决定动哪层。
7. **不为 120 自绘行**：150 是设计预算；120 需要砍内容或自绘，属产品/渲染决策。

## 4. 架构

```text
LibraryPane（视口）
  ├─ LibraryRowMetrics（宽度、textScale → 显示列、行高）
  ├─ LibraryRowHints（可选：文案/空值的唯一出口）
  └─ ListView.builder(itemExtent: metrics.extent)
        └─ LibraryTrackCard(song, metrics, hints)
              ├─ TrackPosition / ArtworkThumb
              ├─ 文本列（HintTrigger）
              ├─ TrackFactStrip（HintTrigger × n）
              └─ RowActionGroup（DenseIconAction × 3）

HintLayer（应用壳层作用域，可嵌套）
  ├─ HintController：同一时刻只有一条活动提示
  ├─ 卡片：在 overlay 里读主题，主题一变就重画
  └─ HintTrigger：MouseRegion + Semantics + Listener，无 portal
```

依赖方向：`shared/ui` 不依赖任何 feature；`HintLayer` 只认识
`HintIntent`（文案、语义标签、锚点矩形、延迟），不认识 `Song`、音乐库。

## 5. ADR-1：提示从「每处一个」改成「一层」

**选项**

- A. 保留每处 `RawTooltip`：否决，密集列表不可扩展。
- B. 每行一个宿主（1 个 portal/行）：迁移步骤，不是终态。
- C. 视口/窗口一个宿主（空闲 0 个 portal）：**采用**。

**契约**

- `HintIntent`：`message`、`semanticsLabel`、`anchorRect`、`delay`。
- `HintController`：`show(intent, owner)`、`hide(owner)`；新意图替换旧意图。
- 触发器保留 `Semantics(tooltip:)`；卡片 `ExcludeSemantics`，读屏不重复。
- 卡片在 overlay 的 build 里读主题，因此开着的提示也跟主题。
- 锚点用显示时的全局矩形，**不用每触发器一个 LayerLink**。
- 隐藏时机：指针离开、滚动、路由切换、窗口尺寸变化、点击空白。
- 延迟/淡入淡出沿用 `TooltipTheme`；触屏长按行为保持。
- `TuneTooltip` 是 `HintTrigger` 的类型别名，调用点不改；卡片归 `HintLayer`。

**收益**：空闲时行里 0 个 overlay；每个触发器约 3 个 element（现在约 7 个）；
一行省 40–50 个 element，且提示层可被队列、搜索复用。

**风险**：行为等价最难。主题跟随、延迟、触屏、滚动隐藏都要有测试；
如果视口层锚点有问题，退回「每行一个宿主」，契约不变。

## 6. ADR-2：密集动作是一个原语，不是被改小的按钮

**选项**

- A. 继续 `IconButton` 改 padding/style：否决，M3 按钮链仍是约 57 element/个。
- B. `DenseIconAction`：`InkResponse` + `SizedBox.square(24)` + `IconGlyph(16)`，
  **采用**；`InkResponse` 自带 `Focus / Actions / MouseRegion / ripple`。
- C. 一个自绘的动作组：暂不采用；键盘与语义复杂度高，profile 证明必要再说。

**契约**

- 状态：enabled / hover / focus / pressed / selected。
- `Semantics(button: true, label: ..., enabled: ...)`；提示走 `HintTrigger`。
- 键盘 Enter/Space 可激活；焦点可见；24×24 命中区。
- 颜色由 `tone` 决定，不读页面按钮主题；无页面级 `ButtonStyle`。
- 先只用于 `dense: true` 的列表行；页面上的 `IconButton` 不动。

**收益**：3 个动作从约 170 个 element 降到 72 个（每个 24，含提示），
ripple/焦点/键盘保留。**风险**：焦点环与 ripple 形状；用 golden + 键盘测试守。

## 7. ADR-3：行度量由视口解析一次

`LibraryRowMetrics`（不可变）：

- `showArtist`（≥480）、`showFacts`（≥600）、`showAlbum`（≥820），沿用现行阈值；
- `extent`：`textScale == 1` 时为 `CompactTokens.libraryRowHeight`，否则 `null`；
- `padding`、列 flex 也收进来，行里不再出现断点数字。

`ListView.builder(itemExtent: metrics.extent)`；大字号时 `extent` 为 `null`，
不会裁字。行里删除 `LayoutBuilder`。`Stack` 常驻，选中的行只在里面多一条
2 像素标记：播放状态一变，行的树形不能跟着变，否则双击的第二次点击会落进
一个新的点击区，曲目被播放而不是被收藏。

**收益**：每行少一次 layout 回调，列表偏移可预计算，行组合更纯。
**风险**：阈值漂移与大字号；用 760/900/1200 宽 + 1.0/1.3/2.0 字号 golden 守。

## 8. 预算与验证

| 对象 | 预算 | 怎么守 |
| --- | --- | --- |
| 一行（典型：8 条提示、2 个事实） | ≤170 element（实测 162） | `row_budget_test.dart` |
| 一行（带音源：10 条提示、3 个事实） | ≤190 element（实测 182） | 同上 |
| 一行（多事实：10 条提示、4 个事实） | ≤190 element（实测 176） | 同上 |
| 一行空闲 overlay | 0 | 同上，数 `OverlayPortal` |
| 一个动作（含提示） | ≤25 element（实测 24） | `dense_action_test.dart` |
| 一个动作（本体，不含提示） | ≤20 element（实测 19） | 同上 |
| 一次收藏重建 | ≤120 element（实测 87，一行） | `library_rebuild_test.dart` |
| 一条提示 | 全局 1 张卡片、1 个 overlay | `hint_layer_test.dart` |
| 20k 滚动 | profile p99 ≤16.7ms、jank <1%；debug 一步中位 ≤30ms（实测 23） | `library_scroll_bench_test.dart` + profile 时间线 |
| 回归 | D1 18/20、D3 53、D4 129ms | 现有测试 |

行为测试：提示开/关/换主题、滚动隐藏、路由切换、长按、读屏标签；
动作的 hover/focus/Enter/Space/disabled；行的三档宽度与三档字号。

基准已经修好：`tool/perf/library_scroll_bench_test.dart` 先挂 `Scaffold` 与
`HintLayer`，一次滚 10 步取中位，并在末尾断言没有异常。它同时打印一行多重、
一行空闲几个 overlay，数字与上面的预算表对得上。

## 9. 迁移顺序（每步独立、可回退）

0. **设计与证据**：修基准、profile 20k、评审本文。不改产品代码。
1. **提示层**：`HintLayer` + `TuneTooltip` 入口，先迁一个低风险界面，做行为矩阵。
2. **密集动作 + 行度量**：库行先用；行目标 ≤180，profile 复测。（已完成）
3. **行组合**：事实条/文本列改用 `HintTrigger`；视需要引入 `rowHintsOf`；行目标 ≤170。（已完成）
4. **复用与收尾**：队列的删除按钮已改用同一原语；搜索面板的动作仍是页面
   尺寸，留作它自己的布局决定；更新 `performance.md` §7、`conventions.md`、
   `AGENTS.md` 地图。（已完成）

回退：提示层藏在 `TuneTooltip` 后；动作只在 `dense: true`；度量是加法；
没有数据/存储变化，每步 `git revert` 即可。

## 10. 不做什么

- 不为少重建给 `PlaybackState` 加第二份 position（违反 `architecture.md`）。
- 不给每一行新建 Riverpod provider；行只订阅已有的 provider，不把行状态搬进 widget 本地 state。
- 不为了 120 写自绘行；预算没到先看 profile 的桶。
- 不加多余的 `RepaintBoundary`：`ListView.builder` 默认已经加了。
- 不在没量到 raster/图片解码时做预取、缩略图 LRU 或 isolate。

## 11. 已定的事

1. **滚动时提示**：滚动即隐藏；提示的锚点不跟着行跑。
2. **预算**：150 撤回，判据按实测改为典型行 ≤170、最重行 ≤190。150 只有在
   砍掉标题/艺人/专辑提示时才到得了，那是产品取舍，不是性能优化。
3. **事实提示**：每个事实保留自己的一条；整条事实带共用一个提示会丢掉
   单个名字的含义。
4. **范围**：库行先做；队列的删除按钮一并迁移；搜索面板的页面按钮不动。
5. **触屏**：长按提示与以前一致（`hint_layer_test.dart` 守着）。
