# Tune 桌面端 UI 视觉审计

> 日期：2026-11-04 · 范围：Linux 桌面 · 方式：只读（真机截图 + 代码取证）
> 代码基线：当前工作区（含他人未提交修改，本轮未改动、未提交）
> 截图见 [`outputs/`](./outputs/)；文中 `E01…` 指向文末[证据索引](#证据索引)。

## 一、结论

### 最值得做的 5 项

| # | 改进 | 类型 | 视觉收益 | 成本 | 风险 |
| --- | --- | --- | --- | --- | --- |
| 1 | 列头放回行网格；行尾拆成固定三格（音源 / 时长 / 红心） | 可直接执行 | 高 | 低 | 低 |
| 2 | 把 5–6 套「选中 / 激活」收编为 3 套语义配方，并统一 hover / focus | 可直接执行 | 高 | 中 | 低 |
| 3 | 工具条控件系统化：34 高、8 圆角、一套文字、来源筛选写出当前值 | 可直接执行 | 高 | 低 | 低 |
| 4 | 删除列表上方的扫描状态行，改为页头下 2px 线 + `⋯` 圆点 | 可直接执行 | 中高 | 中 | 低 |
| 5 | 页头阶梯收敛（24 vs 38、眉标去留） | **需决策** | 高 | 中 | 中 |

**一句话方向：** 问题不在配色，而在同一套设计语言没有共用同一张网格、同一套状态配方和同一批组件；先把这三件系统性收敛，再做单点美化。

**为什么是这 5 项**

- 第 1 项是截图里最刺眼的：列头「标题」悬在封面之上，列头「时长」落在红心列，行尾音源图标在新列表里排不成一列。三处都由同一类原因造成——列头与行没有共用 `LibraryRowMetrics` 的尾部几何。
- 第 2 项决定「点哪里、选中的是什么」是否读得懂。现在侧栏、设置导航、工具条、视图切换、播放器动作各有一套选中样式，换页就像换产品。
- 第 3 项是同一屏里最密集的控件区，也是唯一一处文档已经写死、代码却没执行到的地方（34 高 + 8 圆角 + 来源筛选写出当前值）。
- 第 4 项既违反文档，也直接造成列表下移与「漂浮说明」，是低成本的结构清理。
- 第 5 项视觉收益很高，但要先拍板「一级导航页用 24 还是 38」，因此单列。

## 二、逐维度结论

### 1. 对齐与居中

- **列头与行不是一张网格。** 行在 `ListView` 的 24px `pageGutter` 内，列头在它外面，只有自身 8px padding；推导偏移正好是 24 逻辑像素。截图 S1/S2 中「标题」在封面上方而不在标题文字上方。证据 E01/E02，规范见 E18（`docs/conventions.md` 要求标题、工具条、列表共用同一条左缘）。
- **尾部列也没有对齐。** 行尾是 `[音源][时长][红心]` 右对齐并套 `FittedBox`，没有 44px 的固定时长槽；音源标左缘随每首时长字符数漂移（同一屏实测相差约 25 个图像像素）。列头把整块 102 当成一列右对齐，于是「时长」标签落在红心列，和数字右缘差 28 逻辑像素（24 红心 + 4 间距）。证据 E01/E03/E04。
- **扫描状态行是居中的。** 它被外层 `Column`（默认居中）包住，内部又是 shrink-wrap 的 `Column`，于是整条说明浮在页面中上部，而不是贴着 24px 左缘（S1/S2）。证据 E02/E06。
- **时间标签有两套光学中心。** 底栏 `width 38 + 居中`，正在播放 `width 46 + 默认左对齐`；后者的左标签右侧留 16px 空白、右标签左侧贴 slider，整组看起来向右偏。证据 E12/E13。
- **等宽数字本身合格。** 时长、日期、统计、列头都走 mono；问题只在固定槽与标签位置，不在字体。
- **图标居中未发现系统性问题。** 34/30 容器内基本居中；只有底栏同排 18/20/18 的图标重量不齐（见 P2）。

### 2. 字号与字重阶梯

- **两级页面标题并存。** `PageHeading` 是 mono 红色眉标 + `displayLarge` 38（favorites / sources / discovery），音乐库与设置是 `displayMedium` 24、无眉标（S3 vs S4）。另有一个人人可用的 `SettingsPageHeader` 38 实现，已无引用。证据 E07/E08/E10，规范见 E18（音乐库文档要求删眉标、只留一个大标题）。
- **行内层级倒置。** 标题 `bodyMedium` 14 / w500（选中 w600），次行 `labelMedium` 12 / **w600**；次行颜色虽已变淡，字重却比标题更响。证据 E04，截图 S1。
- **工具条有三种文字语言。** 排序是 mono 11，筛选是 label 12 / w600，来源筛选只有 16 + 14 两个图标（当前值算出来了却没画）。证据 E05。
- **没有硬编码 `fontSize`。** 全仓 features 的字号都走 `CompactTypography` / `TextTheme`；但存在硬编码尺寸 64 / 102 / 46 / 38 / 34，其中 64 与 102 是网格常量的复制（见第 1、7 维）。

### 3. 间距节奏

- **主干刻度是统一的：** 页头 40 / 工具条 34 / 行 32 / 行动作 24 / 页边 24 / 间距 4-6-8-10-12-14-16-18-20-24-32 都来自 `CompactTokens`。
- **控件形状不统一：** 工具条里同时有 8（搜索 / 排序 / 来源 / 视图切换）与 10（筛选按钮）；主题里的输入框是 12，按钮是 12 / 10 / 9，对话框 22，chip 是 stadium。全站没有「控件圆角」的单一来源；规范 E18 已写死工具条 34 + 8。证据 E05/E17。
- **局部仍有随手值：** 卡片头 3 / 9 / 11 / 18、侧栏 10 / 34、底栏 3 / 6，未落在同一套 4 的倍数刻度上。证据 E10/E11/E12。
- **插入式布局造成跳动：** 扫描行按状态插入 2–20px，列表整体下移；规范要求进度线不占布局高度（E18）。证据 E06。

### 4. 颜色

- **对比度达标。** 用令牌对计算：浅色正文 15.48、次要最小 5.14、primary 5.57；深色 16.03 / 6.06 / 6.35；error 5.86 / 7.48；tertiary 11.18 / 5.50。关键文本对全部 ≥ 4.5。
- **两处硬编码颜色。** 设置预览卡写死浅色 accent `#E6532F`（真实浅色 primary 是 `#A83616`），另有一条 `#6B6256` 发丝线；预览因此和真实主题不一致。证据 E22/E17。
- **红色语义被音源占用。** `openCatalog` 映射到 `FactTone.primary`，互联网目录音源的 18px 标全是强调红（S1 每行的音源标），与「红色只标记正在发生」冲突；`docs/library-redesign.md` 与 `docs/chips.md` 在这里自相矛盾，需拍板。证据 E16/E18。
- **第三语义色未定。** `tertiary` 由 `fromSeed` 生成，`LiveBadge` 直接依赖它；换 seed 直播色会漂移（见 P2）。

### 5. 状态表达

- **「选中 / 激活」有 5–6 套：** 侧栏 0.12 + r12 + h40；设置导航 0.10 + 2px bar + r8 + h36（这是 `docs/settings-redesign.md` 的既有决策）；工具条来源 0.12 + 0.4 边；筛选 0.4 边 + primary 字；排序 neutral + primary 箭头；chip 0.22 / 0.13 stadium。证据 E09/E11/E05/E19/E18。
- **行状态是统一的（好）：** 音乐库与队列都是「0.06 tint + 2px primary 左条」，播放钮由行自己订阅，悬停 0.04。证据 E04/E14。
- **hover 三套、focus 两套：** 行 accent 0.04、`DenseIconAction` onSurface 0.06、`IconButton` 走 M3 默认；focus 有 primary 0.16 与默认 overlay。证据 E20。
- **disabled 一致**（统一走 M3 0.38）；**空态 / 加载一致**（`EmptyStateView` 6 处、`CompactSpinner` 11 处，没有第二套手写实现）。

### 6. 密度与呼吸

- **该守住的都守住了：** 32 行高、24 行动作、88 底栏、34 工具条都没有被放大；1440×860 下可见区约 18 行，密度合适。
- **挤的地方：** 760 宽工具条 5 组控件挤在 648px，搜索只剩约 125px（S2）；设置健康度卡在 1440 下仍是 8–9 列 11px 标签 + 百分比（S3）。
- **莫名空的地方：** 喜欢页数据少时下方大块空白（数据少，正常）；设置页右侧卡片留白（正常）。真正的问题是页头 38 + 眉标 + 副标让「喜欢」比「音乐库」重一头，和内容量不匹配。
- **扫描行与筛选 chip 行都是插入式**，是列表跳动的主要来源。

### 7. 复用性

- **三套同形徽标：** `SourceBadge`（18/22，alpha 0.10/0.26，icon 11/13）、`AudioSourceBadge`（0.12/0.28，11/13）、`LiveBadge`（0.14/0.30，12/14）。几何相同，透明度与图标各差一档。证据 E15。
- **两套时间标签**（底栏 38 居中 / 正在播放 46 左对齐）。证据 E12/E13。
- **两套设置卡片语言：** 页面实际渲染的全是 `SettingsPanel`（r12 / p12）；`SettingsCard` 的带框分支（r20 / 编号 / 眉标 / 描述）只在自定义 sheet 内被 `SettingsSheetScope` 短路，等于一套不渲染的并行实现，却仍有 7 个调用点。证据 E10。
- **死代码：** `LibraryRowActions`（无引用）、`SettingsPageHeader`（无引用）、关于卡版本 pill 的红色 dead dot。证据 E21/E10。
- **做得好的复用：** `EmptyStateView`、`CompactSpinner`、`TuneTooltip`、`TrackPosition`、行状态；不需要再造。

## 三、完整清单（可直接执行）

| # | 问题 | 证据（截图 + 代码） | 具体改法 | 影响范围 | 成本 | 风险 | 收益 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P0-1 | 列头左移 24px；「时长」落在红心列；音源标随数字漂移；64/102 常量复制 | S1、S2；E01–E04、E18 | 列头移入 24px gutter（或成为列表首项）；`LibraryRowMetrics` 导出 `addedWidth` / `tailWidth`；列头尾部拆成 `[18][44][24]` 子格；活动列箭头预留 16px 槽；删除 `_addedWidth=64` / `_tailWidth=102` | `library_column_header.dart`、`library_row_metrics.dart`、`library_row_tail.dart`、`library_pane.dart` + 列头/行测试 | 低 | 低 | 高 |
| P0-2 | 工具条控件 8 / 10 两种圆角、3 种文字；来源筛选不写当前值 | S1、S2；E05、E18 | 新增 `controlRadius = radius8`，搜索框不再单独覆盖；排序改 label 12（mono 只留给数字）；来源筛选宽窗写当前值；「筛选」与「来源」共用同一 active 配方 | `library_toolbar.dart`、`compact_theme.dart`、工具条测试 | 低 | 低 | 高 |
| P0-3 | 选中/激活 5–6 套、hover 3 套、focus 2 套 | S1、S3、S5；E09、E11、E12、E14、E19、E20 | 定 3 个语义配方：`NavSelected`（0.12 + r12 + h40）、`ControlActive`（primary 0.12 + 0.4 边 + r8）、`CurrentRow`（0.06 + 2px 条）；hover 统一 onSurface 0.06（可播区 accent 0.04）；focus 统一 primary 0.16；透明度与边框 token 化 | `app_sidebar.dart`、`settings_pane.dart`、`library_toolbar.dart`、`library_view_switch.dart`、`compact_theme.dart`、`shared/ui` | 中 | 低 | 高 |
| P0-4 | 扫描状态行仍在列表上方占位，且被居中成漂浮说明；违反文档 | S1、S2；E02、E06、E18 | 删除插入；扫描中在页头下画 2px 进度线（不占高度）；失败在 `⋯` 上加圆点 + tooltip；删除 `LibraryScanStatusBar` | `library_pane.dart`、`library_header.dart`、删除 `library_scan_status_bar.dart` + 测试 | 中 | 低 | 中高 |
| P1-1 | 次行 12 / w600 比标题 14 / w500 更响 | S1；E04 | 次行改 label 12 / w400（颜色不变）；标题保持 14 / w500（选中 w600）；在类型刻度注释里写一条角色规则 | `library_track_card.dart`（检查 favorites / queue 同模式） | 低 | 低 | 中 |
| P1-2 | 时间标签两套；三套同形徽标 | S1；E12、E13、E15 | 抽 `shared/ui/time_label.dart`（width / align 参数，默认居中）；抽 `MarkBadge` 容器，三徽标共用 18/22 + r5/6 + 0.12/0.28（live 保留 0.14/0.30） | `shared/ui`、`player_dock`、`now_playing_page`、三徽标文件 | 低 | 低 | 中 |
| P1-3 | 设置预览写死浅色 accent，和真实主题不一致 | S3；E22、E17 | 预览直接用 `CompactTheme.accent` / `ColorScheme.primary`；发丝线用 `outlineVariant` | `settings_cards.dart` | 低 | 低 | 中 |
| P1-4 | 两套卡片语言 + 两个死组件 | S3；E10、E21 | 删除 `SettingsPageHeader`、`LibraryRowActions`、版本 pill dead 红点；`SettingsCard` 收敛为 sheet body，或直接删其带框分支，卡片头只留 `SettingsPanel` | `settings_card_shell.dart` + 7 个 settings 卡、`library_row_actions.dart`、`settings_cards.dart` | 低–中 | 低–中 | 中 |
| P2-1 | 局部间距 3/9/11/18 不在刻度上 | S3；E10、E11、E12 | 归并到 4/6/8/10/12/16/20/24；`SizedBox(height:34)` 改用 `controlDefault` | `settings_card_shell`、`app_sidebar`、`player_dock` | 低 | 低 | 低 |
| P2-2 | `tertiary` 未显式设置，直播色随 seed 漂移 | S1/S3；E15、E17 | 显式定义 tertiary（与 accent / moss 同级），`LiveBadge` 只读该 token | `compact_theme.dart` | 低 | 低 | 低 |
| P2-3 | 底栏同排图标 18 / 20 / 18，重量不齐 | S1；E12 | 底栏图标统一一档；强调用 active tint，不靠放大 | `player_dock.dart` | 低 | 低 | 低 |

## 四、需决策（不要混进执行项）

| # | 议题 | 现状与证据 | 选项 | 建议 | 影响 |
| --- | --- | --- | --- | --- | --- |
| D1 | 页面标题用 24 还是 38；眉标去留 | 音乐库/设置 24 无眉标；喜欢/音源/发现 38 + 红眉标（S3 vs S4，E07/E08/E18） | A. 一级导航页 24 无眉标，对象页（专辑、正在播放）保留 38 + 眉标；B. 全部 38 + 眉标；C. 全部 24 | **A**：与音乐库文档 §4.1 一致，也符合「红色只标记正在发生」 | 3 个页面 + `PageHeading` 变体 + 截图基准 |
| D2 | 音源图标是否允许用强调红 | `openCatalog → FactTone.primary`，每行的音源标都是红（S1，E16）；`docs/library-redesign.md` 说不要红，`docs/chips.md` 把 openCatalog 定为 primary | A. 保持 primary；B. 给在线目录一个独立类别色（非红）；C. 音源一律中性色，类别只在 tooltip | **B**：红色留给「正在发生」，与当前播放/选中不抢 | `source_mark.dart`、chips 文档、相关测试 |
| D3 | 窄窗来源筛选怎么退 | 760 下只剩 16 + 14 两个图标，读不出当前来源（S2，E05） | A. 任何宽度都写值（挤压搜索）；B. 宽窗写值、窄窗图标 + tooltip；C. 把来源并入「筛选」面板 | **C 优先，保留宽度 ≥1080 时直接写值**：窄窗可发现，宽窗可读 | 工具条 + 筛选面板 + 测试 |
| D4 | 健康度表的呈现 | 1440 下仍是 8–9 列 11px 标签 + 百分比（S3），是全页最挤处 | A. 保持单表；B. 拆两行 × 4–5 组；C. 收进「健康度详情」弹层 | **B**：不丢信息，降低单行密度；数值仍用 mono 11 | 健康度卡、截图基准 |

## 五、截图清单

| 编号 | 文件 | 尺寸 / 来源 | 主题 | 支撑的结论 |
| --- | --- | --- | --- | --- |
| S1 | [01-library-1440-real.png](./outputs/01-library-1440-real.png) | 1440×860，真机 `flutter run` | 深色 | 列头偏移、行尾漂移、扫描行居中、工具条、行内字重 |
| S2 | [02-library-760-real.png](./outputs/02-library-760-real.png) | 760 宽，真机 | 深色 | 窄窗工具条挤压、来源筛选无文字、「时长」列头错位 |
| S3 | [03-settings-1440-dark.png](./outputs/03-settings-1440-dark.png) | 1440×860，临时 widget 夹具 | 深色 | 24 页头、设置导航选中、卡片壳、健康度密度、预览色 |
| S4 | [04-favorites-1080-dark.png](./outputs/04-favorites-1080-dark.png) | 1080，临时 widget 夹具 | 深色 | 38 + 眉标页头、行状态一致性 |
| S5 | [05-queue-1080-dark.png](./outputs/05-queue-1080-dark.png) | 1080，临时 widget 夹具 | 深色 | 队列面板、当前播放行、面板内头部/行对齐 |

## 六、方法与限制

- 已读 `AGENTS.md` 与 `docs/architecture.md`、`library-redesign.md`、`settings-redesign.md`、`performance-row-design.md`、`chips.md`、`conventions.md`、`queue-panel.md`。
- 真机用 `flutter run -d linux` 启动，以 `wmctrl` 改窗口宽度、`agkit shot` 取证；1440 / 1080 / 760 三档都跑过。
- 喜欢 / 音源 / 设置 / 正在播放 / 队列 / 搜索弹层在本环境无法把合成键鼠送进应用（X11 / XWayland 注入不生效），因此这些页面用仓库内临时 widget 夹具渲染真实组件与真实令牌，夹具数据是少量样例曲目，右上角有 DEBUG 丝带（S3–S5 可见）。音乐库的 1080 真机图也已拍，但为把交付图控制在 5 张没有带出。
- **待确认：** 专辑视图的夹具截图为空（样例数据没有专辑），本轮不对专辑视图下视觉结论；130% 字号下的行尾 `FittedBox` 压缩风险来自代码推断，未实拍；浅色主题只做了令牌对比度计算，未实拍（光晕、发丝线、阴影观感待确认）。
- 像素测量只用于方向判断；所有偏移最终都回到代码常量复核（24 gutter、18 + 4 + 44 + 4 + 24 的尾部账）。
- 本轮没有改任何源码、文档或依赖，没有提交 git；`/tmp/tune-ui-audit` 与临时夹具已清理，`flutter run` 已关闭。

## 证据索引

- **E01** 列头实现：[library_column_header.dart:26-27](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_column_header.dart#L26-L27)、[:40](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_column_header.dart#L40)、[:43-49](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_column_header.dart#L43-L49)、[:90-99](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_column_header.dart#L90-L99)
- **E02** 列表组装与扫描条插入：[library_pane.dart:207](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_pane.dart#L207)、[:284](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_pane.dart#L284)、[:512-515](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_pane.dart#L512-L515)、[:525-546](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_pane.dart#L525-L546)、[:617-628](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_pane.dart#L617-L628)
- **E03** 行尾实现：[library_row_tail.dart:21](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_row_tail.dart#L21)、[:42-50](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_row_tail.dart#L42-L50)、[:67-90](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_row_tail.dart#L67-L90)
- **E04** 行网格/字重/选中：[library_track_card.dart:83-120](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_track_card.dart#L83-L120)、[:128-139](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_track_card.dart#L128-L139)、[:163-187](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_track_card.dart#L163-L187)、[:192-214](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_track_card.dart#L192-L214)、[:225-227](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_track_card.dart#L225-L227)
- **E05** 工具条：[library_toolbar.dart:125-142](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_toolbar.dart#L125-L142)、[:168-196](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_toolbar.dart#L168-L196)、[:276-282](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_toolbar.dart#L276-L282)、[:318-380](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_toolbar.dart#L318-L380)
- **E06** 扫描条：[library_scan_status_bar.dart:30-44](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_scan_status_bar.dart#L30-L44)
- **E07** 共享页头：[page_heading.dart:7](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/page_heading.dart#L7)、[:36-49](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/page_heading.dart#L36-L49)
- **E08** 24 页头：[library_header.dart:47-48](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_header.dart#L47-L48)、[:77-86](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_header.dart#L77-L86)；[settings_pane.dart:258-262](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_pane.dart#L258-L262)
- **E09** 设置导航选中：[settings_pane.dart:183-227](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_pane.dart#L183-L227)
- **E10** 设置卡壳与死页头：[settings_card_shell.dart:61-125](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_card_shell.dart#L61-L125)、[:151-177](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_card_shell.dart#L151-L177)；[settings_cards.dart:13-42](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_cards.dart#L13-L42)
- **E11** 侧栏选中：[app_sidebar.dart:277-305](file:///home/pt/Work/IdeaProjects/tune/lib/features/shell/presentation/app_sidebar.dart#L277-L305)
- **E12** 底栏：[player_dock.dart:253-266](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/presentation/player_dock.dart#L253-L266)、[:340-350](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/presentation/player_dock.dart#L340-L350)、[:423-436](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/presentation/player_dock.dart#L423-L436)
- **E13** 正在播放时间标签：[now_playing_page.dart:471-484](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/presentation/now_playing_page.dart#L471-L484)
- **E14** 队列行/面板：[queue_track_row.dart:70-99](file:///home/pt/Work/IdeaProjects/tune/lib/features/queue/presentation/queue_track_row.dart#L70-L99)；[queue_panel.dart:141-147](file:///home/pt/Work/IdeaProjects/tune/lib/features/queue/presentation/queue_panel.dart#L141-L147)、[:428-436](file:///home/pt/Work/IdeaProjects/tune/lib/features/queue/presentation/queue_panel.dart#L428-L436)
- **E15** 三徽标：[source_badge.dart:34-50](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/source_badge.dart#L34-L50)；[audio_source_badge.dart:41-51](file:///home/pt/Work/IdeaProjects/tune/lib/features/player/presentation/audio_source_badge.dart#L41-L51)；[live_badge.dart:26-39](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/live_badge.dart#L26-L39)
- **E16** 音源 tone 映射：[source_mark.dart:55](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/source_mark.dart#L55)
- **E17** 主题与令牌：[compact_theme.dart:24-25](file:///home/pt/Work/IdeaProjects/tune/lib/app/theme/compact_theme.dart#L24-L25)、[:155-238](file:///home/pt/Work/IdeaProjects/tune/lib/app/theme/compact_theme.dart#L155-L238)；[compact_tokens.dart:67-107](file:///home/pt/Work/IdeaProjects/tune/lib/app/theme/compact_tokens.dart#L67-L107)、[:176-190](file:///home/pt/Work/IdeaProjects/tune/lib/app/theme/compact_tokens.dart#L176-L190)
- **E18** 文档口径：[library-redesign.md:46](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L46)、[:54-58](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L54-L58)、[:84](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L84)、[:110-111](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L110-L111)、[:164-167](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L164-L167)、[:261](file:///home/pt/Work/IdeaProjects/tune/docs/library-redesign.md#L261)；[conventions.md:55-72](file:///home/pt/Work/IdeaProjects/tune/docs/conventions.md#L55-L72)；[settings-redesign.md:76](file:///home/pt/Work/IdeaProjects/tune/docs/settings-redesign.md#L76)、[:158](file:///home/pt/Work/IdeaProjects/tune/docs/settings-redesign.md#L158)
- **E19** 视图切换：[library_view_switch.dart:26-33](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_view_switch.dart#L26-L33)、[:86-104](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_view_switch.dart#L86-L104)
- **E20** 交互状态：[dense_icon_action.dart:54-66](file:///home/pt/Work/IdeaProjects/tune/lib/shared/ui/dense_icon_action.dart#L54-L66)
- **E21** 死代码：[library_row_actions.dart:16](file:///home/pt/Work/IdeaProjects/tune/lib/features/library/presentation/library_row_actions.dart#L16)
- **E22** 预览色：[settings_cards.dart:549](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_cards.dart#L549)、[:570-574](file:///home/pt/Work/IdeaProjects/tune/lib/features/settings/presentation/settings_cards.dart#L570-L574)
