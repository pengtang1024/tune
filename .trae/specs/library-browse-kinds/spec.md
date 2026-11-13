# 音乐库浏览层：内容类型成为浏览维度、电台入口、专辑墙分节

> 依据：用户 2026-11-13 拍板的 A 方案 + 三项补充。A = 音乐库页头加「电台」入口，内容区切到台站列表，走「类型=电台」的同一条筛选，不新增一级导航。其余三项 = 类型拆成音乐 / 播客 / 有声书 / 电台并进分类视图、左侧树、筛选面板与 chip；专辑墙按音乐 / 播客 / 有声书分节，节头只在至少两节非空时出现，节目与书用「集」「章」计数；电台不进专辑墙、不计入专辑数。
>
> 前置：P4 已推送（HEAD = `ea5f112`，工作区干净）。本规格只做浏览层，不改行形态、不改 `Song` 模型、不新增一级导航。

## 结论先行

- `ContentKind` 从三值拆成四值：`music / podcast / audiobook / radio`；`spokenWord` 退化为 `bool get isSpokenWord`。行形态仍是三种（曲目 / 语音 / 电台），所以 `RowShape` 不变。
- 「类型」成为与流派 / 年代 / 艺人 / 音源 / 语言 / 格式并列的第 7 个浏览维度，同时进 `LibraryFilter`、SQL、facets、面板、chip、分类视图卡片、左侧树。
- 专辑墙改为分节滚动：音乐 / 播客 / 有声书三节，节头只在至少两节非空时出现；节目卡计数「集」、书卡「章」、音乐仍「首」；语音卡挂类型徽标。
- 电台入口只放在音乐库页头，点击等价于「类型=电台」筛选并切回歌曲列表；再点一次只移除电台这一项。
- 电台继续不进专辑墙、不计入页头专辑数（两条 `albumSummaries` 路径已剔除 live，本规格只补 `kind`）。

## 已核实的事实

- `lib/domain/models/content_kind.dart` 当前为 `{music, spokenWord, radio}`，已有 `podcastSourceTypes` / `audiobookSourceTypes` / `isPodcastSource` / `isAudiobookSource` / `contentKindOf`。
- `RowShape` 与三种行形态在 `lib/shared/ui/content_row.dart`；`ContentKindMark` 在 `lib/shared/ui/content_kind_mark.dart`，二者只按「是否语音」分流。
- 筛选链路：`LibraryFilter`（`lib/domain/models/library_filter.dart`）→ `LibraryFilterSql.where`（`lib/data/services/database/library_filter_sql.dart`）→ 查询 `library_query.dart`；facets 在 `library_facets_query.dart`，模型 `lib/domain/models/library_facets.dart`；持久化 `lib/features/library/domain/library_view.dart`。
- 分类维度：`LibraryCategoryKind {genres, decades, artists, sources, languages, formats}`（`lib/features/library/domain/library_category.dart`）；卡片 `library_category_view.dart`；树 `library_category_tree.dart`；下钻 `library_pane.dart` 的 `_selectCategoryValue`。
- 专辑：`AlbumSummary`（`lib/domain/models/album_summary.dart`）不带类型；SQL 路径 `app_database.dart::albumSummaries()`（`GROUP BY album, artist, source_id`，已剔除 live）；Dart 路径 `library_album.dart::libraryAlbumsOf`，映射在 `library_storage_io.dart::albumSummaries()`。
- 专辑墙 `library_albums_view.dart`：`LayoutBuilder` + `GridView.builder`，卡片 `_AlbumCard`；页头 `library_header.dart` 已有「在线搜索」按钮可作样式参照；页头编排在 `library_pane.dart`。
- 内置音源实例 id 等于 type，新建实例为 `<type>-<n>`（`sourceTypeOfId`）。`personal` 之外的类型集合固定，见 `content_kind.dart`。
- l10n 四份：`lib/l10n/app_en / app_zh / app_zh_CN / app_zh_TW.arb`；已有 `contentKindPodcast`、`contentKindAudiobook`、`libraryTrackCount`。

