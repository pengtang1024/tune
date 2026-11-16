import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';

/// 一类内容有自己的读法。
///
/// 音乐是「专辑 → 曲目」，播客是「节目 → 单集」，有声书是「书 → 章节」，
/// 电台只有一串台，音效是一堆短条目——把它们塞进同一套视图开关，读者要自己
/// 把不属于这一类的东西过滤掉。这个表就是那层判断的唯一出处：分类决定默认
/// 打开哪个视图、允许切换哪几个、以及「专辑」这一档在这类内容里叫什么。
enum LibraryGroupingLabel {
  /// 音乐：专辑。
  album,

  /// 播客：节目。
  show,

  /// 有声书：书。
  book,
}

class LibraryLayout {
  const LibraryLayout({
    required this.primary,
    required this.views,
    this.groupingLabel,
  });

  /// 切到这类内容时打开的视图。
  final LibraryViewMode primary;

  /// 这类内容允许的视图，顺序即开关里的顺序。
  final List<LibraryViewMode> views;

  /// 「专辑」这一档在这类内容里的名字；为空表示这类内容没有分组墙。
  final LibraryGroupingLabel? groupingLabel;

  bool allows(LibraryViewMode view) => views.contains(view);
}

/// 音乐的默认读法：一屏两列——左边专辑，右边这个专辑的曲目。
/// 一列平铺会让一张专辑的十几个乐章各占一行，专辑墙又看不到曲目；
/// 两列同时在场，才既不重复也不丢层级。
const _music = LibraryLayout(
  primary: LibraryViewMode.albums,
  views: [
    LibraryViewMode.songs,
    LibraryViewMode.columns,
    LibraryViewMode.categories,
    LibraryViewMode.albums,
    LibraryViewMode.collections,
  ],
  groupingLabel: LibraryGroupingLabel.album,
);

/// 播客按节目看，节目里是单集，所以只有两级。
const _podcast = LibraryLayout(
  primary: LibraryViewMode.albums,
  views: [
    LibraryViewMode.albums,
    LibraryViewMode.songs,
  ],
  groupingLabel: LibraryGroupingLabel.show,
);

/// 有声书按书看，需要分类来找书，也需要曲目表定位某一章。
const _audiobook = LibraryLayout(
  primary: LibraryViewMode.albums,
  views: [
    LibraryViewMode.albums,
    LibraryViewMode.songs,
    LibraryViewMode.categories,
  ],
  groupingLabel: LibraryGroupingLabel.book,
);

/// 电台没有专辑可言：一串台，加一个按来源分的合集。
const _radio = LibraryLayout(
  primary: LibraryViewMode.songs,
  views: [LibraryViewMode.songs, LibraryViewMode.collections],
);

/// 音效是短的、一次性的：平铺，按名字找。
const _soundEffect = LibraryLayout(
  primary: LibraryViewMode.songs,
  views: [LibraryViewMode.songs],
);

/// 一类内容对应的读法。多个分类同时选中时按最宽的那种算，
/// 因为读者此时看到的是混合列表。
LibraryLayout libraryLayoutFor(ContentKind kind) => switch (kind) {
  ContentKind.music => _music,
  ContentKind.podcast => _podcast,
  ContentKind.audiobook => _audiobook,
  ContentKind.radio => _radio,
  ContentKind.soundEffect => _soundEffect,
};

/// 一组分类的读法：单一分类用自己的；混合时用音乐的（最宽）。
LibraryLayout libraryLayoutForKinds(Set<ContentKind> kinds) =>
    kinds.length == 1 ? libraryLayoutFor(kinds.first) : _music;
