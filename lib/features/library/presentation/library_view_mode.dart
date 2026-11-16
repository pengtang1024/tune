/// What the library page is showing.
enum LibraryViewMode {
  /// The dense table of every track.
  songs,

  /// Two lists side by side: the groups on the left, the tracks of the
  /// selected group on the right. The left list stays visible while a group

  /// The covers of the albums the tracks belong to.
  albums,

  /// Two tracks per line: the wall of the library.
  columns,

  /// The categories of the library: genres, decades, artists and sources.
  categories,

  /// The collections the tracks came in, one card per instance.
  ///
  /// A collection is opened, not filtered: it leads to its items, and an item
  /// leads to its tracks. A shelf of a thousand uploads therefore stays one
  /// card instead of a thousand rows in the table.
  collections,
}
