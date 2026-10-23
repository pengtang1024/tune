# 播放队列浮层方案

> 状态：已实施 · 2026-10-23
>
> 目标：把播放队列从「一级导航 + 整页」收回播放器，变成随时打开、关闭后回到原处的侧栏。
> 队列的数据模型不动，`PlaybackController` 仍是唯一来源。

---

## 1. 结论

- 侧栏删除「播放队列」，只保留音乐库、喜欢、音源、设置。
- `/queue` 不再是一条路由，也不再是一页；旧深链接按现有的未知路径规则落到音乐库。
- 队列从底栏的队列按钮、正在播放页的队列按钮打开，作为**只锁内容区**的侧栏浮在内容区右侧。
- 打开队列时，底栏和侧栏仍然可点：可以边看队列边播放/暂停/切歌或切页面；当前页面的内容被遮罩压暗、不可点。
- 关闭方式：面板右上角关闭、Esc、点内容区遮罩、侧栏切页；Android 返回键也先关面板。
- 正在播放页有自己的宿主，复用同一块 `QueuePanel`，但由 router 组合，不新增跨 feature 的 presentation 依赖。

---

## 2. 现状与问题

| 位置 | 现状 |
| --- | --- |
| `lib/features/shell/presentation/app_sidebar.dart` | 「收藏」分组下是音乐库 / 播放队列 / 喜欢，队列占一个一级导航位 |
| `lib/app/router/app_router.dart` | `/queue` 是 `ShellRoute` 的子页面，替换右侧内容区 |
| `lib/features/queue/presentation/queue_pane.dart` | 有完整的 `PageHeading`（眉标「收藏」、大标题「播放队列」）和空状态 |
| `lib/features/player/presentation/player_dock.dart` | 队列按钮 `context.go('/queue')` |
| `lib/features/player/presentation/now_playing_page.dart` | 队列按钮 `context.go('/queue')`，会退出全屏播放页 |
| `docs/architecture.md` | 把队列写成「页面」的一部分，没有说明它和播放器的从属关系 |

问题不是「多了一个入口」，而是层级错了：

1. **队列不是收藏品**。它由 `PlaybackState` 派生，随会话变化；音乐库、喜欢才是资料库里的东西。
2. **看队列要离开当前页**。`context.go` 替换当前页面；从音乐库过去会丢掉浏览位置，从正在播放页过去会关掉全屏播放器。
3. **整页宽度浪费**。队列通常只有几首到几十首，读者是「瞄一眼、拖两下」，不需要一个大标题和整块画布。
4. **入口被拆散**。底栏、正在播放页、侧栏各有一个入口，侧栏那个还暗示队列是一个可以常驻的目的地。

原方案（`需求/紧凑播放器重构方案.md`）里，队列是右栏与音乐库并列的**页签**；后来壳层换成侧栏，它被顺手提升成了一级菜单。这次把它收回播放器。

---

## 3. 目标与非目标

### 目标

- 队列随时可达：底栏和正在播放页都能打开，不改变当前页面。
- 打开队列时底栏和侧栏仍然可用；内容区被遮罩压暗，点遮罩关闭。
- 保留现有队列能力：点播、拖拽重排、移除、清空、标心、双击标心。
- 在 760×520、900×600、1280×800 下不溢出；1.3 倍文字缩放不溢出。
- 不新增跨 feature 的 presentation 依赖；组合只发生在 `features/shell` 与 `app/router`。
- 不改 `PlaybackController`、`PlaybackState` 和队列模型。

### 非目标

- 不做保存式歌单、播放历史、持久化队列。
- 不重做音乐库、喜欢、音源、设置。
- 不把队列做成可拖拽调宽的常驻侧栏；本次宽度由布局规则决定。
- 不保留 `/queue` 的整页兜底；深链接按未知路径处理。

---

## 4. 交互与布局

### 4.1 入口

- **底栏**：队列图标改为 `onToggleQueue`，不再走路由；打开时图标进入选中态。
- **正在播放页**：顶栏队列图标切换本页的队列侧栏。
- **侧栏**：删除「播放队列」项；切换到其它页面时关闭队列侧栏，避免新页面上还压着旧页面的队列面板。

### 4.2 壳层里的侧栏

