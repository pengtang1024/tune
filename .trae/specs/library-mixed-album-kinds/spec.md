# 方案：`unlocked_recordings` 混合实例的判定粒度

> 状态：待拍板，不含实现。数据取自本机库 `library.db`（`source_id='unlocked_recordings'`，`active=1`，共 103 条）。

## 1. 数据分布（103 条，8 张专辑）

| 专辑 | 条数 | 时长范围 | genre | 内容 | 建议判定 |
| --- | --- | --- | --- | --- | --- |
| Sound Effects In Stereo | 30 | 14–100 s | `Non-Music / Field Recording / Special Effects / Technical`（30/30 一致） | 音效（`No Artist`，6 秒–100 秒的单个声响） | 音效 |
| For Men Only | 14 | 112–997 s | `Jazz / Pop / Big Band / Vocal / Swing` | Lew Raymond 爵士/通俗专辑 | 音乐 |
| The Best Of The Bossa | 14 | 141–1430 s | `Jazz / Latin / Pop / Bossanova` | bossa nova 专辑 | 音乐 |
| The Best Of The Movie Themes 1970 | 13 | 138–2484 s | 空 | Enoch Light 电影主题改编 | 音乐 |
| Moonlight Sonata | 9 | 128–1965 s | `Classical / Romantic / Classical` | 贝多芬/肖邦，含整面音轨 | 音乐 |
| Beethoven's Greatest Hits | 8 | 116–2032 s | `Classical / Romantic / Classical` | Ormandy 精选，含整面音轨 | 音乐 |
| The Koto Music Of Japan | 8 | 126–1502 s | `Classical / Folk, World, & Country / Folk / Classical` | 日本筝，含整面音轨 | 音乐 |
| Death of a salesman | 7 | 924–11634 s | 空 | 整场话剧：6 面 + 1 条「(entire album)」全长重复 | 有声书（话剧录音） |

合计：音效 30、有声书 7、音乐 66。

两条关键事实：

- **时长不能当判据**：话剧 6 面是 924–1720 s，而音乐专辑里存在 1003 / 1236 / 1502 / 1816 / 1965 / 2032 / 2484 s 的整面音轨，区间完全重叠。
- **专辑名在本机不重名**：`death of a salesman`、`sound effects in stereo` 都只出现在 `unlocked_recordings`；但规则仍按「实例 + 专辑」定位，避免将来别的源撞名。

## 2. 粒度：实例默认 + 专辑级例外

**推荐**：保留实例默认（`unlocked_recordings` → 音乐），只在**专辑**这一级加例外。不做逐条覆盖，也不按标题/时长做通用猜测。

理由：

1. IA 的一次导入就是一个 item，item 名就是专辑名；103 条只有 8 张专辑，例外规则只有 2 条，可读可审。
2. 专辑是唯一不会被「重扫」改变的稳定事实：重新扫描会重写 title/genre/duration，但不会把 `Death of a salesman` 改名；逐条覆盖需要另一张按 `uri` 存的表，重扫与合并时容易丢或重复。
3. 专辑卡与作用域必须整体一致：同一张专辑不能一半音乐一半有声书，否则专辑墙的分区、计数、点进去的列表会互相矛盾。

**扩展方式（不破坏已有声明）**：

- `declaredContentKinds`（实例 → 类型）**保持不动**，它继续承担 `radio_recordings`/`archive_podcasts` 这类整实例语义。
- 新增一张只用于「细化未声明实例」的表，按实例 id 与归一化专辑名定位：

```dart
/// 归一名 = 小写、去首尾空白、内部空白折叠成一个空格。
const Map<String, Map<String, ContentKind>> declaredAlbumKinds = {
  'unlocked_recordings': {
    'death of a salesman': ContentKind.audiobook,
  },
};
```

- 读取顺序：`isLiveStream` → 实例声明 `declaredContentKinds` → **专辑例外 `declaredAlbumKinds`（仅当实例未声明时生效）** → 音源类型集合 → 音乐。
- 实例声明优先于专辑例外，是为了让已有声明（电台/播客/有声书整实例）语义不变；专辑例外只用来细分「默认音乐」的实例。

## 3. 判据表与误判代价

