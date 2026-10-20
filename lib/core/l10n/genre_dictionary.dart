import 'package:tune/l10n/app_localizations.dart';

/// The genres the app knows by name.
///
/// A genre is metadata written by the source of a track, so it arrives in
/// whatever language that source speaks. The genres the catalogues of the
/// app publish have a name in every language, so they are translated; a
/// genre nobody knows keeps the words of its source.
enum Genre {
  rock,
  pop,
  jazz,
  classical,
  electronic,
  hipHop,
  blues,
  country,
  folk,
  metal,
  punk,
  reggae,
  latin,
  dance,
  alternative,
  indie,
  ambient,
  house,
  funk,
  gospel,
  world,
  newAge,
  soundtrack,
  opera,
  experimental,
}

/// The spellings the catalogues do not write themselves.
///
/// Every language of the app writes a name for a genre, and that name is a
/// spelling of that genre too, so the code only holds the spellings that
/// come from the sources.
const Map<Genre, List<String>> _spellings = {
  Genre.rock: ['rock & roll'],
  Genre.electronic: ['electronica'],
  Genre.hipHop: ['hip hop', 'hiphop', 'rap', 'hip-hop/rap', 'hip hop/rap'],
  Genre.metal: ['heavy metal'],
  Genre.punk: ['punk rock'],
  Genre.alternative: ['alternative rock', 'alt rock', 'alt'],
  Genre.indie: ['independent'],
  Genre.ambient: ['drone'],
  Genre.house: ['deep house'],
  Genre.dance: ['edm', 'electronic dance'],
  Genre.world: ['world'],
  Genre.newAge: ['newage'],
  Genre.soundtrack: ['ost', 'original soundtrack', 'score', 'film score'],
  Genre.experimental: ['avant-garde', 'avant garde'],
};

/// The name of a genre in one language.
String genreName(Genre genre, AppLocalizations strings) => switch (genre) {
  Genre.rock => strings.genreRock,
  Genre.pop => strings.genrePop,
  Genre.jazz => strings.genreJazz,
  Genre.classical => strings.genreClassical,
  Genre.electronic => strings.genreElectronic,
  Genre.hipHop => strings.genreHipHop,
  Genre.blues => strings.genreBlues,
  Genre.country => strings.genreCountry,
  Genre.folk => strings.genreFolk,
  Genre.metal => strings.genreMetal,
  Genre.punk => strings.genrePunk,
  Genre.reggae => strings.genreReggae,
  Genre.latin => strings.genreLatin,
  Genre.dance => strings.genreDance,
  Genre.alternative => strings.genreAlternative,
  Genre.indie => strings.genreIndie,
  Genre.ambient => strings.genreAmbient,
  Genre.house => strings.genreHouse,
  Genre.funk => strings.genreFunk,
  Genre.gospel => strings.genreGospel,
  Genre.world => strings.genreWorld,
  Genre.newAge => strings.genreNewAge,
  Genre.soundtrack => strings.genreSoundtrack,
  Genre.opera => strings.genreOpera,
  Genre.experimental => strings.genreExperimental,
};

/// The genre a tag names, or null when nobody knows it.
///
/// The tag is read the way a source writes it: the case and the spaces do
/// not matter, the word for music at the end does not matter either.
Genre? genreOf(String tag) {
  final folded = _fold(tag);
  final known = _known[folded];
  if (known != null) return known;

  for (final word in _musicWords) {
    if (!folded.endsWith(word)) continue;
    final stem = folded.substring(0, folded.length - word.length).trim();
    final stripped = _known[stem];
    if (stripped != null) return stripped;
  }

  return null;
}

/// Every spelling of every genre.
final Map<String, Genre> _known = _buildKnown();

/// The words a source puts at the end of a genre.
final List<String> _musicWords = _buildMusicWords();

Map<String, Genre> _buildKnown() {
  final known = <String, Genre>{};

  for (final entry in _spellings.entries) {
    for (final spelling in entry.value) {
      known[_fold(spelling)] = entry.key;
    }
  }

  // The name a language writes for a genre is a spelling of that genre, so
  // a source that writes in any language of the app is understood.
  for (final locale in AppLocalizations.supportedLocales) {
    final strings = lookupAppLocalizations(locale);
    for (final genre in Genre.values) {
      known[_fold(genreName(genre, strings))] = genre;
    }
  }

  return known;
}

List<String> _buildMusicWords() {
  final words = <String>{};
  for (final locale in AppLocalizations.supportedLocales) {
    final strings = lookupAppLocalizations(locale);
    words.add(_fold(strings.genreMusicWord));
    words.add(_fold(strings.genreMusicWordShort));
  }
  return words.toList();
}

/// The form of a tag the dictionary is written in.
String _fold(String text) {
  return text.trim().toLowerCase().replaceAll(_spaces, ' ');
}

final RegExp _spaces = RegExp(r'\s+');
