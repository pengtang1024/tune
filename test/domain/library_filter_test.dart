import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_filter.dart';

/// The content kind is a scope, not a filter: the library always names one,
/// and the groups the reader picks are counted on their own.
void main() {
  test('the library opens on songs', () {
    expect(LibraryFilter.songs.kinds, {ContentKind.music});
    expect(LibraryFilter.songs.isEmpty, isTrue);
    expect(LibraryFilter.songs.activeGroups, 0);
  });

  test('the content scope does not count as a filter group', () {
    const filter = LibraryFilter(
      kinds: {ContentKind.podcast},
      genres: {'jazz'},
    );

    expect(filter.isEmpty, isFalse);
    expect(filter.activeGroups, 1);
  });

  test('clearing the groups keeps the scope', () {
    const filter = LibraryFilter(
      status: LibraryStatusFilter.liked,
      kinds: {ContentKind.podcast, ContentKind.audiobook},
      genres: {'jazz'},
      decades: {1990},
      sources: {'local'},
    );

    final cleared = filter.withoutGroups();

    expect(cleared.isEmpty, isTrue);
    expect(cleared.kinds, filter.kinds);
    expect(cleared.status, LibraryStatusFilter.all);
    expect(cleared.genres, isEmpty);
    expect(cleared.decades, isEmpty);
    expect(cleared.sources, isEmpty);
  });
}
