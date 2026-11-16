import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/features/library/domain/library_view.dart';

/// The rules about dirty rows are part of the saved view, so a restart does
/// not silently bring a wall of duration-less rows back.
void main() {
  test('a view keeps the dirty-data rules across a restart', () {
    const view = LibraryView(
      filter: LibraryFilter(
        kinds: {ContentKind.music},
        hideMissingDuration: false,
        excludeShortTracks: true,
      ),
    );

    final back = LibraryView.fromJson(view.toJson());

    expect(back.filter.hideMissingDuration, isFalse);
    expect(back.filter.excludeShortTracks, isTrue);
  });

  test('a view written before the rules opens with the defaults', () {
    final back = LibraryView.fromJson({
      'filter': {
        'kinds': ['music'],
      },
    });

    expect(back.filter.hideMissingDuration, isTrue);
    expect(back.filter.excludeShortTracks, isTrue);
  });
}