- 宿主位于**内容区**，不是整个窗口：
  - 左侧导航栏和底部播放条留在宿主外，始终可点。
  - 内容区被遮罩压暗：页面不可点，点遮罩关闭；底栏和侧栏在宿主外，仍然可点。
- 面板从右侧滑入（180ms，`easeOutCubic`），关闭时滑出；系统开启减少动态效果时不动画。
- 面板是圆角卡片，和底栏同一套视觉：
  - 宽度规则：`min(440, max(360, 内容区宽度 - 160))`，始终给页面留一条约 160px 的可见带；可用宽度不足时再按 12px 边距收紧。
  - 窗口宽度小于 800 时导航栏切到紧凑态（76px），让 760 的最小窗口也真的得到紧凑布局。
  - 上、右、下各留 12；圆角 18，边框 `outlineVariant`，阴影与底栏同一层次。
- 遮罩：`scrim` 约 28% 不透明度，只盖内容区；点遮罩关闭。

### 4.3 正在播放页里的侧栏

- 正在播放页没有底栏，宿主包住整页：
  - 遮罩盖住整页，点遮罩关闭；面板浮在右侧。
  - 面板宽度用同一套规则，按页面宽度计算。
  - 面板带一条迷你播放条（上一首 / 播放暂停 / 下一首 / 进度），因为页面自己的 transport 可能被面板盖住。
- 队列按钮切换本页的侧栏；关闭后仍在正在播放页。
- Esc：先关队列侧栏；队列已关时才退出正在播放页。

### 4.4 键盘与返回

- Esc 关闭队列侧栏；壳层和正在播放页各自处理，作用域清楚。
- Android 返回键：壳层用 `PopScope` 在面板打开时先关面板；正在播放页同理。
- 打开时焦点进入面板，内容区用 `ExcludeFocus` 排除；壳层的底栏和侧栏在宿主外，仍然可操作。
- 遮罩有 `barrierLabel`，读屏能读出「关闭」。

### 4.5 面板里的行

整页队列的宽行塞不进侧栏。面板行用紧凑信息结构：

- 第一行：标题。
- 第二行：歌手 + 来源徽标 + 时长。
- 保留：序号、封面、标题/歌手、来源、时长。
- 不显示：事实条（格式/音质/码率…）、详情按钮；这些信息仍在音乐库、正在播放页和曲目详情面板里。
- 操作：红心、拖拽柄、移除常显，不靠悬停；面板最窄也有 360 宽，按两行信息结构算得下。
- 拖拽柄有「拖动排序」提示和 hover 反馈；行尾移除用减号，和右上角关闭 X 分开。
- 打开时滚动到 `currentIndex`，长队列不会从第一首开始。
- 行高仍用 `listRowHeight`，与库列表保持同一节奏。

如果实现时发现某个宽度仍放不下，优先缩短第二行（来源徽标可以先隐藏），不要压标题字号。

---

## 5. 架构

### 5.1 状态

队列状态仍然是 `PlaybackState.queue` / `currentIndex` / `currentSong`，由 `PlaybackController` 独家持有。面板只 `ref.watch`，不改数据归属。

侧栏的「打开/关闭」不是业务状态：

- **壳层**：`CompactShell` 自己持有一个 `bool _queueOpen`。
- **正在播放页**：`_NowPlayingPageState` 自己持有一个 `bool _showQueue`。
- 不进 provider，也不持有 `BuildContext`；两个宿主各自管理自己的显隐。

### 5.2 组合与依赖

硬约束：`features/x/presentation` 不 import `features/y/presentation`。队列侧栏也不例外。

- `lib/shared/ui/side_panel_host.dart`：通用侧栏宿主，不依赖 queue、player 或任何业务状态。
  - 接收 `open`、`onClose`、`barrierLabel`、`child`、`panelBuilder`。
  - 负责遮罩、宽度、位置、进出动画和内容区焦点排除。
- `lib/features/queue/presentation/queue_panel.dart`：队列内容（头部、列表、空状态、清空确认、可选迷你播放条），接收 `onClose`。
- 不新增 `queue_overlay.dart`；浮层由宿主组合，队列 feature 只提供面板内容。
- `CompactShell` import `QueuePanel` 和 `SidePanelHost`，把内容区包起来；`QueuePanel` 不显示迷你播放条，因为底栏在。
- `app_router` import `QueuePanel`，给 `NowPlayingPage` 传一个 builder：
  ```dart
  NowPlayingPage(
    queuePanelBuilder: (context, onClose) =>
        QueuePanel(onClose: onClose, showTransport: true),
  )
  ```
