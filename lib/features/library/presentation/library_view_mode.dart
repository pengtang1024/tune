/// What the library page is showing.
enum LibraryViewMode {
  /// The dense table of every track.
  songs,

  /// The covers of the albums the tracks belong to.
  albums,

  /// Two tracks per line: the wall of the library.
  columns,

  /// The categories of the library: genres, decades, artists and sources.
  categories,
}
