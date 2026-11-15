# 任务：第 5 类「音效」+ 专辑级例外

> 依据：`spec.md`。三点取舍已按推荐拍板：新增 `ContentKind.soundEffect`；话剧归有声书；粒度=实例默认 + 专辑级例外。
> 门禁：`flutter analyze` No issues found；`flutter test` 全绿（网络 e2e 单独复跑）。

## A. 领域

- [x] A1 `ContentKind.soundEffect`，`isSpokenWord` 仍只含播客/有声书。
- [x] A2 `declaredAlbumKinds`（实例 id → 归一化专辑名 → 类型），归一化 = 小写/去首尾空白/内部空白折叠；只细化未声明实例（实例声明优先）。
- [x] A3 `nonMusicGenrePrefix = 'non-music'`：任一 genre 标签以它开头 → 音效（显式元数据，不做时长/标题启发）。
- [x] A4 `contentKindOfFields` 增加 `album` 参数，顺序：直播 → 实例声明 → 专辑例外 → Non-Music 前缀 → 本地规则/类型集合 → 音乐；`contentKindOf` 透传 `song.album`。

## B. SQL

- [x] B1 `LibraryFilterSql`：新增 `_declaredAny`、`_albumOverrideOf(kind)`、`_nonMusicGenre`、`_soundEffectWhere`。
- [x] B2 `kind()` 增加 soundEffect 分支；music 分支排除音效；`_audiobookWhere` 纳入专辑例外；专辑例外只在实例未声明时生效。
- [x] B3 `spokenWord` / 专辑摘要口径随 `_audiobookWhere` 自动生效，核对专辑墙归类。

## C. 应用层

- [x] C1 `_otherKinds` 加入 soundEffect（页头菜单第 5 项）。
- [x] C2 facets：SELECT 增 `songs.album`，`contentKindOfFields` 传入 album（索引随之 +1）。
- [x] C3 专辑归类：`libraryAlbumsOf` / `AlbumSummary.kind` 对音效专辑的处理。

## D. UI

- [x] D1 页头 `_kindLabel` / `_kindIcon` 第 5 项（图标 `graphic_eq_rounded`）。
- [x] D2 工具条计数单位：`libraryEffectCount`（「{count} 段」/ "{count} clips"）。
- [x] D3 `RowShape.soundEffect`：副标题只写专辑，不写「歌名 + 歌手」；表格艺术家列留空。
- [x] D4 `filterKindLabel` 第 5 项；专辑卡单位用「段」。

## E. 文案

- [x] E1 四份 ARB：`contentKindSoundEffect`、`libraryEffectCount`，`flutter gen-l10n` 提交产物。

## F. 测试

- [x] F1 `content_kind_test`：专辑例外命中/不命中；实例已声明时不被专辑例外覆盖；`Non-Music` 前缀 → 音效；音乐不受影响。
- [x] F2 `library_database_test`：songs 作用域排除音效；音效作用域计数；`otherKindCount` 含音效；专辑摘要 kind。
- [x] F3 页头测试：菜单 5 项、音效选中态。
- [x] F4 行形态/工具条测试：音效行不写艺术家、单位「段」。

## G. 文档与证据

- [x] G1 `docs/library-browse.md`：声明表、第 5 类、计数单位、专辑例外机制。
- [x] G2 `flutter analyze` / `flutter test`。
- [x] G3 截图：歌曲视图、音效作用域、页头菜单（无法注入点击时用 golden 渲染菜单）。

## H. 后续（另起）

- [x] H1 全库内容类型审计（确认错判 / 疑似 / 没问题），单独报告。

## I. 审计后的第二轮判定（2026-11-15 拍板）

- [x] I1 口语 genre 覆盖实例声明：`audiobook` / `audio book` / `books and spoken` /
  `books & spoken` / `poetry` → 有声书，`speech` / `comedy` → 播客；只读 genre 首个标签，
  普通音乐流派（Blues、Gospel…）不许覆盖实例。
- [x] I2 专辑例外对**已声明实例**也生效：`radio_recordings / American Stories`（30）、
  `archive_podcasts / Sleep Safe…`（30）、`archive_podcasts / pIANO`（11）随之修正。
- [x] I3 `RelicRadio.com`（120）按专辑例外归电台，不归播客。
- [x] I4 机制第二层：IA 扫描读条目自带 `collection`（`librivox` / `audio_foreign` → 有声书，
  `podcasts` → 播客，`oldtimeradio` → 电台），写成 `sourceData.contentKind`；不做启发式。
- [ ] I5 机制第一层（类型写进音源实例配置）——本轮不实现，只记录在
  `docs/library-browse.md` §5.1.1。
- [ ] I6 机制第三层（专辑例外进库表）——本轮不实现，同上。
- [x] I7 `great78` 的 novelty/party-record 段子与政治演讲记为「疑似：五类无合适位置」，
  不加第 6 类；名单见 `docs/library-browse.md` §5.1.1。
- [x] I8 `radio_recordings` 混排、`TASCAM DR-05`、`Reading1Volume6.mp3`、peertube 教育视频
  按同口径：有显式标签才定，纯推断留疑似并记录。
- [x] I9 测试：口语前缀覆盖实例、专辑例外覆盖已声明实例、条目自带声明优先、
  IA collection 映射；SQL 侧 5 条 fixture 与 Dart 同序。

## J. 脏数据：零时长与极短轨（2026-11-15 拍板）

- [x] J1 `LibraryFilter.hideMissingDuration`（默认 `true`）与
  `excludeShortTracks`（默认 `false`），进 `view.json`，清除全部保留前者。
- [x] J2 SQL：`hiddenDuration` / `shortTracks` 进 `where`；`missingDurationCount`
  统计当前搜索与筛选下被隐藏的零时长条目。
- [x] J3 工具条：可见提示「已隐藏 N 条时长缺失的曲目」+ 一键显示，禁止暗过滤。
- [x] J4 筛选面板「极短轨」组（≤3 秒），默认关闭，计入生效组数。
- [x] J5 测试：零时长默认隐藏、关闭后恢复、计数文案、极短轨默认不过滤、
  `view.json` 往返与旧视图默认值。
- [x] J6 文档：`docs/library-browse.md` §4.9。
