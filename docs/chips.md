# 标识（chip）

> 全应用的 chip 只有一种写法。规则在这里维护，别处只指向它。
> 相关：[architecture.md](architecture.md)（谁拥有什么）、[conventions.md](conventions.md)（写法）、[i18n.md](i18n.md)（文案）。

## 什么是 chip

chip 是一个小小的有框的标记，它给某个东西贴一个身份、一个状态或一个计数：曲目的事实、音源、扫描状态、直播标记、路径的默认标记。

控件（下拉框、开关、按钮）不是 chip——它们显示的是自己的值（语言、开关状态、菜单项），那是控件的职责。

## 一条规则：chip 里不写字

chip 只有两样东西：

- **图标**说"是哪一个"；
- **颜色**说"是哪一类"。

字在 tooltip 里（走 `TuneTooltip`），细节在详情面板里（`track_detail_sheet.dart`）。

为什么：chip 的宽度跟着字走，同一行里就会因为名字、状态、值的不同而忽宽忽窄——列对不齐，读者也要多扫一眼才知道哪个是哪个。固定大小 + 颜色分类 + 悬停出名字，读起来更快，也更好看。

## 颜色：先说类别

颜色是有限的几种，类别也是有限的几种，所以颜色先分大类，图标再分个体。

音源的类别来自数据层已经分好的 `MusicSourceKind`，界面不再另分一套：

| 类别 | 颜色 | 谁属于它 |
| --- | --- | --- |
| 本地目录 `localDirectory` | 中性 `onSurfaceVariant` | 本地音乐 |
| 公开目录 `openCatalog` | 主色 `primary` | Openverse、Jamendo、Internet Archive、ccMixter、iTunes、Audius、Wikimedia Commons、网络电台 |
| 自建接口 `openApi` | 次色 `secondary` | 网易云音乐 API、播客 RSS、Subsonic、Jellyfin |
| 自定义 `custom` | 三色 `tertiary` | 用户自己加的实例（自己的 feed、直链音频、映射好的接口） |

事实也有自己的语气色（`FactTone`）：中性、主色、次色、三色、错误色——同一件事在哪儿都是同一个颜色。

## 图标：再说个体

- 图标按**类型**查（`sourceIconOf(type, kind)`）：同一类型的实例共用一个图标；目录里没有的类型按类别兜底。
- 一个事实一个图标（格式、码率、画质、歌词、存储、直播……），行内靠图标就能分清。
- 直播标记只有一份实现（`shared/ui/live_badge.dart`），底栏与正在播放页共用。
- **喜欢是控件，不是标识**：红心（`shared/ui/favorite_button.dart`）自己就是那个动作，标过与没标过一眼看得出来，所以它不进事实条。

## 尺寸

chip 的盒子是固定的：图标走 `icon12 / icon14 / icon16` 这一条梯子，装在固定边长的小方块里（行内 18、正在播放页 22）。尺寸取 `CompactTokens`，不要在调用点写数字，也不要按文字长度撑开。

## 例外只有两处

1. **详情面板**（`track_detail_sheet.dart`）：唯一把事实写全的地方——图标 + 名字 + 值，再写出地址与正文。
2. **控件**：下拉框、开关、按钮显示自己的值。

想在 chip 里写字，先想是不是该进 tooltip，或者进详情面板。

## 加东西的时候

- **加一个音源**：在 `source_mark.dart` 给它一个自己的图标；类别变了就改 `sourceToneOf` 的映射，不要在调用点写颜色。名字与本地化名照旧只改 ARB。
- **加一个事实**：在 `track_facts.dart` / `track_metadata_facts.dart` 给它一个图标和一句话（tooltip 用）；行内自动变成一个纯图标，详情面板自动多一条。
- **加一个 chip**：用 `MetaBadge`（纯图标 + tooltip）或 `SourceBadge`（音源标识），不要自己拼一个带文字的方块。

## 谁守着这条线

- `test/app/chip_style_test.dart`：扫源码，`MetaChip`（带文字的 chip）只许出现在详情面板里；带框的标记不许自带文字。
- `test/app/source_badge_test.dart`：标识是图标、名字只在 tooltip、大小不随名字变、13 个图标互不重复、颜色跟着类别走。
- `test/app/track_facts_test.dart`：事实的图标与 tooltip。
- `test/app/localization_render_test.dart`：两种语言 × 两种窗口都画得下，没有溢出。
