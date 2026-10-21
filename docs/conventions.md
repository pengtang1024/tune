# 代码约定

> AGENTS.md 的展开文档。写代码前扫一眼这份。

## 日志

- 用 `Log.info` / `Log.error`（`lib/utils/logger.dart`），不要用 `print`（lib 下目前 0 处）。
- `Log` 只有 `debug` / `info` / `error` / `errorWithStack` 四个方法，没有 `warn`。
- 带堆栈的错误用 `Log.error(message, stackTrace)`。

## 主题与尺寸

- 间距、圆角、图标尺寸取 `CompactTokens`（`lib/app/theme/compact_tokens.dart`）。
- 颜色走 `Theme.of(context)` 或 `CompactTheme`（`lib/app/theme/compact_theme.dart`），不写裸色值与魔法数。
- 改外观先找现成 token，不要在 widget 里现编尺寸。
- 图标走 `icon12 / icon14 / icon16 / icon18 / icon20 / icon24 / icon28` 这一条两像素一级的梯子：跟正文（`body`）并排的图标取 `icon16`，大按钮里的取 `icon18` 或 `icon20`。
- 按钮高度走 `controlTiny / controlCompact / controlSmall / controlDefault / controlMedium / controlLarge`。空画面上的插图（`illustration*`）是画不是控件的图标，它有自己的尺寸。
- **三种按钮共用一个高度**：主题里 `FilledButton` / `OutlinedButton` / `TextButton` 都是 `controlDefault`（34）。它们总是挨着出现（对话框里的取消与确定、卡片里的扫描与清空），高度差一档就会看成失误；主次靠填充色和字重分，不靠高度分。
- 主题给按钮钉了 `VisualDensity.standard`：桌面的紧凑密度会把按钮的最小高度再减 8 像素，那样 `controlDefault` 34 画出来只有 26，token 就说了假话。
- 列表行的高度是 `listRowHeight`（56），行内留白由 `listRowPadding` 推出来，别在行里另写 `space8`。
- **正文颜色要过对比度**：浅色主题里的次要色（`muted`）与强调色（`accent`）至少要能和纸面拉开 4.5:1，白字压在强调色上也要 4.5:1。强调色不只是块，它还写页面眉标、节号和正在播放的曲名；亮朱红（`E6532F`）压白字只有 3.72:1，压纸面只有 3.16:1，纸上那排小红字就是「看不清」的来源。浅色主题现在用 `A83616`，`muted` 用 `635B50`，错误色用 `A82C1D`。
- 颜色的 alpha 只留给装饰。写着字的行不要用 `onSurfaceVariant.withValues(alpha: 0.6)` 这类半透明：在纸色上再叠 40% 透明度，最高也只能到 4.4:1，笔画本来就更细，等于没有对比度。
- `test/app/theme_contrast_test.dart` 守着这条线：明暗两套主题的正文色、次要色、强调色与错误色在每一层底色上都要过 4.5:1。

## 字体

- 字体的唯一入口是 `CompactTypography`（`lib/app/theme/compact_typography.dart`）：拉丁三个脸 Fraunces / Instrument Sans / JetBrains Mono 只带拉丁字形，中文靠回退家族接上。
- 中文用随包发布的思源黑体（`Noto Sans SC`）与思源宋体（`Noto Serif SC`），标题走宋体、正文走黑体；不要依赖系统装了什么字体，也不要在 widget 里写 `fontFamily`。
- 这两个字族打包的是 Noto CJK 的**变量字体**（`assets/fonts/NotoSansSC/NotoSansSC-VF.ttf`、`assets/fonts/NotoSerifSC/NotoSerifSC-VF.ttf`）：一份文件覆盖所有字重，标题的粗体是真的，不是引擎合成的假粗体。
- 字重统一由 `CompactTypography` 钉在 `wght` 轴上（`weightVariations` / `displayVariations`）。引擎只按字体自带的命名实例匹配，这两个字族缺 600 这一档，不钉轴的话 `w600` 会落到 `w500` 上。
- 拉丁展示体 Fraunces 走 `SOFT=100`（圆润那版）+ `WONK=1`，`opsz` 跟字号走；改展示观感改 `CompactTypography.displayVariations`，不要在调用点加 `fontVariations`。
- 需要新样式就调 `CompactTypography.sans` / `display` / `mono` / `asDisplay`，不要在调用点直接 `TextStyle(fontFamily: ...)`。
- **等宽那一族把随包的黑体排在最前面**（`monoFallback`）：系统的等宽中文字族并不总能画出每一个字，有些字会变成一个空方块（「本地 + 在线」的「本」就是这样），一个字变成方块比一个不太等宽的字更糟。

