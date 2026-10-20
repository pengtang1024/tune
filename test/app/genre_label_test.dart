import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/l10n/genre_dictionary.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/track_metadata_facts.dart';

/// The name of a genre belongs to the reader, not to the source.
///
/// A source writes the genre in its own language, so the app translates the
/// genres it knows and leaves the rest the way the source wrote them.
void main() {
  final zh = lookupAppLocalizations(const Locale('zh', 'CN'));
  final tw = lookupAppLocalizations(const Locale('zh', 'TW'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('a genre the app knows is named in the language of the interface', () {
    expect(genreLabel('Rock', zh), '摇滚');
    expect(genreLabel('Rock', tw), '搖滾');
    expect(genreLabel('Rock', en), 'Rock');
  });

  test('the way a source spells a genre does not matter', () {
    expect(genreLabel('rock', zh), '摇滚');
    expect(genreLabel('ROCK', zh), '摇滚');
    expect(genreLabel('  Rock  ', zh), '摇滚');
    expect(genreLabel('Rock Music', zh), '摇滚');
    expect(genreLabel('rock & roll', zh), '摇滚');
    expect(genreLabel('Heavy Metal', zh), '金属');
    expect(genreLabel('hip hop', zh), '说唱');
    expect(genreLabel('rap', zh), '说唱');
    expect(genreLabel('Hip-Hop/Rap', zh), '说唱');
  });

  test('a genre written in any language of the app is understood', () {
    expect(genreLabel('摇滚', en), 'Rock');
    expect(genreLabel('搖滾', en), 'Rock');
    expect(genreLabel('摇滚乐', en), 'Rock');
    expect(genreLabel('电子音乐', en), 'Electronic');
    expect(genreLabel('搖滾音樂', en), 'Rock');
  });

  test('a genre nobody knows keeps the words of its source', () {
    expect(genreLabel('Drum & Bass', zh), 'Drum & Bass');
    expect(genreLabel('Drum & Bass', en), 'Drum & Bass');
    expect(genreLabel('蒸汽波', zh), '蒸汽波');
    expect(genreLabel('', zh), '');
  });

  test('several genres keep the order of the source', () {
    expect(genresLabel(['Rock', 'Jazz'], zh), '摇滚 / 爵士');
    expect(genresLabel(['Rock', 'Jazz'], en), 'Rock / Jazz');
    expect(genreLabel('Rock/Jazz', zh), '摇滚 / 爵士');
    expect(genreLabel('Rock, Jazz', zh), '摇滚 / 爵士');
  });

  test('a row of unknown genres stays the way the source wrote it', () {
    expect(genreLabel('AC/DC', zh), 'AC/DC');
  });

  test('an unknown genre among known ones keeps its own words', () {
    expect(genreLabel('Rock / 蒸汽波', zh), '摇滚 / 蒸汽波');
  });

  test('every genre the app knows has a name in every language', () {
    for (final genre in Genre.values) {
      for (final strings in [zh, tw, en]) {
        expect(genreName(genre, strings), isNotEmpty);
      }
    }
  });

  testWidgets('the details sheet names the genre in the language of the reader', (
    tester,
  ) async {
    const song = Song(
      id: 1,
      title: '夜曲',
      artist: '某歌手',
      duration: 245000,
      uri: '/music/night.flac',
      genre: '流行',
    );

    await tester.pumpWidget(app(const Locale('en'), song));
    await tester.pumpAndSettle();

    expect(find.text('Pop'), findsOneWidget);
    expect(find.text('流行'), findsNothing);
  });

  testWidgets('the details sheet keeps a genre nobody knows', (tester) async {
    const song = Song(
      id: 2,
      title: '夜曲',
      artist: '某歌手',
      duration: 245000,
      uri: '/music/night.flac',
      genre: '蒸汽波',
    );

    await tester.pumpWidget(app(const Locale('en'), song));
    await tester.pumpAndSettle();

    expect(find.text('蒸汽波'), findsOneWidget);
  });
}

/// The facts of a track, drawn the way the details sheet draws them.
Widget app(Locale locale, Song song) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Column(
        children: [
          for (final fact in metadataFactsOf(context, song))
            if (fact != null) Text(fact.value),
        ],
      ),
    ),
  );
}
