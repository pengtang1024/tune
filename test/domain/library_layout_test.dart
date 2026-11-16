import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/domain/library_layout.dart';

/// The list has one first level or none, and that decision belongs here: the
/// page has no view switch, so nothing else may change the shape of the list.
void main() {
  group('a page of one kind', () {
    test('music is read by album', () {
      final layout = libraryLayoutFor(ContentKind.music);

      expect(layout.grouped, isTrue);
      expect(layout.groupingLabel, LibraryGroupingLabel.album);
    });

    test('a podcast is read by show', () {
      final layout = libraryLayoutFor(ContentKind.podcast);

      expect(layout.grouped, isTrue);
      expect(layout.groupingLabel, LibraryGroupingLabel.show);
    });

    test('an audiobook is read by book', () {
      final layout = libraryLayoutFor(ContentKind.audiobook);

      expect(layout.grouped, isTrue);
      expect(layout.groupingLabel, LibraryGroupingLabel.book);
    });

    test('a single kind decides by itself', () {
      final layout = libraryLayoutForKinds({ContentKind.music});

      expect(layout.grouped, isTrue);
      expect(layout.groupingLabel, LibraryGroupingLabel.album);
    });
  });

  group('a flat list', () {
    test('a station is a stream, not a group of tracks', () {
      final layout = libraryLayoutFor(ContentKind.radio);

      expect(layout.grouped, isFalse);
      expect(layout.groupingLabel, isNull);
    });

    test('a sound effect is one short take', () {
      final layout = libraryLayoutFor(ContentKind.soundEffect);

      expect(layout.grouped, isFalse);
      expect(layout.groupingLabel, isNull);
    });

    test('no kind is the song table', () {
      final layout = libraryLayoutForKinds(const {});

      expect(layout.grouped, isFalse);
      expect(layout.groupingLabel, isNull);
    });

    test('several kinds have no single noun to put on a row', () {
      final layout = libraryLayoutForKinds(const {
        ContentKind.music,
        ContentKind.podcast,
      });

      expect(layout.grouped, isFalse);
      expect(layout.groupingLabel, isNull);
    });
  });
}
