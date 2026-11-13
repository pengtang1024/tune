# 任务：音乐库浏览层（类型维度 / 电台入口 / 专辑墙分节）

> 依据：`spec.md`。全部完成（2026-11-13）。门禁：`flutter analyze` No issues found；`flutter test` 1557 通过（排除两个网络 e2e）。

## A. 分类器拆四类

- [x] A1 `content_kind.dart`：`ContentKind { music, podcast, audiobook, radio }` + `isSpokenWord` + `contentKindOfSource`；`contentKindOf` 委托。
- [x] A2 `content_row.dart`：`rowShapeOf` 用 `podcast || audiobook => spokenWord`。
- [x] A3 `content_kind_mark.dart`：标签按四值 switch，图标用 `isSpokenWord`。
- [x] A4 更新 `content_kind_test.dart`、`library_album_test.dart` 的旧断言。

## B. 筛选链路

- [x] B1 `library_filter.dart`：`kinds` 字段 + isEmpty / activeGroups / copyWith / == / hashCode。
- [x] B2 `library_view.dart`：`kinds` 序列化与解析。
- [x] B3 `library_filter_sql.dart`：`kind(...)` 子句（radio / music / podcast / audiobook，live 优先）。
- [x] B4 `library_facets.dart`：`kinds` 计数。
- [x] B5 `library_facets_query.dart`：新增 `_FacetGroup.kinds`、`live` 基础列、计数与下标调整。
- [x] B6 `library_filter_labels.dart`：`filterKindLabel`。
- [x] B7 `library_filter_panel.dart`：「类型」组。
- [x] B8 `library_filter_chips.dart`：类型 chip。

## C. 分类维度与树

- [x] C1 `library_category.dart`：追加 `kinds`。
- [x] C2 `library_category_view.dart`：kinds 卡片、封面取值、tab 文案与图标。
- [x] C3 `library_category_tree.dart`：kinds 组、选中态、文案与图标。
- [x] C4 `library_pane.dart::_selectCategoryValue`：kinds 下钻。

## D. 专辑类型与分节

- [x] D1 `album_summary.dart`：`kind` 字段（默认 music）。
- [x] D2 `library_album.dart`：`LibraryAlbum.kind` 与 `_albumOf` 赋值。
- [x] D3 `library_storage_io.dart`：Dart 路径透传 `kind`。
- [x] D4 `app_database.dart::albumSummaries`：SQL 路径写 `kind`。
- [x] D5 `library_pane.dart::_albumOf`：透传 `summary.kind`。
- [x] D6 `library_albums_view.dart`：`CustomScrollView` 三节、节头条件、集/章/首、语音徽标。

## E. 页头电台入口

- [x] E1 `library_header.dart`：`onRadio` / `radioActive` 按钮。
- [x] E2 `library_pane.dart`：显示条件与 `_toggleRadio`。

## F. 文案与文档

- [x] F1 四份 ARB 加 5 键（`libraryFilterKinds`、`contentKindMusic`、`contentKindRadio`、`libraryEpisodeCount`、`libraryChapterCount`）。
- [x] F2 `flutter gen-l10n` 并保留产物。
- [x] F3 `docs/library-browse.md` 更新第 7 维、电台入口、专辑分节。
- [x] F4 `library-content-kinds/spec.md` 修正旧枚举并指向本规格。

## G. 测试与门禁

- [x] G1 `library_filter_test.dart`：面板类型组、chip 增删。
- [x] G2 `library_category_test.dart`：kinds 卡片回传。
- [x] G3 新增 `library_header_radio_test.dart`：按钮显隐与回调。
- [x] G4 `library_albums_test.dart`：节头条件与集/章/首。
- [x] G5 `library_database_test.dart`：kinds 计数、筛选查询、专辑 kind。
- [x] G6 `flutter analyze` → No issues found。
- [x] G7 `flutter test`（排除两个网络 e2e）全绿：1557 通过。
- [x] G8 提交 `feat(library): 内容类型成为浏览维度并加电台入口`；不 push。
- [x] G9 汇报：改动点、入口与分节形态、门禁结果。
