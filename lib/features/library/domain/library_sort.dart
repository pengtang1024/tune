import 'package:flutter/foundation.dart';

/// The column the library is ordered by.
enum LibrarySortField { title, addedAt, artist, album, duration }

@immutable
class LibrarySort {
  final LibrarySortField field;
  final bool ascending;

  const LibrarySort({
    this.field = LibrarySortField.title,
    this.ascending = true,
  });

  /// The order a reader who has never sorted anything sees.
  static const LibrarySort title = LibrarySort();

  /// The default of the redesign: the track added last is first.
  static const LibrarySort recent = LibrarySort(
    field: LibrarySortField.addedAt,
    ascending: false,
  );

  LibrarySort flipped() => LibrarySort(field: field, ascending: !ascending);

  /// The order a click on [field] asks for: the same column flips, a new
  /// column takes its natural direction (the added time newest first).
  LibrarySort then(LibrarySortField field) {
    if (field == this.field) return flipped();
    return LibrarySort(
      field: field,
      ascending: field != LibrarySortField.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LibrarySort &&
      other.field == field &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(field, ascending);
}