### 字号梯度

- 字号按「角色」取，不按调用点取。唯一的梯度是 `CompactTypeScale`（`lib/app/theme/compact_type_scale.dart`）：
  - `mark` 11：标记类文字——页面眉标、药丸标签、品牌角标、机器写出来的数字与名字（时长、序号、版本号、路径）。
  - `label` 12：控件上的标签与次要说明。
  - `body` 13：输入框、列表项、段落正文。
  - `strong` 14：曲目标题、卡片标题、主要按钮。
  - `title` 15：一组内容的标题。
  - `heading` 16：浮层与对话框的标题。
  - 展示体是另一条梯子：`displaySmall` 17 / `displayMedium` 24 / `displayLarge` 38。它比无衬线那一条高一像素起——同样大小的一个宋体和一个黑体读起来就是两种字，所以不用把两条梯子合成一条。
- **十一像素是这条梯子的地板，不是偏好**：中文一个字有十几根笔画，缩到十一像素以下笔画就叠在一起，那个字就糊成一团。这台机器的屏幕是 1920×1080、缩放 1.0，9 像素的「偏好」两个字就是一团淡红。要放更小的字只能放纯拉丁的符号。
- **详情面板的值用正文号（13）**：属性表里的值不降到标记号。脸和号各说一件事——脸说这话是谁写的（机器写的用等宽体：路径、地址、编号、时长、原始数据、请求头；人写的用正文体：专辑、流派、简介、歌词），号说它有多大。
- 药丸、徽标这类「密排」变体只改留白与图标尺寸，**不改字号**：密排是挤，不是小。
- **桌面有自己的字号缩放**：引擎读 GNOME 的 `text-scaling-factor` 交给框架，框架把每一个逻辑尺寸乘上去。应用不要跟它对着干——不要写 `TextScaler.noScaling`，也不要把装字的盒子钉死高度。梯度里的数字是逻辑像素，所以 11 像素是 100% 时的地板，设置一放大，地板跟着抬。
- 装不下的时候要让位，不要裁：正在播放页的字自己会滚动（`NowPlayingTrackInfo`），底栏的高度是 `dockHeight` 的**最小**高度（大字来了就长高），设置页预览里那张假界面的缝隙会让开。设备像素比不是可读性的信号——一个逻辑像素的物理大小不随它变，变的只是笔画被采样得细不细。
- **调用点不许写 `fontSize:` 数字**。要某个角色就挑主题里对应的 `textTheme` 角色（`bodySmall`、`labelMedium`、`bodyMedium`……），主题已经把它们接到梯度上。
- 主题里的 15 个 `textTheme` 角色全部接到梯度上，没有一个角色自己带字号：写死一个数字就等于开了第二条梯度。
- 要加新档位先想清楚：每多一档就多半个像素要让人记住，而这个界面一次要显示很多字。

## 加载指示

- 加载圈只用 `CompactSpinner`（`lib/shared/ui/compact_spinner.dart`），尺寸和线宽都从 `CompactTokens` 出。
- 不要直接用 `CircularProgressIndicator`：Material 的现行样式把描边画在路径中央，一半落在自己的框外被裁掉，圈在四个正方向上会变细，转起来像锯齿。`CompactSpinner` 用 `strokeAlignInside` 把整条描边收进框里，并换成圆头、把底圈去掉。
- 牌子式的小圈（按钮里那个）不要加底圈，两圈挨在一起会互相干扰。

## 布局对齐

- 页面左右留白统一用 `CompactTokens.pageGutter`；标题、工具条和列表共用同一条左边缘。
- 列表里的一行曲目统一走 `TrackMeta`（`lib/shared/ui/track_meta.dart`）：封面、序号、时长都从同一份 token 出发，音乐库和播放队列的列才会对齐。
- 走带控件（播放按钮、进度条）要落在中线上：播放按钮的中心与容器的中线重合，而不是让整组按钮居中。
- 输入框不要拉成细长条：`CompactTokens.searchFieldMaxWidth` 给了上限，右侧留给页面自己的动作。
- 悬浮元素（徽标、状态标签）跟着它描述的对象走，不要漂在行尾。
- **详情面板贴着内容长**：属性表的两列按字量出来（`TrackDetailColumns`），面板的宽度跟着表走，最多 `detailPanelWidth`。值都是短词，面板撑满浮层只会在右边空出一大片，信息密度就掉了。
- **量字宽用 `measureTextWidth`**（`lib/shared/utils/text_width.dart`）：画笔报的宽度比画字要的少一丝，列正好等于报的宽度时最后一个字会掉到下一行。量出来的宽度要留余量。
- **定宽的列里不要用 `SelectableText`**：可选中的字自己留四十像素的滚动余量，字只写在剩下的地方，列就得胖四十像素。