- `PlayerDock` 与 `NowPlayingPage` 只声明回调，不 import queue 的 presentation：
  - `PlayerDock({VoidCallback? onToggleQueue, bool queueOpen = false})`
  - `NowPlayingPage({QueuePanelBuilder? queuePanelBuilder})`
  - `typedef QueuePanelBuilder = Widget Function(BuildContext, VoidCallback onClose);`
- 回调为空时按钮禁用，测试里的 `const PlayerDock()` / `const NowPlayingPage()` 不需要改签名。

### 5.3 为什么不用 `/queue` 路由

队列不是位置，是一条随时可收起的播放器侧栏。做成路由有三个麻烦：

- 冷启动直接落在 `/queue` 时，侧栏下面没有页面，背景是空的。
- 旧深链接会把「临时侧栏」当成一个可收藏的地址。
- 路由会参与返回栈，和「关闭侧栏」的语义混在一起。

侧栏用本地状态，系统返回键用 `PopScope` 接住；这样既不占 URL，也不会在返回栈里多出一层。旧 `/queue` 按现有规则落到 `/library`，这是有意的行为变化。

### 5.4 文件职责

| 文件 | 职责 |
| --- | --- |
| `lib/shared/ui/side_panel_host.dart` | 通用侧栏宿主：遮罩、宽度、位置、进出动画、内容区焦点排除 |
| `lib/features/queue/presentation/queue_panel.dart` | 面板内容：头部、列表、空状态、清空确认、可选迷你播放条；接收 `onClose` |
| `lib/features/queue/presentation/queue_track_row.dart` | 队列行；`dense` 两行信息、拖拽提示、减号移除 |
| `lib/shared/ui/track_meta.dart` | 曲目行身份；加 `dense` 模式（两行信息，去掉事实条与详情） |
| `lib/features/shell/presentation/app_sidebar.dart` | 删除队列导航项；加 `onNavigate` |
| `lib/features/shell/presentation/compact_shell.dart` | 持有 `_queueOpen`；内容区包 `SidePanelHost`；800 以下紧凑导航；Esc / `PopScope`；把开关传给底栏 |
| `lib/features/player/presentation/player_dock.dart` | 队列按钮改 `onToggleQueue`；打开时选中态 |
| `lib/features/player/presentation/now_playing_page.dart` | 持有 `_showQueue`；用 `SidePanelHost`；顶栏队列按钮；Esc 先关侧栏；传入带迷你播放条的面板 |
| `lib/app/router/app_router.dart` | 删除 `/queue` 路由与白名单；给 `NowPlayingPage` 传 `queuePanelBuilder` |
| `lib/app/theme/compact_tokens.dart` | 侧栏宽度、紧凑断点、面板宽度/留白/边距/圆角 token |
| `lib/l10n/app_*.arb` + gen-l10n 产物 | 删除 `queueSubtitle`；补 `queueReorderTooltip`、`favoritesEyebrow`、`sidebarBrowse` |

---

## 6. 实施顺序

每一步都保持可编译、可回退。

1. **通用宿主**：新增 `SidePanelHost`，先用一个空面板做 widget 测试，确认宽度、进出动画和 `panelBuilder` 行为。
2. **队列面板**：把 `queue_pane.dart` 里的列表/空状态/清空逻辑搬进 `queue_panel.dart`；`TrackMeta` / `QueueTrackRow` 加 `dense` 模式。暂时保留旧页面与路由，先让新面板能被单独渲染。
3. **壳层接线**：`CompactShell` 改为 Stateful，包 `SidePanelHost`；`AppSidebar` 加 `onNavigate`；`PlayerDock` 加 `onToggleQueue` / `queueOpen`。验证底栏和侧栏仍能操作、内容区被遮罩挡住。
4. **正在播放页**：`NowPlayingPage` 加 `queuePanelBuilder` 和 `_showQueue`；Esc 先关侧栏；`app_router` 传入带 `showTransport` 的 `QueuePanel` builder。
5. **收口导航**：删除侧栏队列项、删除 `/queue` 路由与白名单；`/queue` 深链接落到 `/library`。
6. **删旧页**：删除 `queue_pane.dart` 与相关 import，更新所有测试、截图工具和文档。
7. **门禁**：`flutter gen-l10n`、`flutter analyze`、`flutter test`、截图对比、Linux 实机走查。

