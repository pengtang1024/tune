# 任务：库内内容类型 P0/P1

> 依据：`spec.md`。每项完成即勾选。

## A. P0 展示层（直播不再伪装歌曲）

- [x] A1 `library_row_tail.dart`：直播用 `LiveBadge` 替代时长。
- [x] A2 `library_columns_view.dart`：`_ColumnCard` 直播用 `LiveBadge`，去掉零时长。
- [x] A3 `online_search_sheet.dart`：`_SongRow` 直播用 `LiveBadge` 替代 `--:--`。
- [x] A4 `track_meta.dart`：`dense` 分行直播用 `LiveBadge`。
- [x] A5 `track_facts.dart`：新增 `onAirLineOf(context, song)`。
- [x] A6 `now_playing_track_info.dart`：电台副行改为「正在播出 · …」，收起 artist 与「专辑 · 年份」。
- [x] A7 `player_dock.dart`：电台副行改为「正在播出 · …」。
- [x] A8 `library_album.dart`：`libraryAlbumsOf` 跳过 live。
- [x] A9 `app_database.dart`：`albumSummaries()` 的 `WHERE` 剔除 live。
- [x] A10 `flutter analyze` + 测试通过。

## B. P1 领域与存储（语音专辑归并）

- [x] B1 `music_source.dart`：新增 `sourceTypeOfId`。
- [x] B2 新增 `lib/domain/models/content_kind.dart`：`ContentKind`、`spokenWordSourceTypes`、`isSpokenWordSource`、`contentKindOf`。
- [x] B3 `album_summary.dart`：新增 `albumKeyOf(...)`。
- [x] B4 `library_album.dart`：`libraryAlbumKeyOf` 委托 `albumKeyOf`。
- [x] B5 `app_database.dart`：`albumSummaries()` 按 `album, artist, source_id` 分组后按新键合并；`albumSongs(key)` 支持 `album\0src\0<sourceId>`。
- [x] B6 提交 P1（`library_album.dart` 与 `app_database.dart` 同时含 P0 改动，无法按文件拆分，P0/P1 合为一个提交）。

## C. 测试

- [x] C1 `test/domain/library_album_test.dart`：语音归并、live 剔除、音乐不变、分类器用例。
- [x] C2 `test/services/library_database_test.dart`：SQL 路径的合并、剔除与按新键取曲。
- [x] C3 `flutter analyze`（No issues found）与 `flutter test`（除网络用例 1521 项全绿）。

## D. 收尾

- [x] D1 `git status` 只含本步文件；不 push。
- [x] D2 汇报：P0/P1 证据、门禁结果，以及第 3 项（电台类型化字段）的 P3 落点与重扫/兼容取舍。

## E. P3 电台类型化在播字段

- [x] E1 `song.dart`：新增 `onAirArtist` / `onAirTitle` / `onAirYear`，接入 `fromMap`、`copyWith`、`toJson`。
- [x] E2 `source_song_factory.dart`：`create` 透传三个在播字段。
- [x] E3 `radio_source.dart`：`buildSongs` 不再写 `artist`/`album`/`year`，改写 typed 字段；`sourceData['nowPlaying']` 保留一版。
- [x] E4 `track_metadata_facts.dart`：新增 `onAirOf(song)`，typed 优先、`nowPlaying` 回退；`_onAirFact` 读它。
- [x] E5 `track_facts.dart`：`onAirLineOf` 改用 `onAirOf`。
- [x] E6 `library_controller.dart`：新增 `migrateRadioOnAir()`，只重扫 enabled 的 radio 源，flag 先写。
- [x] E7 `app.dart`：启动时先迁移电台字段，再按设置决定是否自动扫描。
- [x] E8 测试：电台/ AzuraCast 断言改为 artist/album 空 + typed 字段；`Song` JSON round-trip；`onAirOf` 兼容读四条。
- [x] E9 `flutter analyze`（No issues found）与 `flutter test`（除网络用例 1526 项全绿）。

## F. P4 三种行形态与类型标识

- [x] F1 `content_kind.dart`：新增播客 / 有声书集合与 `isPodcastSource` / `isAudiobookSource`。
- [x] F2 新增 `lib/shared/ui/content_kind_mark.dart`：`contentKindLabelOf`、`contentKindIconOf`、`ContentKindMark`。
- [x] F3 新增 `lib/shared/ui/content_row.dart`：`RowShape`、`rowShapeOf`、`rowSubtitleOf`、`rowColumnsOf`。
- [x] F4 `track_metadata_facts.dart`：`metadataFactsOf` 首项加 `_contentKindFact`（仅语音，compact）。
- [x] F5 `library_track_card.dart`：两列改 `rowColumnsOf`，标题旁挂 `ContentKindMark`。
- [x] F6 `library_columns_view.dart`：标题挂标；副行按曲目 / 语音 / 电台分流。
- [x] F7 `track_meta.dart`：`_byline` 改 `rowSubtitleOf`；dense 副行与标题挂标。
- [x] F8 `online_search_sheet.dart`：`_SongRow` 副行改 `rowSubtitleOf`。
- [x] F9 四份 ARB 新增三键并 `flutter gen-l10n`。
- [x] F10 `docs/chips.md` 补「内容类型」一段。
- [x] F11 新增 `test/domain/content_kind_test.dart` 与 `test/app/content_row_test.dart`。
- [x] F12 `flutter analyze` 与过滤网络 e2e 的 `flutter test` 全绿；提交（不 push）。