| 规则 | 条件 | 结果 | 证据 | 误判代价 |
| --- | --- | --- | --- | --- |
| R1 | 任一 genre 标签以 `non-music` 开头（IA 自己的非音乐分类） | 音效 | 30/30 一致，且标题/时长/艺术家三项吻合 | 低：把音乐误标为音效会从歌曲视图消失，但这是 IA 元数据的显式分类，不是我们的猜测 |
| R2 | 实例 `unlocked_recordings` 且专辑归一名 = `death of a salesman` | 有声书 | 7 条同属一场演出：封面同名、艺术家为作者+导演、标题为 `Side N … Act …` | 低：仅 7 条，仍可播放，只是进入有声书作用域 |
| R3 | 其余 66 条 | 音乐（实例默认） | genre 为爵士/古典/拉丁，曲目为单曲 | — |

**明确拒绝的信号**：

- **时长**：与音乐整面音轨重叠（见 §1），不可用。
- **标题里的 `Act` / `Side`**：歌剧与古典套曲也用 Act/Movement；只有配合专辑名与空 genre 才可信，所以落进 R2 的专辑声明，不做通用关键词规则。
- **艺术家**：`No Artist` / `Various` / `Brazil 's Best` 都是上传者写法。
- **曲目序号/分章形态**：音乐专辑同样有 `disc1side1` 这类整面命名，与话剧分面同形。

**代价不对称**：默认作用域是音乐，把音乐误判成语音/音效会让它从默认视图消失（用户找不到），因此只在**显式元数据**或**人工声明**上移动条目；反向的漏判只是多几行噪音，可接受。

## 4. 音效归哪类：新增第 5 类 `soundEffect`（推荐）

推荐新增 `ContentKind.soundEffect`（「音效」/ "Sound effects"），而不是并进音乐再隐藏。

理由：

1. 它既不是歌曲也不是语音（`isSpokenWord = false`），没有现有类型能诚实表达。
2. 若并进音乐再「打标记 + 歌曲视图默认隐藏」，等于在音乐作用域里造一个隐式子集：计数、专辑墙、分类视图、搜索都要各自记得排除它——正是本轮要求避免的「视图层过滤掩盖问题」。
3. 现有的作用域模型（`kinds` 永不为空、页头单选菜单、SQL 谓词由 domain 常量生成）天然支持第 5 个值，扩展是线性的，不是特例。
4. R1 是通用规则，其他实例/本地文件的 `Non-Music` 标签同样受益。

影响面（实现时一次改齐）：

- `ContentKind` 加值；`LibraryFilterSql.kind` 加谓词（由常量生成，与 Dart 同序）。
- 页头菜单第 5 项 + 工具条计数单位（建议「段」/ "clips"）+ 筛选面板标签 + 专辑卡单位。
- `content_row.dart`（行形态按 track 画）、`content_kind_mark.dart`（音效不打「语音」标记）。
- `otherKindCount` 口径加入音效，否则页头菜单不出现。
- 四份 ARB + `flutter gen-l10n`；`docs/library-browse.md` §5.1/§5.3。

备选（不推荐）：并入音乐并加「非音乐」标记、歌曲视图默认隐藏。省一个枚举值，但把「音乐」拆成两种含义，后续每个视图都要重复排除逻辑。

## 5. 话剧录音：归有声书（推荐）

- 一场演出被切成 6 面，形态就是「一本书的章节」：专辑 = 作品名，条目 = 部分，没有订阅源、没有更新节奏。
- 归播客会把 7 面拆成 7 集，破坏作品整体性，也与「一档节目持续发集」的语义不符。
- 归电台更不对：它不是播出流，也没有 `isLiveStream`。
- 已知不精确：界面文案叫「有声书」，话剧严格说是戏剧录音。目前只有这一个实例；若以后出现更多戏剧/广播剧，再单独加类型比现在为一个专辑加类型更划算。

附带的数据问题：该专辑第 7 条 `(entire album)`（11634 s）是整场全长重复，实现时可考虑按规则一并归入有声书、但在队列/播放里不特殊处理（本轮不处理去重）。

## 6. 不改的东西

- 不加数据库列、不做迁移：判定仍由事实（source/album/genre/live）在读取时算出，重扫不会丢规则。
- 不动 `declaredContentKinds` 现有 9 条声明；`foreign_audio → 有声书` 保持本轮已修结果。
- 不在视图层过滤任何条目。

## 7. 待拍板

1. 音效：新增第 5 类 `soundEffect`（推荐），还是「并入音乐 + 标记 + 默认隐藏」？
2. 话剧 `Death of a salesman`：归有声书（推荐），还是播客/电台？
3. 粒度：实例默认 + 专辑级例外（推荐），是否接受按「实例 + 专辑名」而不是逐条配置？
