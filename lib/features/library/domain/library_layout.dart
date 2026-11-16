import 'package:tune/domain/models/content_kind.dart';

/// What one group of the library is called.
///
/// Music groups tracks into albums, a podcast into shows and an audiobook
/// into books. The noun is the only thing the page needs from the kind when
/// it draws the group rows; the count still comes from each group itself.
enum LibraryGroupingLabel {
  /// Music: albums.
  album,

  /// Podcast: shows.
  show,

  /// Audiobook: books.
  book,
}

/// How one class of content is browsed.
///
/// Music, podcasts and audiobooks are read in two levels: a group first, the
/// tracks of that group after. A station never ends and a sound effect is a
/// single short take, so both are one flat list. This class is the single
/// place that decision lives: the page has no view switch, and the toolbar
/// cannot change the shape of the list.
class LibraryLayout {
  const LibraryLayout({required this.grouped, this.groupingLabel});

  /// Whether the list starts with groups that open into their own tracks.
  final bool grouped;

  /// The noun a group of this content carries; null on a flat list.
  final LibraryGroupingLabel? groupingLabel;
}

/// Music: album rows, then the tracks of the album the reader opened.
const _music = LibraryLayout(
  grouped: true,
  groupingLabel: LibraryGroupingLabel.album,
);

/// A podcast is read by show: one row per show, its episodes after.
const _podcast = LibraryLayout(
  grouped: true,
  groupingLabel: LibraryGroupingLabel.show,
);

/// An audiobook is read by book: one row per book, its chapters after.
const _audiobook = LibraryLayout(
  grouped: true,
  groupingLabel: LibraryGroupingLabel.book,
);

/// A station is a stream, not a group of tracks: one flat list of stations.
const _radio = LibraryLayout(grouped: false);

/// A sound effect is one short take and has nothing under it: flat.
const _soundEffect = LibraryLayout(grouped: false);

/// The song table a page shows when nothing names a kind.
const _flat = LibraryLayout(grouped: false);

/// The shape of the list that holds [kind].
LibraryLayout libraryLayoutFor(ContentKind kind) => switch (kind) {
  ContentKind.music => _music,
  ContentKind.podcast => _podcast,
  ContentKind.audiobook => _audiobook,
  ContentKind.radio => _radio,
  ContentKind.soundEffect => _soundEffect,
};

/// The shape of the list that holds [kinds].
///
/// Only a scope that names exactly one kind has a first level: one noun
/// (album, show or book) to put on a row. No scope is the song table, and a
/// scope of several kinds has no single noun — calling an episode a song, or
/// filing a station under an album, would be the kind of row this page is
/// here to remove. Both are one flat table of tracks.
LibraryLayout libraryLayoutForKinds(Set<ContentKind> kinds) {
  if (kinds.length != 1) return _flat;
  return libraryLayoutFor(kinds.first);
}
