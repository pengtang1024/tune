import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/discovery/domain/taste_profile.dart';

/// A profile built from counts the database grouped normalizes the same way
/// as one built from the whole library.
void main() {
  test('weights are normalized to the strongest key', () {
    final profile = TasteProfile.fromWeights(
      artists: {'rock': 2, 'jazz': 1},
      genres: {'jazz': 4},
    );

    expect(profile.artists['rock'], 1.0);
    expect(profile.artists['jazz'], 0.5);
    expect(profile.genres['jazz'], 1.0);
  });

  test('an empty aggregate gives an empty profile', () {
    final profile = TasteProfile.fromWeights();

    expect(profile.artists, isEmpty);
    expect(profile.genres, isEmpty);
    expect(profile.favoriteCount, 0);
  });
}
