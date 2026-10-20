import 'package:tune/l10n/app_localizations.dart';

/// The browse streams a source may pull.
///
/// A browse stream is a list the platform serves by itself: the tracks that
/// were published last, the tracks everybody plays, the tracks the platform
/// picks for this listener. A source that offers one of them needs no
/// keyword: the app does not pick a taste for the reader.
///
/// An instance that names a keyword searches with it instead, and the keyword
/// wins over the stream.
class BrowseMode {
  const BrowseMode._();

  /// The tracks that were published last.
  static const latest = 'latest';

  /// The tracks everybody plays.
  static const charts = 'charts';

  /// The tracks the platform picks for this listener.
  static const daily = 'daily';

  /// The name a browse stream is called in the language of the app.
  ///
  /// A mode the app does not know is written as it is, so a new mode of a
  /// new type never shows an empty name.
  static String labelOf(String mode, AppLocalizations strings) {
    return switch (mode) {
      latest => strings.browseModeLatest,
      charts => strings.browseModeCharts,
      daily => strings.browseModeDaily,
      _ => mode,
    };
  }
}
