# 测试与验证

> AGENTS.md 的展开文档。写测试、跑门禁前读这份。

## 提交前门禁

```bash
flutter analyze          # 必须 No issues found
flutter test             # 全绿
flutter gen-l10n         # 改过 ARB 才需要
flutter run -d linux     # 需要看界面时
```

只写测试不算验证：`flutter analyze` 干净 + `flutter test` 全绿 + 亲手跑过界面，三者都要有。

### 门禁的前提：SDK 补丁

工程路径里有中文（`文档`），Flutter 3.47.x 的 `flutter analyze` 在这种路径下会炸：
它给分析服务发的 LSP 报文把 `Content-Length` 写成了**字符数**，而实际发出去的是
**UTF-8 字节数**，少 4 个字节，服务端读到截断的 JSON，报
`FormatException: Unexpected end of input`。

这是 SDK 自己的 bug（上游 `packages/flutter_tools/lib/src/dart/analysis.dart` 的
`_writeMessage` 用 `message.length`），本地已经改掉：

```bash
# 改这一行：${message.length} -> ${utf8.encode(message).length}
# 然后让工具重建快照：
rm -f /opt/flutter/bin/cache/flutter_tools.stamp
flutter --version
```

**注意**：`flutter upgrade` 会把这个补丁冲掉，届时 `flutter analyze` 又会在中文路径下报错。
临时兜底是 `dart analyze`（不走 LSP，结果一样）。

## 测试目录

镜像 lib 结构：

| 目录 | 放什么 |
| --- | --- |
| `test/app/` | controller、界面、设置的测试；替身（fake）也放这里 |
| `test/core/` | l10n、文本方向等核心工具的测试 |
| `test/domain/` | 领域模型的测试 |
| `test/services/` | 服务与适配器的测试，含跨服务的集成用例 |

## 替身与隔离

- service / controller 的替身写成 `test/app/fake_*.dart`（`FakeAudioPlayerService`、`FakeSongDownloadService`、`FakeStreamUrlResolver`）。
- 持久化用 `FakePersistenceService`（`test/services/fake_persistence.dart`）隔离；要测真的文件存储，用 `FilePersistenceService(directory: ...)` 指向临时目录。
- controller 的替身继承原类并覆盖 `build()`（见 `layout_shots_test.dart` 里的 `_FakeLibraryController`）。

## 语言守卫

- `test/app/localization_test.dart`：扫源码，比对各 locale 的目录、查硬编码文案、查漏出的其它语言。
- `test/app/localization_render_test.dart`：真正渲染每个页面读树，抓硬编码文案、跨语言漏出和超长标签；页面上的浮层、对话框与搜索结果也一起画。
- `test/app/localization_words.dart`：专有名词与格式名的白名单，新增音源名要加进去。
- `test/app/localization_numbers_test.dart`：数字分组格式。

规则细节见 [i18n.md](i18n.md)。

## 截图对比

- `tool/layout_shots_test.dart` 是开发用的截图工具，不是测试套件的一部分。
- 跑法：`flutter test tool/layout_shots_test.dart`，每个页面写一张 PNG 到 `build/layout-shots/`（1280、900、760×520 三套；760 是应用最小尺寸）。队列侧栏写 `queue_panel*.png`，正在播放页的队列侧栏写 `now_playing_queue*.png`；窄屏截图里导航是紧凑态，内容区被遮罩压暗，正在播放页的面板带迷你播放条。旧的 `queue*.png` 整页截图不再生成。
- 它在 `tool/` 下，常规 `flutter test` 不会跑到它。
- 它把平台钉成 Linux：测试套件默认假装是 Android，而 Android 用另一套密度和更大的点击区，不钉的话截图里的按钮比用户看到的矮 8 像素。
- 改了界面布局后跑一次，和改动前的 PNG 对比，比读代码更快发现布局问题。
- `tool/tooltip_shots_test.dart` 同理，写提示的两张图到 `build/tooltip-shots/`；改了提示样式后跑它。

## 对齐守卫

- `test/app/layout_alignment_test.dart`：盯住容易漂的几处——播放按钮落在底栏中线、队列面板的行不越出卡片且宽度守规则、标题与列表同一条左边缘、正在播放页的整块居中、搜索框不越宽上限。
- `test/app/compact_layout_test.dart`：盯住 760 的紧凑导航与 440 面板、面板打开时内容区不可点而底栏/侧栏可用、长队列打开时定位当前曲目、正在播放页的迷你播放条，以及 1.3 倍中英文不溢出；还盯住默认 900×563 窗口的曲库首屏至少放下十首歌。
- `test/app/playback_session_store_test.dart` / `playback_session_test.dart` / `playback_session_provider_test.dart`：盯住启动恢复的队列、进度、音量与开关；详见 [playback-session.md](playback-session.md)。
- `test/app/compact_spinner_test.dart`：盯住加载圈的描边没有被自己的框裁掉（Material 的现行样式会裁），以及字号梯度里没有两档共用一个尺寸。
- `test/app/library_albums_test.dart` / `test/domain/library_album_test.dart`：盯住曲库的专辑分组（同名片、未知专辑、封面与曲序）和「歌曲 → 专辑网格 → 专辑曲目 → 返回」的整条路径。
- `test/app/compact_control_metrics_test.dart`：盯住 token 说的是真话——三种按钮画出来一样高且等于 `controlDefault`，列表行等于 `listRowHeight`，主题里的每个字号角色都是梯度上的一档。
- `test/app/theme_contrast_test.dart`：盯住纸上的字看得见——明暗两套主题里，正文色、次要色、强调色与错误色在每一层底色上都要过 4.5:1，白字压在强调色和错误色上也要过 4.5:1。改了 `CompactTheme` 的颜色就要跑它。
- `test/app/text_scale_test.dart`：盯住界面扛得住桌面的字号缩放——列表行和设置卡片在 1.25、1.5、2 倍的字号下、窗口窄到 420 像素时都不许溢出。改了装字的布局就要跑它。
- 改了 `CompactTokens`、`CompactTypeScale` 或动了上面几处布局，要连这三个文件一起跑。

## 联网测试

`test/services/` 里有若干访问真实服务的用例（`music_source_e2e_live_test.dart`、`music_source_live_test.dart`）。它们依赖网络与外部服务，跑测试时若失败先确认是不是网络问题，再判断是不是代码问题。