## 改动

### 1. 分类器拆成四类

`lib/domain/models/content_kind.dart`

```dart
enum ContentKind {
  music,
  podcast,
  audiobook,
  radio;

  bool get isSpokenWord => this == podcast || this == audiobook;
}

ContentKind contentKindOfSource({String? sourceId, bool isLiveStream = false}) {
  if (isLiveStream) return ContentKind.radio;
  if (isPodcastSource(sourceId)) return ContentKind.podcast;
  if (isAudiobookSource(sourceId)) return ContentKind.audiobook;
  return ContentKind.music;
}

ContentKind contentKindOf(Song song) => contentKindOfSource(
  sourceId: song.sourceId,
  isLiveStream: song.isLiveStream,
);
```

`contentKindOfSource` 让 facets 与 SQL 侧能只凭 `source_id + isLiveStream` 分类，避免在数据层构造 `Song`。

调用点同步：

- `lib/shared/ui/content_row.dart`：`rowShapeOf` 用 `ContentKind.podcast || ContentKind.audiobook => RowShape.spokenWord`。
- `lib/shared/ui/content_kind_mark.dart`：`contentKindLabelOf` 改为四值 switch（music/radio → `null`），`contentKindIconOf` 用 `kind.isSpokenWord`。

### 2. `LibraryFilter.kinds`

`lib/domain/models/library_filter.dart`

- 新增 `final Set<ContentKind> kinds;`，默认 `const {}`，import `content_kind.dart`。
- `isEmpty`、`activeGroups`、`copyWith`、`==`、`hashCode` 各加一项。

`lib/features/library/domain/library_view.dart`

- `toJson`：`'kinds': [for (final kind in filter.kinds) kind.name]`。
- `fromJson`：按 `ContentKind.values.asNameMap()` 解析，未知名丢弃。

`lib/data/services/database/library_filter_sql.dart`

- `where(...)` 的 clause 列表在 `search(query)` 之后插入 `kind(filter.kinds)`。
- 新增：

```dart
static const String _live = "json_extract(songs.json, '\$.isLiveStream') = 1";
static const String _notLive =
    "COALESCE(json_extract(songs.json, '\$.isLiveStream'), 0) != 1";
static const List<String> _podcastTypes = [
  'podcast_rss', 'podcast_catalog', 'podcast_apple',
];
static const List<String> _audiobookTypes = ['librivox', 'audiobookshelf'];

static ({String sql, List<Object?> args})? kind(Set<ContentKind> kinds) {
  if (kinds.isEmpty) return null;
  final spoken = '($_notLive AND (${[
    for (final type in [..._podcastTypes, ..._audiobookTypes]) _sourceOf(type),
  ].join(' OR ')}))';
  final conditions = <String>[
    for (final kind in kinds)
      switch (kind) {
        ContentKind.radio => _live,
        ContentKind.music => '($_notLive AND NOT ($spoken))',
        ContentKind.podcast =>
          '($_notLive AND (${[for (final type in _podcastTypes) _sourceOf(type)].join(' OR ')}))',
        ContentKind.audiobook =>
          '($_notLive AND (${[for (final type in _audiobookTypes) _sourceOf(type)].join(' OR ')}))',
      },
  ];
  return (sql: '(${conditions.join(' OR ')})', args: const []);
}

/// 内置实例 id 等于 type，新建实例是 `<type>-<n>`。GLOB 里 `_` 是字面量，
/// 比 LIKE 更准，不必转义。
static String _sourceOf(String type) =>
    "(source_id = '$type' OR source_id GLOB '$type-[0-9]*')";
```

语义与 `contentKindOf` 一致：live 优先归电台；播客 / 有声书也排除 live。

### 3. facets 的 kinds 计数

`lib/domain/models/library_facets.dart`

- 新增 `final Map<ContentKind, int> kinds;`，默认 `const {}`，import `content_kind.dart`。

`lib/data/services/database/library_facets_query.dart`

