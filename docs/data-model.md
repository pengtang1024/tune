# 数据模型

> 状态：契约 · 适用版本 1.33.0 · 最后核对 2026-11-15
>
> 本文写清 Tune 的 SQLite 数据模型与写库纪律：库里有哪几张表、每张表的真实列、谁写谁读、加表加列怎么走、数据什么时候被清掉。**谁改表（DDL、列、索引、清理时机）谁同步这里**；与代码冲突时以代码为准，并顺手改掉本文件对应那句（`AGENTS.md:5`）。
>
> 事实来源：`lib/data/services/database/` 的建表 SQL 与读写方法，以及 `lib/features/*/data/` 里的几个 store。性能诊断数字不在这里重复，见 `docs/performance.md`。

## 目录

- [1. 一句话定位](#1-一句话定位)
- [2. 表清单总览](#2-表清单总览)
- [3. 逐表](#3-逐表)
- [4. 迁移与版本](#4-迁移与版本)
- [5. 写库纪律](#5-写库纪律)
- [6. 生命周期](#6-生命周期)

## 1. 一句话定位

**表的形状看这里，写库的规矩看这里，别在别处另写一份。** 本文只描述现状，不描述规划。

## 2. 表清单总览

共 **11 张表**，全部落在同一个文件：`<application support>/library/library.db`（`lib/features/library/data/impl/library_storage_io.dart:362,394-396`）。打开时设 `journal_mode = WAL`、`synchronous = NORMAL`、`busy_timeout = 5000`（`lib/data/services/database/app_database.dart:48-52`）；曲库、播放会话、播放记录、智能歌词四个 store 各自 `AppDatabase.open` 同一个路径，所以「同一个库」是靠路径约定，不是靠一个单例。

| 表名 | 存什么 | 谁写 | 谁读 |
| --- | --- | --- | --- |
| `songs` | 曲库索引，一行一首；`json` 列存整首 `Song` | `SqliteLibraryStorage`（`ingest` / `save` / `deactivateUncovered` / `prune` / `syncPinned` / `markPlayed` / `clear`） | `LibraryQuery`、`LibraryFilterSql`、`LibraryFacetsQuery`、智能歌词各 store |
| `favorites` | 收藏的曲目 uri 与收藏时间 | `FavoritesStore`（`lib/features/favorites/data/favorites_store.dart:49,93`） | 同一 store 的 `loadFavorites`、口味聚合、筛选与分面 |
| `queue` | 播放队列快照，一行一个位置 | `PlaybackSessionStore.saveQueue` | 同一 store 的 `init()`（重启恢复） |
| `queue_meta` | 会话小值：当前曲、模式、历史、进度 | `PlaybackSessionStore`（`saveQueue` / `savePosition` / `clearPosition`） | 同一 store 的 `init()` |
| `listening_signals` | 每首的收听聚合（uri + 五个数字） | `ListeningSignalStore`（`recordListen` / `recordSkip`） | 同一 store 的 `init()`、口味聚合 |
| `smart_lyrics_sample` | 准确率审计的分层抽样名单 | `SmartLyricsSampleStore.draw` | 同一 store 的 `read` / `tracksOf` |
| `smart_lyrics_audit` | 人工对抽样的判定 | `SmartLyricsSampleStore.recordVerdict` | 同一 store 的 `read`（左连接） |
| `smart_lyrics_tasks` | 智能歌词批处理队列 | `SmartLyricsTaskStore`、`requeueSongTask` | 任务卡、筛选、标记页、批处理调度 |
| `smart_lyrics_marks` | 读者/共识打的标记 | `SmartLyricsTaskStore` 的标记方法 | 标记管理页、歌词面板、任务排序 |
| `text_translations` | 翻译缓存（按文本哈希） | `TranslationStore.writeBatch` | `TranslationStore.readHashes` |
| `translation_usage` | 翻译 token 账本 | `TranslationStore.addUsage` | `TranslationStore.usageSince` |

## 3. 逐表

### 3.1 `songs` —— 曲库索引

建表在 `lib/data/services/database/app_database.dart:54-73`；`facts_hash`、`active`、`title_sort` 三列不在建表语句里，由 `_migrateColumns` 补（同文件 `:190-217`），新库也走这一遍。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `uri` | TEXT | `PRIMARY KEY` | 曲目唯一键；本地文件与流地址共用这一列 |
| `source_id` | TEXT | 可空 | 音源 id；旧库为 NULL 的会在打开时回填 `'local'`（`:226`） |
| `title` | TEXT | — | 标题原文，不折叠 |
| `artist` | TEXT | — | 艺术家 |
| `album` | TEXT | — | 专辑 |
| `date_added` | INTEGER | — | 入库毫秒时间戳；`<= 0` 在「最近添加」里排最后 |
| `year` | INTEGER | 可空 | 年份，分面按十年聚合 |
| `genre` | TEXT | 可空 | 单值流派；多值在 `json.genres` |
| `json` | TEXT | `NOT NULL` | 整首 `Song.toMap()` 的 JSON，**读窗口只解这一列** |
| `pinned` | INTEGER | `NOT NULL DEFAULT 0` | 收藏/固定标记，`prune` 永不删 |
| `last_seen` | INTEGER | `NOT NULL DEFAULT 0` | 扫描最近一次见到的时间 |
| `last_played` | INTEGER | 可空 | 上次播放时间，`markPlayed` 写 |
| `play_count` | INTEGER | `NOT NULL DEFAULT 0` | 播放次数，`markPlayed` 加一 |
| `has_lyrics` | INTEGER | `NOT NULL DEFAULT 0` | 是否已知有词；账本与筛选取它 |
| `language` | TEXT | 可空 | 语言键，筛选/分面用 |
| `format` | TEXT | 可空 | 容器格式 |
| `duration` | INTEGER | `NOT NULL DEFAULT 0` | 毫秒；`<= 0` 视为时长缺失 |
| `facts_hash` | INTEGER | `NOT NULL DEFAULT 0` | 事实指纹；同 hash 的重扫零写 |
| `active` | INTEGER | `NOT NULL DEFAULT 1` | 1 = 在库；0 = 源关闭或文件消失 |
| `title_sort` | TEXT | `NOT NULL DEFAULT ''` | `foldText(title)` 的折叠键，排序用 |

索引（`app_database.dart:74-77,164-180`）：

- 单列：`idx_songs_source(source_id)`、`idx_songs_title(title)`、`idx_songs_year(year)`、`idx_songs_date_added(date_added)`、`idx_songs_duration(duration)`、`idx_songs_has_lyrics(has_lyrics)`、`idx_songs_language(language)`、`idx_songs_format(format)`。
- 两个部分索引：`idx_songs_added_order ON songs(date_added DESC, uri ASC) WHERE active = 1`、`idx_songs_title_order ON songs(title_sort COLLATE NOCASE, uri) WHERE active = 1`。它们的排序与 `LibraryQuery._order` 的 tie break 对齐（`lib/data/services/database/library_query.dart:82-90`），所以一页大库是顺着索引读，不是每次排。

关键说明：

- `json` 是事实来源，其余列是为 SQL 筛选/排序/计数做的投影；两边不一致就是写库 bug，不是「以列为准」。
- `active = 1` 是所有读路径的前置条件：`load()`（`:308-314`）、`count()`（`:1313-1322`）、`LibraryFilterSql.where` 的第一条子句（`lib/data/services/database/library_filter_sql.dart:17`）。
- `facts_hash` 覆盖 `Song` 的文档字段与音源字段（`app_database.dart:335-383`）；`ingestBatch` 见同 hash 直接 `continue`（`:513-519`），这就是「同事实重扫零写」。

### 3.2 `favorites` —— 收藏

建表 `app_database.dart:137-142`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `uri` | TEXT | `PRIMARY KEY` | 收藏的曲目 uri |
| `added_at` | INTEGER | `NOT NULL DEFAULT 0` | 收藏毫秒时间戳，`loadFavorites` 按它排序 |

无额外索引（主键即索引）。关键说明：**没有外键**，`favorites` 的 `uri` 与 `songs.uri` 靠约定对齐；`saveFavorites` 是全量差集（删掉不在集合里的、插入新增的并写 `now`，`:1114-1142`）。`prune` 之前 `syncPinned(_pinnedUris())` 先把收藏 uri 标成 `pinned = 1`（`lib/features/library/application/library_controller.dart:773-780`），收藏行不被裁掉靠的是这个写入顺序，不是数据库约束。

### 3.3 `queue` —— 播放队列快照

建表 `app_database.dart:143-149`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `position` | INTEGER | `PRIMARY KEY` | 播放顺序，从 0 连续递增 |
| `uri` | TEXT | `NOT NULL` | 冗余的曲目 uri，便于排查 |
| `json` | TEXT | `NOT NULL` | 整首 `Song.toJson()`，读取只解这一列 |

关键说明：`saveQueue` 是**整表替换**——先 `DELETE FROM queue` 再逐行插入，全程一个事务（`:1160-1181`）。队列本来只在播放器内存里，这张表只是重启快照，不是播放状态的第二份真源。

### 3.4 `queue_meta` —— 会话小值

建表 `app_database.dart:150-155`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `key` | TEXT | `PRIMARY KEY` | 键 |
| `value` | TEXT | `NOT NULL` | 值，统一按字符串存 |

固定键空间只有 5 个：`currentUri`、`playMode`、`history`、`positionUri`、`positionMs`（`lib/features/player/data/playback_session_store.dart:204-210`）。`playMode` 存 `PlayMode.name`；`history` 存 JSON 数组，上限 50 条（同文件 `:42`）。写入是单键 UPSERT：`INSERT ... ON CONFLICT(key) DO UPDATE SET value = excluded.value`（`app_database.dart:1195-1214`）。

### 3.5 `listening_signals` —— 收听聚合

建表 `app_database.dart:156-161`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `uri` | TEXT | `PRIMARY KEY` | 曲目 uri |
| `json` | TEXT | `NOT NULL` | `TrackListening.toJson()`：只含时长、完成次数、跳过次数等数字，不存标题/艺术家 |

关键说明：写入单条用 `INSERT OR REPLACE`（`:1253-1257`）；全量写 `saveListening` 会先删差集、再对同 json 的行跳过（`:1273-1301`）。这张表与发现页共用，只在用户打开本地收听记录时写（`lib/features/discovery/data/listening_signal_store.dart:11-17`）。

### 3.6 `smart_lyrics_sample` —— 审计抽样

建表 `app_database.dart:81-87`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `uri` | TEXT | `PRIMARY KEY` | 被抽中的曲目 |
| `layer` | TEXT | `NOT NULL` | 分层名（`SmartLyricsLayer.id`） |
| `added_at` | INTEGER | `NOT NULL` | 抽中时间毫秒 |

写入 `INSERT OR IGNORE`（`:1384-1408`）：重抽只**追加**，旧行与旧判定都留着。读取都 `JOIN songs ... AND s.active = 1`（`:1411-1453`），库外曲目不会污染抽样账。

### 3.7 `smart_lyrics_audit` —— 人工判定

建表 `app_database.dart:88-94`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `uri` | TEXT | `PRIMARY KEY` | 与 `smart_lyrics_sample.uri` 对齐 |
| `verdict` | TEXT | `NOT NULL` | 只有 `'correct'` / `'incorrect'` 两个值（`:1464`） |
| `checked_at` | INTEGER | `NOT NULL` | 判定时间毫秒 |

写入是 UPSERT：`ON CONFLICT(uri) DO UPDATE SET verdict = excluded.verdict, checked_at = excluded.checked_at`（`:1455-1468`），一个人可以改判。

### 3.8 `smart_lyrics_tasks` —— 批处理队列

建表 `app_database.dart:98-109`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `song_id` | INTEGER | `PRIMARY KEY` | **`Song.id`，取自 `json_extract(json,'$.id')`**，不是 SQLite rowid |
| `uri` | TEXT | `NOT NULL` | 冗余的曲目 uri |
| `status` | TEXT | `NOT NULL` | `pending` / `running` / `done` / `disputed` / `instrumental` / `failed` / `skipped`（`lib/features/smart_lyrics/domain/smart_lyrics_task.dart:9-32`） |
| `votes` | INTEGER | `NOT NULL DEFAULT 0` | 票池给到的票数 |
| `disputed` | INTEGER | `NOT NULL DEFAULT 0` | 仍有争议的行数 |
| `attempts` | INTEGER | `NOT NULL DEFAULT 0` | 已尝试次数，`beginTaskRun` 加一 |
| `last_error` | TEXT | 可空 | 最近一次失败的原文 |
| `updated_at` | INTEGER | `NOT NULL DEFAULT 0` | 状态更新时间毫秒 |

无额外索引：点查走主键，`GROUP BY status` 全表扫（表规模是缺口曲目数，不是整个曲库）。关键说明：与 `songs` 没有外键，读的一侧一律 `JOIN songs ON ... = t.song_id AND songs.active = 1`（`:1526-1555`）；入队只补缺口，条件是 `active = 1 AND has_lyrics = 0 AND 非直播 AND duration <= 10 分钟 AND 无同名任务`（`:1471-1500`）。

### 3.9 `smart_lyrics_marks` —— 标记

建表 `app_database.dart:121-132`。打开时先探测 `PRAGMA table_info`，**没有 `line` 列的旧表直接 `DROP TABLE` 重建**（`:114-120`）——这是全库唯一一处破坏性结构迁移。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `id` | INTEGER | `PRIMARY KEY AUTOINCREMENT` | 自增主键，`ORDER BY id` 即标记先后 |
| `song_id` | INTEGER | `NOT NULL` | `Song.id`，同 3.8 |
| `line` | INTEGER | 可空 | 行号；NULL 表示整首或「不是唱的」 |
| `kind` | TEXT | `NOT NULL` | `line` / `song` / `instrumental`（`lib/features/smart_lyrics/domain/smart_lyrics_mark.dart:8-19`） |
| `source` | TEXT | `NOT NULL` | `system`（票池共识）或读者 |
| `state` | TEXT | `NOT NULL` | `uncleared` / `resolved` / `reworded` / `revoked`（同文件 `:22-41`） |
| `created_at` | INTEGER | `NOT NULL DEFAULT 0` | 创建时间毫秒 |
| `updated_at` | INTEGER | `NOT NULL DEFAULT 0` | 状态变更时间毫秒 |

索引：`idx_marks_song ON smart_lyrics_marks(song_id)`（`:133-136`）。关键说明：标记**只改 `state`，从不删行**——撤回是 `revoked`，重解成功是 `resolved`，读者自己改词是 `reworded`（`:1696-1709,1733-1743,1797-1803`）。

### 3.10 `text_translations` —— 翻译缓存

建表 `lib/data/services/database/translation_tables.dart:14-24`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `text_hash` | TEXT | 复合主键第 1 列 | 源文本哈希，不是曲目 id |
| `source_text` | TEXT | `NOT NULL` | 原文，便于排查 |
| `target_lang` | TEXT | 复合主键第 2 列 | 目标语言 |
| `engine` | TEXT | 复合主键第 3 列 | 翻译引擎 |
| `value` | TEXT | `NOT NULL` | 译文 |
| `created_at` | INTEGER | `NOT NULL` | 写入时间毫秒 |

`PRIMARY KEY (text_hash, target_lang, engine)`；无额外索引（主键即查询路径）。写入是 `INSERT OR IGNORE`（`:52-85`，**已存在的行胜出**，不覆盖人工改过的译文）；读取按 `(target_lang, engine)` 一次取回整批（`:36-49`）。

### 3.11 `translation_usage` —— token 账本

建表 `lib/data/services/database/translation_tables.dart:25-33`。

| 列 | 类型 | 约束 / 默认值 | 说明 |
| --- | --- | --- | --- |
| `id` | INTEGER | `PRIMARY KEY AUTOINCREMENT` | 流水号 |
| `engine` | TEXT | `NOT NULL` | 引擎 |
| `prompt_tokens` | INTEGER | `NOT NULL DEFAULT 0` | 输入 token |
| `completion_tokens` | INTEGER | `NOT NULL DEFAULT 0` | 输出 token |
| `created_at` | INTEGER | `NOT NULL` | 记账时间毫秒 |

只追加，不改不删。`addUsage` 在两个 token 都是 0 时直接返回、不写行（`:96-109`）；`usageSince(since)` 按时间窗聚合（`:111-123`），设置页按周期读。

## 4. 迁移与版本

**先说结论：本项目没有 `PRAGMA user_version`。** 全仓 `lib/` 下 grep `user_version` 无命中（2026-11-15 核实）。版本不是数字，而是**每次打开无条件重跑一遍幂等 DDL + 列探测**：

1. `AppDatabase._prepare` 的顺序是有依赖的，不能调（`app_database.dart:43-182`）：`PRAGMA` → 建表 → `TranslationTables.ensureSchema` → `_migrateColumns` → 建索引。索引放在最后，因为 `idx_songs_added_order` / `idx_songs_title_order` 用到迁移列 `active`、`title_sort`。
2. **加表**：加一条 `CREATE TABLE IF NOT EXISTS`，跨模块的（翻译）放进 `TranslationTables.ensureSchema`。不要写版本判断，也不要写「如果不存在版本 X」。
3. **加列**：往 `_migrateColumns` 的 `additions` 里加 `'列名': '列名 TYPE ...'`（`:190-217`）。必须是 `NOT NULL DEFAULT` 或可空，否则老库的 `ALTER TABLE ... ADD COLUMN` 会失败；新库也走同一遍，所以**列只在这里定义一次**。需要回填历史行，就仿 `_backfillTitleSort`（`:281-304`）：`added` 集合命中时跑一次、`BEGIN/COMMIT`、坏行跳过。
4. **改结构**：`PRAGMA table_info` 探测 + `DROP TABLE` 重建，现例只有 `smart_lyrics_marks`（`:114-120`）。代价是丢旧行，只在「旧行没有读者」时用。
5. **一次性搬数据**：旧 JSON 文档在对应 store 的 `init()` 里按「库为空」条件导入——曲库 `scanned_songs.json` 迁完改名 `.migrated`（`lib/features/library/data/impl/library_storage_io.dart:411-429`），队列与播放记录同理（`lib/features/player/data/playback_session_store.dart:53-62`、`lib/features/discovery/data/listening_signal_store.dart:46-57`）。
6. **若要引入 `user_version`**：必须同时写「读版本 → 按版本升级 → 成功后写回」，并与现有幂等 DDL 二选一，不能两套并存。这一步**尚未做**，不要假设库里有版本号。

## 5. 写库纪律

`AGENTS.md:109-110` 的原话：

> **每操作路径不做写放大。** 写库按键、按需、按批：单键 UPSERT、搜索防抖、进度节流、行形态归一（同事实重扫零写、改名一写）。

配合 `AGENTS.md:107-108` 的「**库不入内存**：`LibraryState.songs` 始终是数据库读出的一个窗口（`windowSize = 1000`）」。落到数据库层是这六条：

| 纪律 | 代码落点 |
| --- | --- |
| 单键 UPSERT | `queue_meta` 的 `ON CONFLICT(key) DO UPDATE`（`app_database.dart:1195-1214`）；`favorites` / `text_translations` / `smart_lyrics_sample` 用 `INSERT OR IGNORE`；`listening_signals` 用 `INSERT OR REPLACE`；`smart_lyrics_audit`、`smart_lyrics_tasks` 用 `ON CONFLICT(...) DO UPDATE`（`:1455-1468,1745-1754`） |
| 搜索防抖 | 防抖在上层（180ms，见 `docs/performance.md:470`）；数据库侧只承担一次窗口查询，不在每个按键上做全表重载 |
| 进度节流 | 进度只写 `queue_meta` 的 `positionUri` / `positionMs` 两个键（`playback_session_store.dart:154-159`），一次 1–2 行，不重写队列 |
| 行形态归一 | `mergedCandidate` 把扫描结果与已存行折成唯一形状（`app_database.dart:603-621`）；`facts_hash` 相同就跳过写（`:513-519`）→ 同事实重扫 0 写；改名走同一条 UPSERT → 1 写 |
| 库不入内存 | `load()` / `page()` / `query()` 都带 `LIMIT`（`library_query.dart:31-35`），分面在独立 isolate 的第二条连接上算（`lib/data/services/database/facets_worker.dart:19-25`） |
| 不在循环里查库 | 批量读用 `IN (...)` 按 500 个一组（`_existingRows` 与 `deleteListening`，`app_database.dart:563-579,1261-1272`）；大量 id 走临时表 `tune_pins`（`:769-797`）；筛选合成一条 SQL（`LibraryFilterSql.where`） |

写库还有两条硬约束：**所有批量写都在 `BEGIN` / `COMMIT` 里，异常 `ROLLBACK` 后重抛**（如 `:394-462`、`:1160-1181`）；**坏行不拖垮整批**——解码失败的行跳过而不是抛（`:317-329`、`library_query.dart:105-117`）。另外，`favorites`、`syncPinned` 里有逐行 `statement.execute`，但复用的是同一个 prepared statement，属于批量写，不是「循环里查库」。

## 6. 生命周期

| 表 | 何时清空 / 裁剪 |
| --- | --- |
| `songs` | `clear()` 清整表（`app_database.dart:1308-1311`，入口 `LibraryController.clearLibrary`）；`removeSource(sourceId)` 删一个源（`:1047-1049`）；`deactivateUncovered` 只把行置 `active = 0` 不删（`:645-721`），源恢复或文件回来再由扫描置回 1；`prune(limit)` 每个远程源按 `last_played`、`play_count`、`last_seen`、`date_added` 排名只留前 `limit`，`pinned = 1` 与 `source_id = 'local'` 不参与（`:734-766`） |
| `favorites` | 不随 `clear()` 清空；只在 `saveFavorites` 的差集里删除。行本身没有级联，靠 `syncPinned` 提前标 `pinned` 保住对应 `songs` 行 |
| `queue` | 队列为空或显式清空时整表删（`playback_session_store.dart:99-101,172-182`）；`clearQueue()` 连 `queue_meta` 一起清（`app_database.dart:1235-1238`） |
| `queue_meta` | `clearPosition` 只删 `positionUri`、`positionMs` 两个键（`playback_session_store.dart:184-193`）；`clearQueue()` 清全部键 |
| `listening_signals` | 上限 2000 条（`listening_signal_store.dart:28`）；每写一条后按 `lastPlayedAt` 排序裁剪，多出的批量 `deleteListening`（`:139-148,187-198`）；设置页可整表清（`clearListening`，`app_database.dart:1303-1305`） |
| `smart_lyrics_sample` | 只增不删；重抽不重置，旧行与旧判定保留（`:1384-1408`） |
| `smart_lyrics_audit` | 只 UPSERT，不删 |
| `smart_lyrics_tasks` | 入队只补缺口（`:1471-1500`）；`dropUnqueueableTasks` 删直播与超 10 分钟的 `pending`/`failed`/`running` 行（`:1619-1629`）；`requeueInterruptedTasks` 把上次残留的 `running` 回 `pending`（`:1632-1641`）；没有「清空全部任务」的入口 |
| `smart_lyrics_marks` | 不删行，只改 `state`；旧结构在打开时 `DROP TABLE` 重建（`:114-120`） |
| `text_translations` | `clear()` 整表清（`translation_tables.dart:94`，入口设置页本地化卡片 `lib/features/settings/presentation/settings_localization_card.dart:180`） |
| `translation_usage` | 只追加，无裁剪；读取按时间窗聚合 |

## 相关文档

- [架构契约](architecture.md) — 状态归属与持久化边界
- [性能](performance.md) — 写放大、窗口查询与预算的判据
- [智能歌词](smart-lyrics.md) — 歌词相关几张表的票池与账本口径
- [测试与验证](verification.md) — 改表后要跑的门禁
