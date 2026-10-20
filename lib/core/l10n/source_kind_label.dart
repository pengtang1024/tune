import 'package:tune/domain/models/music_source.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The text that names the kind of a source.
///
/// The kind belongs to the source and not to the catalogue entry of one
/// source, so every source of the same kind is named the same way in every
/// language, and the text lives in one place.
extension MusicSourceKindLabel on MusicSourceKind {
  String label(AppLocalizations strings) {
    return switch (this) {
      MusicSourceKind.localDirectory => strings.sourceKindLocal,
      MusicSourceKind.openCatalog => strings.sourceKindOpenCatalog,
      MusicSourceKind.openApi => strings.sourceKindOpenApi,
      MusicSourceKind.plugin => strings.sourceKindPlugin,
    };
  }
}