## 标识（chip）

- chip 的写法只有一份规范：[chips.md](chips.md)。要加标识、加事实、加音源的图标，先读它。
- 一句话版本：**chip 里不写字**——图标说"是哪一个"，颜色说"是哪一类"，字在 tooltip 里，细节在详情面板里。控件（下拉框、开关、按钮）显示自己的值，那不是 chip。
- `test/app/chip_style_test.dart` 扫源码守这条线：带文字的 chip 只许出现在详情面板里，药丸不许写字。

## 提示（tooltip）

- 界面上没写出来的说明一律走 `TuneTooltip`（`lib/shared/ui/tune_tooltip.dart`），不要直接用 `Tooltip`。
- 外观只有一处：`CompactTheme.tooltipTheme`（`lib/app/theme/compact_theme.dart`）。改动外观改主题，不要在调用点写 `decoration`。
- 提示是**主题自己的一张卡片**：卡片用主题的 `surfaceContainerHighest`，字用 `onSurface`，描边用 `outline`，投影跟主题一致。亮色主题下是纸色卡片配墨字，暗色主题下是深色卡片配纸字——暗色用暗色，明亮用明亮，主题里有现成的颜色就别另造。
- **字永远跟卡片反色，用哪个令牌由主题说了算**：不要把纸色或墨色写死在提示里。亮色主题的提示是纸卡片配墨字，暗色主题的提示是墨卡片配纸字。
- 提示的外观跟着应用主题走：**还开着的提示也会当场换成新主题的卡片**，不用等它关掉重开。
- 提示站在 `RawTooltip` 上而不是框架的 `Tooltip`：框架只在提示打开时把卡片画一次，画完就留着，所以它跟着不了主题。`TuneTooltip` 在 overlay 里读主题——也就是卡片真正被画出来的地方——所以主题一变，提示当场跟着变。
- 图标按钮的提示也走 `TuneTooltip`：`TuneTooltip(message: ..., child: IconButton(...))`。不要用 `IconButton(tooltip: ...)` 或 `PopupMenuButton(tooltip: ...)`，那是框架自己的提示，跟不了主题。`test/app/tooltip_style_test.dart` 里有守卫拦着。
- 提示没有文案就不该存在：`TuneTooltip` 会直接把子组件原样返回，不要用空字符串凑一个空框。

## 常量

- 偏好键名等放 `lib/core/constants/app_preferences_constants.dart`。
- 业务常量跟所属 feature 走，不要堆进全局常量文件。

## 体积

- 新文件控制在 200 行内、方法 50 行内。
- 已超限的大文件不要再长胖，把新逻辑拆到独立文件。当前超限的：
  - `lib/features/sources/presentation/music_sources_section.dart`
  - `lib/features/settings/presentation/settings_cards.dart`
  - `lib/features/player/application/playback_controller.dart`
  - `lib/features/player/presentation/now_playing_page.dart`
  - `lib/features/search/presentation/online_search_sheet.dart`

## 注释

- 英文，写「为什么」而不是「做了什么」。
- 对外 API 必须有 doc comment；私有成员只在语义不明显时写。
- 生成代码（`lib/l10n/app_localizations*.dart`）不手工改。

## 复用

- 新增 widget 前先搜 `lib/shared/ui/`；新增服务前先搜 `lib/data/services/`。
- 同一概念只留一份实现：重复的片段提到共享文件，不要复制到各处再各改一次。

## 平台差异

- 按 `lib/data/services/impl/*_io.dart` + `*_stub.dart` 成对实现（见 `http_song_download_service_io.dart` / `_stub.dart`）。
- 或走抽象服务，如 `lib/core/services/window_manager_service.dart`。
- 不要在 widget 里写平台判断。

## 脚本与工具目录

- `tool/` 放开发脚本（`generate_linux_icons.dart`、`layout_shots_test.dart`），不放业务代码。
- **测试专用 API 只能在 `test/` 下用**：`SharedPreferences.setMockInitialValues` 这类成员在 `tool/` 里会触发 `invalid_use_of_visible_for_testing_member`。
  - app 自己的持久化在测试里用 `FakePersistenceService` 隔离，不去碰真的磁盘存储。
  - 脚本要留在 `tool/`（不进常规 `flutter test`）就在调用处加 `// ignore: invalid_use_of_visible_for_testing_member` 并写明原因。
  - 脚本要进常规测试运行就挪到 `test/` 下。
- 详见 [verification.md](verification.md)。
