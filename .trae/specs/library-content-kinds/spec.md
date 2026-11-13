# 库内内容类型 P0/P1：直播不再伪装歌曲，语音专辑按来源归并

> 依据：用户 2026-11-13 的三条拍板（播客/有声书不做独立导航页；电台彻底移出专辑墙与专辑计数；电台 `artist` 语义要拆成类型化字段）与上一轮设计。本轮只做 **P0 + P1**；第 3 项只评估落点与取舍，不写代码。v1.30.0 已发布，develop / master 已合流，工作区干净。

## 结论先行

- **P0 是纯展示层**：凡是 `isLiveStream`，一律用现有的 `LiveBadge`（`lib/shared/ui/live_badge.dart`，已存在）替代时长；电台从专辑墙与专辑计数里彻底剔除；正在播放页与播放条不再把「正在播出的艺人 + 曲名」当成作者和专辑展示。
- **P1 是领域与存储层**：语音类内容的专辑键从 `album+artist` 改为 `album+sourceId`，同一档播客的所有单集归成一张卡；音乐保持 `album+artist`。不改数据库 schema，`albumSummaries()` 与 Dart 的 `libraryAlbumsOf()` 两条路径一起改。
- **第 3 项（电台类型化字段）归入 P3 单独做**：新增 `onAirArtist` / `onAirTitle` / `onAirYear`，`artist`/`album` 对电台留空；采用「新字段向前写 + UI 兼容读 `sourceData['nowPlaying']` + 升级后触发一次电台重扫」，不按 `' - '` 拆旧数据。

## 已核实的事实（实现前提）

- 唯一的内容类型事实是 `Song.isLiveStream`，只有 `radio_source.dart` 的适配器写 `true`（`lib/data/services/music_sources/radio_source.dart:332`）。
- 电台当前映射：`title` = 台名，`artist` = 正在播出的艺人，`album` = 正在播出的曲名，`duration = 0`，`sourceData['nowPlaying']` = `'艺人 - 曲名'`。
- 播客单集：`album` = 节目名，`artist` = 单集作者（回退节目名），`trackNumber` = 集，`discNumber` = 季。
- 有声书：librivox 用 `genre: 'Audiobook'`，audiobookshelf 用 `album` = 书名、`trackNumber` = 章节。
- 音源实例 id：新实例是 `<type>-<n>`（`newSourceInstance`，`lib/domain/models/music_source.dart:98-121`）；内置实例 id 默认等于 type（`_instance`，`built_in_music_sources.dart:475-501`），Internet Archive 的多实例用自定义 id（`live_music_archive` 等），本轮不处理。
- 专辑不是实体，键是 `album\0artist`（`library_album.dart:97-101`）；SQL 路径是 `app_database.dart:876-948`。
- 专辑计数读 `library.albums`（`library_pane.dart:205-207`），因此只要两条 `albumSummaries` 路径剔除 live，计数自动正确。
- 现有可复用文案：`playerLiveBadge`（直播中）、`nowPlayingDetailNowPlaying`（正在播出 / On air）、`trackFactLive`。**P0/P1 不新增 l10n 键**，因此不需要 `flutter gen-l10n`。

## P0：直播电台不再伪装成一首歌（纯展示）

| # | 文件 | 改动 |
| --- | --- | --- |
| P0-1 | `lib/features/library/presentation/library_row_tail.dart` | 静止态尾部：`song.isLiveStream` 时用 `const LiveBadge()` 替代时长 `Text`；非直播保持不变。 |
| P0-2 | `lib/features/library/presentation/library_columns_view.dart` | `_ColumnCard` 尾部的时长 `Text` 改为 `song.isLiveStream ? const LiveBadge() : Text(...)`，不再画 `00:00`。 |
| P0-3 | `lib/features/search/presentation/online_search_sheet.dart` | `_SongRow` 的时长位：直播用 `LiveBadge`；非直播保留「时长或 `--:--`」。 |
| P0-4 | `lib/shared/ui/track_meta.dart` | `dense` 分行的时长位：直播用 `LiveBadge`；非 dense 已由 `TrackFactStrip` 画直播事实，不动。 |
| P0-5 | `lib/shared/ui/track_facts.dart` | 新增 `String? onAirLineOf(BuildContext context, Song song)`：非直播或无 `sourceData['nowPlaying']` 返回 `null`，否则返回 `'${context.loc.nowPlayingDetailNowPlaying} · $onAir'`。文案派生于现有键，不新增。 |
| P0-6 | `lib/features/player/presentation/now_playing_track_info.dart` | `_Artist.build`：`song.isLiveStream` 时提前返回「正在播出 · …」一行（无内容则 `SizedBox.shrink()`），不再显示被污染的 artist 与「专辑 · 年份」；非直播逻辑完全不变。 |
| P0-7 | `lib/features/player/presentation/player_dock.dart` | 标题下的副行：直播用 `onAirLineOf(...) ?? ''`，非直播保持 artist/未知艺术家。播放条进度区已有的 `LiveBadge` 不动。 |
| P0-8 | `lib/features/library/domain/library_album.dart` | `libraryAlbumsOf` 分组前跳过 `song.isLiveStream`。 |
| P0-9 | `lib/data/services/database/app_database.dart` | `albumSummaries()` 的 `WHERE` 增加 `AND json_extract(json, '$.isLiveStream') IS NOT 1`（沿用该文件既有写法）。 |

P0 不引入新控件、不改行高：`LiveBadge` 的 18px 与现有 mono 时长字号同高，尾部 102px 与 72px 的布局不跳。