---

## 7. 测试与验收

### 7.1 必须补的测试

在 `test/app/compact_layout_test.dart` 增补队列面板用例（不再单独建 `queue_panel_test.dart`）：

- 从底栏打开：面板出现，当前页仍在下面；**底栏的播放/暂停仍然可点**。
- 从底栏关闭：再点一次队列图标关闭。
- 侧栏切换页面：面板关闭，页面切换。
- Esc、关闭按钮、点内容区遮罩、返回键都能关；内容区不可点，底栏和侧栏仍可操作。
- 正在播放页打开：面板里的迷你播放条可以暂停/切歌；关闭后仍在正在播放页，不退出全屏。
- 长队列打开时定位到 `currentIndex`，当前曲目不在第一屏也能看到。
- 空队列：显示空状态；「去音乐库」关闭面板并落到 `/library`。
- 非空队列：点播、移除、清空、标心由 UI 测试覆盖；拖拽重排沿用原 `ReorderableListView`，数据由 `PlaybackController` 测试覆盖。
- 760×520 使用紧凑导航、面板宽 440；900×600 与 1280×800 无 overflow；1.3 倍文字缩放无 overflow。
- `/queue` 深链接落到 `/library`，且不会打开面板。

### 7.2 需要改的现有测试

| 文件 | 处理 |
| --- | --- |
| `test/app/router_navigation_test.dart` | 从页面循环里删掉 `/queue`；加「`/queue` 落到 `/library`」 |
| `test/app/compact_layout_test.dart` | 队列页测试改为从底栏打开 `QueuePanel`；不再断言「播放队列」出现两次 |
| `test/app/layout_alignment_test.dart` | 删掉队列整页与库列表的列对齐断言；改为断言面板宽度、标题省略、行内操作不溢出 |
| `test/app/localization_render_test.dart` | 队列部分改为渲染 `QueuePanel`（或打开壳层面板），确保面板也在语言守卫里 |
| `test/app/favorites_test.dart` | `PlayerDock` 不传回调时应能正常布局（队列按钮禁用即可） |
| `tool/layout_shots_test.dart` | 把 `queue` 页截图换成 `queue_panel` / `queue_panel_narrow`；窄屏改成真实的 760×520 |

### 7.3 手工验收

- 900×600、760×520、1280×800 各看一次浅色/深色。
- 中文、英文各看一次，长标题不溢出，按钮不换行。
- 从音乐库打开队列再关闭：滚动位置与筛选条件不变。
- 打开队列时点内容区会被遮罩挡住/关闭；底栏播放/暂停/上一首/下一首、侧栏切页仍可用。
- 从正在播放页打开队列：用面板里的迷你播放条暂停/切歌；关闭后仍在正在播放页。
- 长队列打开时看得到当前曲目。
- 队列里拖一首、移一首、清空一次、标心一次。
- 键盘：打开后 Esc 关闭；Tab 可以在面板、侧栏和底栏之间走，不会跑到被遮罩的内容区。

### 7.4 门禁

```bash
flutter gen-l10n
flutter analyze
flutter test
flutter test tool/layout_shots_test.dart
flutter run -d linux
```

---

## 8. 文档同步

- `AGENTS.md`
  - 项目快照改成现在的壳层：左侧导航 + 右侧内容 + 底部播放条；队列是播放条打开的侧栏，不是导航页。
  - 文档地图加一行指向本文件。
- `README.md` / `README_en.md`
  - 开头「左侧常驻播放器，右侧在音乐库、队列、设置之间切换」已经和现在不符；改成侧栏导航 + 内容区 + 底栏播放器 + 队列侧栏。
- `docs/architecture.md`
  - 目录结构里把 `queue_pane.dart` 换成 `queue_panel.dart`。
  - 「页面之间的切换只有路由一处」补一句：侧栏不是页面，队列侧栏由 shell/router 组合，不占导航。
  - 「状态归属」里补一句：队列的呈现不拥有状态，仍读 `PlaybackController`。
