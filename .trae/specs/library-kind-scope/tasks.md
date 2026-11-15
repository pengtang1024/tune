# 任务：内容类型默认作用域 + 专辑入口

> 依据：`spec.md`。除 E 组（未声明 IA 实例，待用户确认）外，其余按规格默认值执行。
> 门禁：`flutter analyze` No issues found；`flutter test` 全绿（排除两个网络 e2e）。

## A. 领域与状态（唯一作用域来源）

- [x] A1 `lib/domain/models/library_filter.dart`：加 `static const LibraryFilter songs = LibraryFilter(kinds: {ContentKind.music});` 与 `LibraryFilter withoutGroups()`；import `content_kind.dart`（若尚未 import）。
- [x] A2 `lib/features/library/domain/library_state.dart`：加 `final int matching;`（作用域命中数，默认 0）与 `final int otherKindCount;`（非音乐条数，默认 0），补 `copyWith` / `==` / `hashCode`。
- [x] A3 `lib/features/library/application/library_controller.dart`
  - `build`：`final saved = view?.filter ?? LibraryFilter.empty; final filter = saved.kinds.isEmpty ? saved.copyWith(kinds: const {ContentKind.music}) : saved;`，规范化后回写 `view.json`。
  - `build` / 扫描完成：写入 `matching = countQuery(filter: 当前 filter)` 与 `otherKindCount = countQuery(filter: LibraryFilter(kinds: {podcast, audiobook, radio}))`；`_reloadForFilter` 同步 `matching`（不重算 `otherKindCount`）。
  - `setFilter`：空 `kinds` 规范化为 `{music}` 后再比较 / 查询（唯一 chokepoint，修 P2）。

## B. 页头与工具条

- [x] B1 `lib/features/library/presentation/library_header.dart`：删除 `radioActive` / `onRadio`；加 `selectedKind` / `onKind` / `showKindMenu`（内容菜单，`key: library-content-kind`，四项单选带勾选）与 `onAlbums` / `albumsActive`（`key: library-albums`，图标 `grid_view_rounded`，文案 `libraryViewAlbums`）。
- [x] B2 `lib/features/library/presentation/library_pane.dart`
  - `_toggleRadio` → `_selectKind(ContentKind kind)`：`setFilter(filter.copyWith(kinds: {kind}))` + 切回歌曲视图 + 清空 `_openAlbum`。
  - 当前单一类型 `selectedKind`（`filter.kinds.length == 1` 时取值）；`showKindMenu = library.otherKindCount > 0`（修 P6）。
  - `onAlbums: () => _setView(LibraryViewMode.albums)`，`albumsActive: _view == LibraryViewMode.albums`；专辑数为 0 时不显示。
  - 页头摘要改传新语义（文案在 D1 改），其余调用点不动。
- [x] B3 `lib/features/library/presentation/library_toolbar.dart`：`filteredCount`/`showCount` 改为 `count` + `ContentKind? kind`；始终显示，单位按 A4 规则取 `libraryTrackCount` / `libraryEpisodeCount` / `libraryChapterCount` / `libraryStationCount`。

## C. 专辑可见

- [x] C1 `lib/features/library/presentation/library_track_card.dart`：加 `final ValueChanged<Song>? onOpenAlbum;`；专辑单元格在可点击时用 `TuneTooltip` + `InkWell` + `Semantics(button)` 包裹，hover 下划线；不可解析时保持纯文本（无 tooltip、无下划线）。
- [x] C2 `lib/features/library/presentation/library_pane.dart`
  - 抽出 `LibraryAlbum? _albumOf(List<AlbumSummary> albums, Song song)`：精确 key（`libraryAlbumKeyOf`）→ 合并节目按 `normalizedShowNameOf` + 来源命中；`_currentAlbumKey` 改为调用它，规则只有一份。
  - `_openAlbumOfSong(Song)`：命中后 `await _openAlbumByKey(...)`；未命中直接返回。
  - `_trackList` / 缓存路径透传 `onOpenAlbum`；缓存比较项不变（回调不参与比较）。

## D. 文案

- [x] D1 四份 ARB（`app_en` / `app_zh` / `app_zh_CN` / `app_zh_TW`）：
  - `librarySummary` 改为「{count} 项内容 · {albums} 张专辑 · {sources} 个来源」（英文 `{count} items`）；
  - 新增 `libraryStationCount`（`{count} 台` / `{count} stations` / 繁体同）；
  - 新增 `libraryOpenAlbum`（打开专辑 / Open album / 開啟專輯）。
- [x] D2 `/opt/flutter/bin/flutter gen-l10n`，保留产物。

## E. 未声明 IA 实例（待用户确认；默认按推荐做）

- [x] E1 `lib/domain/models/content_kind.dart::declaredContentKinds`：`news_recordings → radio`、`science_talks → podcast`、`poetry_books → audiobook`、`poetry → audiobook`；`unlocked_recordings` 保持音乐。
- [ ] E2 若用户否掉某条，恢复该条并把它记入 spec 的「待确认」结果。

## F. 文档

- [x] F1 `docs/library-browse.md`：新增「内容作用域」一节——默认音乐、`kinds` 永不为空、清除全部只清组不清作用域、页头内容菜单、工具条计数单位；专辑入口一节——页头按钮、专辑列可点、专辑页内容；把「用户可多选类型」表述改为「类型是作用域，多选仍在筛选面板可用」。
- [x] F2 若判定规则（E）落地，更新 `docs/library-browse.md` 的声明表。

## G. 测试与门禁

- [x] G1 `test/domain/library_filter_test.dart`：`LibraryFilter.songs`、`withoutGroups`。
- [x] G2 控制器测试（沿用现有 library controller 测试文件）：无保存视图 → `kinds == {music}`；`setFilter(empty)` → `{music}`；`matching` / `otherKindCount` 有值。
- [x] G3 页头测试（替换 `library_header_radio_test.dart`）：菜单四项、勾选态、专辑按钮显隐与回调。
- [x] G4 `test/domain/library_album_test.dart`：`_albumOf` 等价规则（精确 key、合并节目回退、无专辑返回 null）。
- [x] G5 `test/services/library_database_test.dart`：`kinds={music}` 排除 `archive_podcasts`；`otherKindCount` 计数口径（podcast+audiobook+radio）。
- [x] G6 `flutter analyze` → No issues found。
- [x] G7 `flutter test` 全量（+1709）全绿。
- [x] G8 截图：默认音乐视图（2,948 首，无电台/播客行）与播客作用域（497 集）已截；专辑页与专辑墙由 widget 测试覆盖（本机无法注入桌面点击）。
- [x] G9 作用域持久化：单选类型重启后保留（测试：切播客 → 重建 controller 仍是播客）。
- [x] G10 专辑列 → 专辑页的空结果护栏：专辑读不出曲目时不跳转（测试：`_EmptyAlbumController`）。