## P1：语音类专辑按来源归并（领域 + 存储）

### 分类器

新增 `lib/domain/models/content_kind.dart`：

```dart
enum ContentKind { music, spokenWord, radio }

const Set<String> spokenWordSourceTypes = {
  'podcast_rss', 'podcast_catalog', 'podcast_apple',
  'librivox', 'audiobookshelf',
};

bool isSpokenWordSource(String? sourceId);
ContentKind contentKindOf(Song song); // radio > spokenWord > music
```

`lib/domain/models/music_source.dart` 新增 `String sourceTypeOfId(String id)`：id 末尾是数字（`<type>-<n>`）时取前缀，否则原样返回。与 `newSourceInstance` 共用同一套 id 约定。Internet Archive 的自定义内置 id 归 P3，不在本轮集合里。

### 专辑键

`lib/domain/models/album_summary.dart` 新增顶层函数（数据层与 feature 层共用，避免两份键规则）：

```dart
String albumKeyOf({required String album, required String artist, String? sourceId}) {
  final name = album.trim().toLowerCase();
  if (name.isEmpty) return '\u0000unknown';
  if (isSpokenWordSource(sourceId)) return '$name\u0000src\u0000${sourceId ?? ''}';
  return '$name\u0000${artist.trim().toLowerCase()}';
}
```

`library_album.dart` 的 `libraryAlbumKeyOf(Song)` 改为委托 `albumKeyOf(...)`，不再自己拼键。

### 存储两条路径

- Dart 路径：`libraryAlbumsOf` 用新键 + 跳过 live，`albumSongs` 按 key 匹配，无需额外改动。
- SQL 路径 `app_database.dart`：
  - `albumSummaries()` 改为按 `album, artist, source_id` 分组（同时剔除 live），Dart 侧按 `albumKeyOf` 合并同名键、累加 `trackCount`、保留第一个可用封面，最后按名称、作者排序。
  - `albumSongs(key)`：`split('\u0000')` 得到 3 段且第 2 段为 `src` 时，用 `album + source_id` 查询；否则保持现有 `album + artist` 查询。

不改 schema、不改 `AlbumSummary` 字段；语音专辑的 `artist` 仍取第一集的作者（与现状一致），不额外引入「未知艺术家」文案。

## 不做的事（明确范围）

- 播客 / 有声书 / 电台的独立导航页：不做。
- 「电台自己的入口」（一级导航或独立页）：不在 P0/P1，归 P2；本轮电台仍可从歌曲列表与音源筛选进入。
- 电台类型化字段（第 3 项）：不在本轮实现。
- 视频、试听的差异化呈现：归 P2。
- Internet Archive 内置有声书实例（`audio_bookspoetry` 等）的归并：归 P3。
- 不改 `需求/` 下任何文档；本轮不新增 `docs/` 文档。

## 第 3 项评估：电台 `artist` 语义拆分（P3，单独做）

### 为什么单独做

它同时动模型（`Song`）、音源适配器（`radio_source.dart`）、持久化 JSON、事实面板、详情页与测试；和 P0/P1 的纯展示/归并混在一个提交里，评审看不出哪一层变了。

### 字段设计

- `Song.title` 继续表示台名。
- 新增 `String? onAirArtist`、`String? onAirTitle`、`int? onAirYear`；电台的 `artist`、`album`、`year` 留空。
- `sourceData['nowPlaying']` 保留一个版本用于兼容读取；新写入以类型化字段为准。
- 事实面板的「正在播出」从 `onAirArtist · onAirTitle (year)` 渲染，不再读字符串；详情页同理。
- 语义边界：`onAir*` 是「扫描那一刻电台在播什么」的快照，会过期；UI 不把它当作歌曲作者/专辑。

### 重扫 vs 兼容读取

| 方案 | 代价 | 结论 |
| --- | --- | --- |
| A. 新字段向前写 + UI 兼容读旧 `sourceData` + 升级后触发一次电台重扫 | UI 多一个 fallback 分支；旧库在下一次扫描前仍可读 | **推荐**：无数据丢失，无需解析歧义字符串 |
| B. 只靠重扫，不写 fallback | 代码最简；升级后到首次扫描之间电台信息为空 | 可接受但不必要地牺牲体验 |
| C. 从旧 `artist`/`album` 按 `' - '` 反拆 | 最便宜；艺人名或曲名本身含 `' - '` 时拆错，且不可逆 | 拒绝 |

推荐 A；重扫沿用现有扫描（按 `uri` 覆盖），不需要迁移脚本，也不改 SQLite 表结构。

## 验收

- `flutter analyze` 无问题；`flutter test` 全绿。
- 新增 / 更新的测试：
  - `test/domain/library_album_test.dart`：同一档播客、不同单集作者 → 一张专辑；直播电台不进入专辑；音乐分组不变；`sourceTypeOfId` / `isSpokenWordSource` 的实例 id 与内置 id 用例。
  - `test/services/library_database_test.dart`：SQL 路径的 `albumSummaries` 合并语音单集、剔除 live；`albumSongs` 能按新键取回单集。
- 手工抽查（Linux 桌面）：库列表、双列墙、搜索结果、队列/喜欢、正在播放页、播放条六处直播显示徽标而非时长；专辑墙与页头专辑计数不含电台。
- 本轮改动不 push，不夹带无关文件；提交按 P0、P1 分开（建议 `feat(library): 直播电台改用直播徽标`、`refactor(library): 语音类专辑按来源归并`）。