- `_FacetGroup` 末尾加 `kinds`。
- `clauses` 加 `_FacetGroup.kinds: LibraryFilterSql.kind(filter.kinds)`。
- `columns` 基础列改为 8 个，在 `source` 后插入 `"json_extract(songs.json, '\$.isLiveStream') AS live"`；组标志位下标从 `7 + index` 改为 `8 + index`。
- 循环内新增 `keepsKinds = keepsAll || failedAt == _FacetGroup.kinds.index`，命中时：
  `final kind = contentKindOfSource(sourceId: row.columnAt(1) as String?, isLiveStream: (row.columnAt(2) as int?) == 1);`
  然后 `kinds[kind] = (kinds[kind] ?? 0) + 1;`
- 返回值加入 `kinds`，`facets()` 透传。

（保持现有「每组不计自身选择」的口径：失败两组即跳过，因此 kinds 的计数天然是不带 kinds 选择的。）

### 4. 标签、面板、chip

`lib/features/library/presentation/library_filter_labels.dart`

```dart
String filterKindLabel(BuildContext context, ContentKind kind) => switch (kind) {
  ContentKind.music => context.loc.contentKindMusic,
  ContentKind.podcast => context.loc.contentKindPodcast,
  ContentKind.audiobook => context.loc.contentKindAudiobook,
  ContentKind.radio => context.loc.contentKindRadio,
};
```

`library_filter_panel.dart`

- 在状态组之前加「类型」组：`if (facets.kinds.values.any((count) => count > 0))`；四个 `FilterChip`，标签 `'${filterKindLabel(...)} · ${count}'`，仅列出计数 > 0 的类型；选中态读 `filter.kinds.contains(kind)`，点击用 `_toggled(filter.kinds, kind)`。

`library_filter_chips.dart`

- 状态 chip 之后加 `for (final kind in filter.kinds)` 的可删除 chip，标签 `filterKindLabel`，删除时 `filter.copyWith(kinds: {...filter.kinds}..remove(kind))`。

### 5. 第 7 个分类维度

`lib/features/library/domain/library_category.dart`

- 追加 `kinds`（放末尾，避免改动既有顺序语义）：`enum LibraryCategoryKind { genres, decades, artists, sources, languages, formats, kinds }`。

`library_category_view.dart`

- `_entries`：
  ```dart
  case LibraryCategoryKind.kinds:
    for (final kind in ContentKind.values) {
      final count = facets.kinds[kind] ?? 0;
      if (count == 0) continue;
      add(kind, filterKindLabel(context, kind), count);
    }
  ```
- `_valuesOfSong`：`LibraryCategoryKind.kinds => [contentKindOf(song)]`。
- `_kindLabel`：`kinds => context.loc.libraryFilterKinds`。
- `_kindIcon`：`kinds => Icons.segments_rounded`。

`library_category_tree.dart`

- `_valuesOf` 加 kinds 分支（同卡片，最多 6 个，按 `ContentKind.values` 顺序）。
- `_isActive`：`kinds => filter.kinds.contains(value)`。
- `_labelOf` / `_iconOf` 同上。

`library_pane.dart`

- `_selectCategoryValue` 加 `LibraryCategoryKind.kinds => filter.copyWith(kinds: {value as ContentKind})`。

### 6. `AlbumSummary.kind` 与两条归并路径

`lib/domain/models/album_summary.dart`

- 新增 `final ContentKind kind;`，默认 `ContentKind.music`，import `content_kind.dart`。

`lib/features/library/domain/library_album.dart`

- `LibraryAlbum` 新增 `final ContentKind kind;`（默认 `music`）。
- `_albumOf` 设 `kind: contentKindOf(ordered.first)`。

`lib/features/library/data/impl/library_storage_io.dart`

- `albumSummaries()`（Dart 路径）构造 `AlbumSummary` 时传 `kind: album.kind`。

`lib/data/services/database/app_database.dart`

- `albumSummaries()`：每行用 `contentKindOfSource(sourceId: row['sourceId'] as String?)` 得 `kind`；合并时 `kind: existing?.kind ?? kind`，import `content_kind.dart`。
- `GROUP BY` 与 live 剔除保持原样。

