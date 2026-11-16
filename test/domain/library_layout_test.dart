import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/domain/library_layout.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';

void main() {
  test('music opens on the album wall and may switch to any of its views', () {
    final layout = libraryLayoutFor(ContentKind.music);

    expect(layout.primary, LibraryViewMode.albums);
    expect(layout.groupingLabel, LibraryGroupingLabel.album);
    for (final view in LibraryViewMode.values) {
      expect(layout.allows(view), isTrue, reason: '$view should be allowed');
    }
  });

  test('podcast stops at two levels: shows, then episodes', () {
    final layout = libraryLayoutFor(ContentKind.podcast);

    expect(layout.primary, LibraryViewMode.albums);
    expect(layout.groupingLabel, LibraryGroupingLabel.show);
    expect(layout.views, [LibraryViewMode.albums, LibraryViewMode.songs]);
    expect(layout.allows(LibraryViewMode.categories), isFalse);
  });

  test('audiobook groups by book and keeps categories to find one', () {
    final layout = libraryLayoutFor(ContentKind.audiobook);

    expect(layout.primary, LibraryViewMode.albums);
    expect(layout.groupingLabel, LibraryGroupingLabel.book);
    expect(layout.allows(LibraryViewMode.categories), isTrue);
    expect(layout.allows(LibraryViewMode.collections), isFalse);
  });

  test('radio and sound effects have no wall to open', () {
    final radio = libraryLayoutFor(ContentKind.radio);
    final effect = libraryLayoutFor(ContentKind.soundEffect);

    expect(radio.primary, LibraryViewMode.songs);
    expect(radio.groupingLabel, isNull);
    expect(radio.allows(LibraryViewMode.albums), isFalse);
    expect(radio.allows(LibraryViewMode.collections), isTrue);

    expect(effect.primary, LibraryViewMode.songs);
    expect(effect.groupingLabel, isNull);
    expect(effect.views, [LibraryViewMode.songs]);
  });

  test('a mixed selection reads like music, the widest layout', () {
    expect(
      libraryLayoutForKinds({ContentKind.podcast, ContentKind.music}).primary,
      LibraryViewMode.albums,
    );
    expect(
      libraryLayoutForKinds({ContentKind.podcast, ContentKind.radio})
          .groupingLabel,
      LibraryGroupingLabel.album,
    );
    expect(
      libraryLayoutForKinds(const <ContentKind>{}).primary,
      LibraryViewMode.albums,
    );
  });

  test('a single selection uses its own layout', () {
    expect(
      libraryLayoutForKinds({ContentKind.radio}).primary,
      LibraryViewMode.songs,
    );
  });
}