- `需求/紧凑播放器重构方案.md`
  - 在「播放队列」页签和 `/queue` 路由两处加日期注记：该呈现已被侧栏取代，细节见本文件；保留原文作为当时的方案。
- `docs/verification.md`
  - 如果新增了侧栏截图，补一句截图文件名与查看方式。

---

## 9. 风险与取舍

| 风险 | 处理 |
| --- | --- |
| 两个宿主（壳层、正在播放页）各写一次开关 | 面板内容与宽度都走 `SidePanelHost` / `QueuePanel`，宿主只负责显隐 |
| 面板盖住页面右侧 | 面板始终给页面留约 160px；内容区被遮罩挡住，底栏/侧栏仍可点；正在播放页用迷你播放条补上被盖住的 transport |
| 侧栏宽度挤压标题 | 两行信息 + 440 上限 + 160 页面留白 + 800 紧凑断点 |
| 点内容区遮罩会关闭面板 | 这是有意的关闭动作；内容区本身不响应其他点击 |
| 删除 `/queue` 改变深链接 | 有意为之；队列不是可收藏的位置，旧链接落到音乐库 |
| `PopScope` 与页面路由的返回栈相互影响 | 只在面板打开时拦截返回；面板关后恢复原有行为 |
| 工作区有未提交修改 | 实施时以当前文件为准，不回退无关改动；先 grep 引用再删旧页 |

---

## 10. 验收标准

- 侧栏不再有「播放队列」，`/queue` 不再是路由。
- 从底栏和正在播放页都能打开队列侧栏；关闭后回到原页面，不丢滚动位置、不退出全屏播放器。
- 打开队列时底栏播放/暂停/上一首/下一首、侧栏切页仍然可用；内容区被遮罩挡住，点遮罩关闭面板。
- 队列的点播、重排、移除、清空、标心全部保留；长队列打开时定位当前曲目。
- 正在播放页的面板带迷你播放条，关闭后不退出全屏。
- 760×520 使用紧凑导航、面板宽 440；900×600 / 1280×800、浅色/深色、中英文、1.3 倍文字缩放都不溢出。
- `flutter analyze` 无问题，`flutter test` 全绿，截图与实机走查通过。

---

## 11. 实施记录

- `lib/shared/ui/side_panel_host.dart`：内容区遮罩、宽度规则、12px 边距、进出动画、内容区焦点排除。
- `lib/features/queue/presentation/queue_panel.dart`：紧凑头部、列表、空状态、清空确认、长队列定位、可选迷你播放条；`QueuePane` 已删除。
- `TrackMeta` / `QueueTrackRow`：`dense` 两行信息；拖拽提示与 hover；减号移除；事实条与详情按钮只在整页行显示。
- `CompactShell`：本地 `_queueOpen`；800 以下紧凑导航；内容区遮罩，底栏和侧栏保持可操作；Esc 与 `PopScope` 关闭。
- `NowPlayingPage`：本地 `_showQueue`，`queuePanelBuilder` 由 `app_router` 注入；Esc 与系统返回都先关侧栏；面板带迷你播放条。
- `app_router`：删除 `/queue` 路由与白名单；深链接落到 `/library`。
- 文案/图标：侧栏分组「浏览」、音乐库「资料库」、喜欢「收藏」；单曲入队用 `add`、整列表入队用 `playlist_add`；底栏队列激活态改中性底 + 主色描边。
- 测试：`test/app/compact_layout_test.dart` 覆盖面板开关、底栏/侧栏可用、内容区不可点、侧栏切页、Esc/遮罩/返回、长队列定位、空队列、1.3 倍英文、迷你播放条与正在播放页；`layout_alignment_test` 覆盖面板宽度与行边界；`localization_render_test` 渲染面板；`router_navigation_test` 覆盖深链接。
- 门禁：`flutter gen-l10n`、`flutter analyze`、`flutter test test/app/...`、`flutter test tool/layout_shots_test.dart` 均通过；全量 `flutter test` 中两项线上音源 live 测试受网络影响失败，与本改动无关。
- 截图：`build/layout-shots/queue_panel*.png`、`now_playing_queue*.png`；窄屏为 760×520。