`library_pane.dart::_albumOf(AlbumSummary, List<Song>)`

- 透传 `kind: summary.kind`，打开专辑后的页头不丢类型。

### 7. 专辑墙分节

`lib/features/library/presentation/library_albums_view.dart`

- 把 `GridView.builder` 换成 `CustomScrollView`（仍用外部 `controller`），在 `LayoutBuilder` 内构建 slivers。
- 分桶顺序 `[music, podcast, audiobook]`；忽略 `radio`（正常不会出现）。
- `final sections = buckets.where((b) => b.albums.isNotEmpty).length;`
- `final showHeaders = sections >= 2;`
- 每个非空节：`showHeaders` 时先 `SliverToBoxAdapter` 节头，文本 `'${filterKindLabel(context, kind)} · ${albums.length}'`，左右 `pageGutter`，样式 `labelMedium`；再 `SliverPadding` + `SliverGrid`（沿用现有 `SliverGridDelegateWithFixedCrossAxisCount`、`cell + caption`、间距）。
- 底部 `SliverPadding` 补 `space8`。
- `_AlbumCard` 增 `kind`：
  - 标题行改 `Row [Flexible(TranslatedText), if (kind.isSpokenWord) _KindBadge(kind)]`；
  - 计数按类型：`music → libraryTrackCount`、`podcast → libraryEpisodeCount`、`audiobook → libraryChapterCount`；
  - `_KindBadge`：`MetaBadge(icon: Icons.record_voice_over_rounded, tooltip: filterKindLabel(context, kind), tone: FactTone.secondary, size: 12)`，自带 `space4` 左距。
- 新增 import：`content_kind.dart`、`library_filter_labels.dart`、`meta_badge.dart`、`track_fact.dart`。

### 8. 页头电台入口

`lib/features/library/presentation/library_header.dart`

- 新增 `final bool radioActive; final VoidCallback? onRadio;`。
- 在「在线搜索」之前渲染：
  ```dart
  if (onRadio != null) ...[
    OutlinedButton.icon(
      key: const ValueKey('library-radio'),
      onPressed: onRadio,
      style: OutlinedButton.styleFrom(...)  // 与在线搜索同尺寸；radioActive 时主色边框与浅底
      icon: Icon(
        radioActive ? Icons.radio_rounded : Icons.podcasts_rounded,
        size: CompactTokens.icon16,
      ),
      label: Text(context.loc.contentKindRadio),
    ),
    const SizedBox(width: CompactTokens.space8),
  ]
  ```

`library_pane.dart`

- `final radioActive = library.filter.kinds.contains(ContentKind.radio);`
- `final hasRadio = library.songs.any((song) => song.isLiveStream);`
- 页头传 `radioActive: radioActive`，`onRadio: (radioActive || hasRadio) ? _toggleRadio : null`。
- 新增方法：
  ```dart
  void _toggleRadio() {
    final filter = ref.read(libraryControllerProvider).requireValue.filter;
    const radio = ContentKind.radio;
    final next = filter.kinds.contains(radio)
        ? filter.copyWith(kinds: {...filter.kinds}..remove(radio))
        : filter.copyWith(kinds: {radio});
    setState(() => _view = LibraryViewMode.songs);
    ref.read(libraryControllerProvider.notifier).setFilter(next);
  }
  ```
- 入口不新增导航项；移动端底栏不变。

### 9. 文案（四份 ARB）

新增并跑 `flutter gen-l10n`：

| 键 | en | zh / zh_CN | zh_TW |
| --- | --- | --- | --- |
| `libraryFilterKinds` | Kind | 类型 | 類型 |
| `contentKindMusic` | Music | 音乐 | 音樂 |
| `contentKindRadio` | Radio | 电台 | 電台 |
| `libraryEpisodeCount` | `{count, plural, =1{1 episode} other{{count} episodes}}` | `{count} 集` | `{count} 集` |
| `libraryChapterCount` | `{count, plural, =1{1 chapter} other{{count} chapters}}` | `{count} 章` | `{count} 章` |

