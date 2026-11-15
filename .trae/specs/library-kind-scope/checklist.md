# 检查清单：内容类型作用域 + 专辑入口

- [x] `LibraryFilter.kinds` 在启动加载与 `setFilter` 两个入口都不会为空，默认 `{music}`
- [x] 控制器写入 `matching`（作用域 + 筛选命中数）与 `otherKindCount`（播客 + 有声书 + 电台），扫描后同步刷新
- [x] 页头内容菜单只有在本库存在非音乐内容时出现，四项单选且当前项打勾，点击即把 `kinds` 设为该项并切回歌曲列表
- [x] 页头「专辑」按钮在库里有专辑时出现，点击进入专辑墙，墙打开时按钮高亮
- [x] 工具条计数始终显示，单位随作用域变化（首 / 集 / 章 / 台）
- [x] 清除全部（面板、chip 行、空态、树「全部歌曲」）只清筛选组，作用域保留
- [x] 单选作用域跨重启保留；旧版多选 `kinds` 的 `view.json` 启动落回 `{music}` 并回写
- [x] 歌曲视图的专辑列可点开该专辑，点行内其他位置仍是播放；命中规则与「正在播放」高亮共用 `albumSummaryOf`
- [x] 专辑读不出曲目时点击不跳转，不出现空白页
- [x] 未声明 IA 实例已补声明：`news_recordings → radio`、`science_talks → podcast`、`poetry_books / poetry → audiobook`，`unlocked_recordings` 保持音乐
- [x] 四份 ARB 与 gen-l10n 产物一致（`librarySummary` / `libraryStationCount` / `libraryOpenAlbum`）
- [x] `docs/library-browse.md` 记录作用域、专辑入口与声明表
- [x] `flutter analyze` 无 issue
- [x] `flutter test` 全绿（+1709）
- [x] 截图对比：默认音乐视图无 `RelicRadio` / `Pod Save America` 行（2,948 首）；播客作用域见 `Case Closed!`（497 集）；专辑页与专辑墙由 `library_albums_test.dart` 覆盖（本机桌面输入注入不可用，无法脚本点击截图）
