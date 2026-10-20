import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/library/data/library_storage.dart';

/// The library of an older version wrote the words of that version when a
/// file carried no name. The interface writes the missing name in the
/// language of the app now, so the old words are dropped when the library is
/// read.
void main() {
  test('the words of an older version are dropped', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Night Flight',
      'artist': 'Unknown Artist',
      'album': 'Unknown Album',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['artist'], '');
    expect(cleaned['album'], '');
  });

  test('a name that is really there is kept', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Night Flight',
      'artist': 'Forest Radio',
      'album': 'City Echoes',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['artist'], 'Forest Radio');
    expect(cleaned['album'], 'City Echoes');
  });

  test('the words of an older version that stand for a title are kept', () {
    final cleaned = withoutLegacyNames({
      'id': 1,
      'title': 'Unknown Artist',
      'uri': '/music/a.mp3',
    });

    expect(cleaned['title'], 'Unknown Artist');
  });
}
