import 'package:tune/core/l10n/genre_dictionary.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The name of a genre in the language of the interface.
///
/// A genre the app does not know keeps the words of its source: a name
/// nobody translated is understood better than a wrong translation.
String genreLabel(String genre, AppLocalizations strings) {
  final trimmed = genre.trim();
  if (trimmed.isEmpty) return trimmed;

  final known = genreOf(trimmed);
  if (known != null) return genreName(known, strings);

  final parts = trimmed.split(_separator);
  if (parts.length < 2) return trimmed;

  final labels = <String>[];
  var translated = false;
  for (final part in parts) {
    final partGenre = genreOf(part);
    if (partGenre == null) {
      labels.add(part.trim());
      continue;
    }
    translated = true;
    labels.add(genreName(partGenre, strings));
  }

  // Nothing was known, so the row stays the way the source wrote it.
  if (!translated) return trimmed;
  return labels.join(' / ');
}

/// The names of several genres in the language of the interface.
String genresLabel(Iterable<String> genres, AppLocalizations strings) {
  return genres.map((genre) => genreLabel(genre, strings)).join(' / ');
}

/// The signs a source puts between several genres.
final RegExp _separator = RegExp(r'\s*[/,;、]\s*');
