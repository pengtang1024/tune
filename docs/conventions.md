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

## 字体

- 字体的唯一入口是 `CompactTypography`（`lib/app/theme/compact_typography.dart`）：拉丁三个脸 Fraunces / Instrument Sans / JetBrains Mono 只带拉丁字形，中文靠回退家族接上。
- 中文用随包发布的思源黑体（`Noto Sans SC`）与思源宋体（`Noto Serif SC`），标题走宋体、正文走黑体；不要依赖系统装了什么字体，也不要在 widget 里写 `fontFamily`。
- 这两个字族打包的是 Noto CJK 的**变量字体**（`assets/fonts/NotoSansSC/NotoSansSC-VF.ttf`、`assets/fonts/NotoSerifSC/NotoSerifSC-VF.ttf`）：一份文件覆盖所有字重，标题的粗体是真的，不是引擎合成的假粗体。
- 字重统一由 `CompactTypography` 钉在 `wght` 轴上（`weightVariations` / `displayVariations`）。引擎只按字体自带的命名实例匹配，这两个字族缺 600 这一档，不钉轴的话 `w600` 会落到 `w500` 上。
- 拉丁展示体 Fraunces 走 `SOFT=100`（圆润那版）+ `WONK=1`，`opsz` 跟字号走；改展示观感改 `CompactTypography.displayVariations`，不要在调用点加 `fontVariations`。
- 需要新样式就调 `CompactTypography.sans` / `display` / `mono` / `asDisplay`，不要在调用点直接 `TextStyle(fontFamily: ...)`。

### 字号梯度

- 字号按「角色」取，不按调用点取。唯一的梯度是 `CompactTypeScale`（`lib/app/theme/compact_type_scale.dart`）：
  - `markDense` 8 / `mark` 9：标记类文字——页面眉标、药丸标签、品牌角标。这类字是符号不是句子，才允许小于正文。
  - `micro` 10.5：机器写出来的数字与名字——时长、序号、版本号、路径。
  - `label` 11.5：控件上的标签与次要说明。
  - `body` 12.5：输入框、列表项、段落正文。
  - `strong` 13.5：曲目标题、卡片标题、主要按钮。
  - `title` 15：一组内容的标题。
  - `heading` 16：浮层与对话框的标题。
  - 展示体是另一条梯子：`displaySmall` 17 / `displayMedium` 24 / `displayLarge` 38。它比无衬线那一条高一像素起——同样大小的一个宋体和一个黑体读起来就是两种字，所以不用把两条梯子合成一条。
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

## 提示（tooltip）

- 界面上没写出来的说明一律走 `TuneTooltip`（`lib/shared/ui/tune_tooltip.dart`），不要直接用 `Tooltip`。
- 外观只有一处：`CompactTheme.tooltipTheme`（`lib/app/theme/compact_theme.dart`）。改动外观改主题，不要在调用点写 `decoration`。
- 提示是**一滴墨**：明暗两套主题都是深色卡片 + 纸色文字。深色主题下不要换成纸色卡片，否则深色桌面上会浮起一个白盒子。
- 图标按钮用 `IconButton(tooltip: ...)`，它跟 `TuneTooltip` 走同一份主题。
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
  - app 自己的持久化在测试里用 `FakePersistenceService` 隔离，不去碰真的插件存储。
  - 脚本要留在 `tool/`（不进常规 `flutter test`）就在调用处加 `// ignore: invalid_use_of_visible_for_testing_member` 并写明原因。
  - 脚本要进常规测试运行就挪到 `test/` 下。
- 详见 [verification.md](verification.md)。
