import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/store_read_mode.dart';

void main() {
  group('StoreReadMode', () {
    test('a mode the store offers is taken as it is', () {
      expect(
        StoreReadMode.of('albums', const [StoreReadMode.songs, StoreReadMode.albums]),
        StoreReadMode.albums,
      );
    });

    test('a mode the store does not offer falls back to its first one', () {
      // A store that cannot read playlists must not answer with them, even
      // when the setting was written by a store that could.
      expect(
        StoreReadMode.of('playlists', const [StoreReadMode.songs, StoreReadMode.albums]),
        StoreReadMode.songs,
      );
      expect(
        StoreReadMode.of(null, const [StoreReadMode.songs, StoreReadMode.albums]),
        StoreReadMode.songs,
      );
      expect(
        StoreReadMode.of('   ', const [StoreReadMode.artists, StoreReadMode.albums]),
        StoreReadMode.artists,
      );
    });

    test('the setting offers exactly the modes the store reads', () {
      final field = StoreReadMode.field(const [
        StoreReadMode.songs,
        StoreReadMode.albums,
        StoreReadMode.playlists,
      ]);

      expect(field.key, 'mode');
      expect(
        field.choices.map((choice) => choice.value),
        ['songs', 'albums', 'playlists'],
      );
      for (final choice in field.choices) {
        expect(choice.label.trim(), isNotEmpty);
      }
      expect(field.hint.trim(), isNotEmpty);
      expect(AppStrings.instance.storeReadModeField, isNotEmpty);
    });
  });
}
