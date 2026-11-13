import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The way a store is asked for its music.
///
/// The two stores read the same four things — the tracks themselves, the
/// records they belong to, the artists who made them, and the playlists that
/// collect them — so the names and the setting live here instead of in each
/// adapter, where they drifted apart.
enum StoreReadMode {
  songs('songs'),
  albums('albums'),
  artists('artists'),
  playlists('playlists');

  const StoreReadMode(this.value);

  /// The word the setting carries: it is saved with the source, so it never
  /// changes.
  final String value;

  /// The mode a configuration asks for, from the ones a store offers.
  ///
  /// A name the store does not read falls back to the first thing it offers,
  /// which is the plain list of tracks.
  static StoreReadMode of(String? raw, List<StoreReadMode> offers) {
    final wanted = raw?.trim() ?? '';
    for (final mode in offers) {
      if (mode.value == wanted) return mode;
    }
    return offers.first;
  }

  /// The name of the mode in the language of the app.
  String label(AppLocalizations strings) {
    return switch (this) {
      StoreReadMode.songs => strings.storeReadModeSongs,
      StoreReadMode.albums => strings.storeReadModeAlbums,
      StoreReadMode.artists => strings.storeReadModeArtists,
      StoreReadMode.playlists => strings.storeReadModePlaylists,
    };
  }

  /// The setting that lets the reader pick one of [offers].
  static MusicSourceField field(List<StoreReadMode> offers) {
    final strings = AppStrings.instance;
    return MusicSourceField(
      'mode',
      strings.storeReadModeField,
      strings.storeReadModeFieldHint,
      choices: [
        for (final mode in offers)
          MusicSourceChoice(mode.value, mode.label(strings)),
      ],
    );
  }
}