`libraryEpisodeCount` / `libraryChapterCount` 的 `@` 元数据与 `libraryTrackCount` 一致（`count`：`int` + `decimalPattern`）。页头按钮复用 `contentKindRadio`，不另立 `libraryRadio`。

### 10. 测试

- `test/domain/content_kind_test.dart`：`contentKindOf` 断言改为 podcast / audiobook；新增 `contentKindOfSource`（live 优先、实例 id、空 source）。
- `test/domain/library_album_test.dart`：第 198–211 行的 `spokenWord` 断言改为 podcast / audiobook；新增专辑 `kind` 断言。
- `test/app/library_filter_test.dart`：facets 加 `kinds: {podcast: 2}`；断言面板出现「类型」组与「播客 · 2」，点击后 `filter.kinds == {podcast}`；chip 删除后为空。
- `test/app/library_category_test.dart`：`facets.kinds: {podcast: 2}`，`LibraryCategoryKind.kinds` 卡片显示「播客」，点击回传 `ContentKind.podcast`。
- 新增 `test/app/library_header_radio_test.dart`：`onRadio == null` 不渲染；非空时按钮出现、文案「电台」；点击触发回调。
- `test/app/library_albums_test.dart`：仅音乐一节时无节头；音乐 + 播客两节时两个节头；节目卡写「集」、书卡写「章」、音乐卡写「首」；语音卡有类型徽标。
- `test/services/library_database_test.dart`：
  - 播下音乐 / 播客 / 有声书 / 电台四行，`facets.kinds` 计数各 1；
  - `LibraryFilter(kinds: {ContentKind.podcast})` 只回播客行；
  - `albumSummaries()` 给播客、有声书组写对 `kind`，电台不出现。
- 若 `LibraryView` 的 JSON 往返已有测试，补 `kinds` 断言；没有则不新开文件。

### 11. 文档

- `docs/library-browse.md`：分类维度从 6 个改为 7 个（「类型」）；补页头电台入口与「同一条筛选」的说明；补专辑墙分节规则（三节、节头条件、集/章/首、电台不入墙）。
- `.trae/specs/library-content-kinds/spec.md` 第 45 行的旧枚举改为四值，并注明浏览层见本规格。

## 明确不做

- 不新增一级导航、不改移动端底栏。
- 不改 `Song` 模型、不改行形态、不改 `RowShape`。
- 不做电台独立页、不在专辑墙给电台留位置、不改页头专辑计数口径。
- 不按 `kinds` 过滤专辑墙（与现有流派筛选行为一致：专辑墙是整表分组）。
- 不重构 `library_pane.dart` 的缓存逻辑。

## 验收

1. `flutter gen-l10n` 产物一并提交。
2. `/opt/flutter/bin/flutter analyze` → `No issues found`。
3. `flutter test` 全绿（排除 `music_source_e2e_live_test.dart`、`music_source_live_test.dart` 两个网络 e2e）。
4. 手工抽查（Linux 桌面）：
   - 页头出现「电台」；点击后列表只剩台站，chip 出现「电台」，再点后电台移除且其他筛选组保留；
   - 分类视图第 7 个 tab「类型」有 4 张卡（无数据的类型不显示），点击下钻到歌曲列表；
   - 左侧树「类型」组可展开并高亮；
   - 筛选面板「类型」组计数正确；
   - 专辑墙：只有音乐时无节头；音乐 + 播客时出现「音乐 · n」「播客 · m」；节目卡「集」、书卡「章」；电台不在墙内、页头专辑数不变。
5. 提交信息建议 `feat(library): 内容类型成为浏览维度并加电台入口`；不 push。

## 需要批准

请确认以上口径后执行。特别确认两点：

- 页头按钮复用 `contentKindRadio` 文案，不新增 `libraryRadio`。
- 专辑墙不按 `kinds` 筛选（只分节），与现有流派筛选行为一致。
