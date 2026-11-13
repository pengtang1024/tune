import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/content_kind_mark.dart';
import 'package:tune/shared/ui/content_row.dart';
import 'package:tune/shared/ui/icon_glyph.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// A track row takes one of three shapes: a song, a spoken track or a
/// station. The shape decides the line under the title and the two columns
/// of the library table, and the kind decides the mark beside the title.
void main() {
  const song = Song(
    id: 1,
    title: '夜曲',
    artist: '某歌手',
    album: '夜曲专辑',
    uri: '/music/night.flac',
    sourceId: 'local',
  );
  const episode = Song(
    id: 2,
    title: '第二集',
    artist: '主播甲',
    album: '慢慢说',
    uri: 'tune://podcast_rss/2',
    sourceId: 'podcast_rss-2',
  );
  const audiobook = Song(
    id: 3,
    title: '第一章',
    artist: '朗读者',
    album: '傲慢与偏见',
    uri: 'tune://librivox/1',
    sourceId: 'librivox',
  );
  const station = Song(
    id: 4,
    title: 'Jazz FM',
    uri: 'tune://radio/one',
    sourceId: 'radio',
    isLiveStream: true,
    onAirArtist: 'Miles Davis',
    onAirTitle: 'So What',
  );
  const quietStation = Song(
    id: 5,
    title: 'Quiet FM',
    uri: 'tune://radio/two',
    sourceId: 'radio',
    isLiveStream: true,
  );
  const showWithoutVoice = Song(
    id: 6,
    title: '序',
    album: '安静的书',
    uri: 'tune://librivox/2',
    sourceId: 'librivox',
  );

  Widget app(Widget home) {
    return MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  /// Reads one value that needs the localisations of the shell.
  Future<T> read<T>(
    WidgetTester tester,
    T Function(BuildContext context) reader,
  ) async {
    late T value;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            value = reader(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return value;
  }

  test('the kind picks the shape of the row', () {
    expect(rowShapeOf(song), RowShape.track);
    expect(rowShapeOf(episode), RowShape.spokenWord);
    expect(rowShapeOf(station), RowShape.radio);
  });

  testWidgets('a song reads as its artist and its album', (tester) async {
    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, song),
    );

    expect(subtitle, '某歌手 · 夜曲专辑');
  });

  testWidgets('a spoken track names the show before the voice', (tester) async {
    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, episode),
    );

    expect(subtitle, '慢慢说 · 主播甲');
  });

  testWidgets('a show that is also the author says it once', (tester) async {
    const episodeOfOneName = Song(
      id: 7,
      title: '第二集',
      artist: '慢慢说',
      album: '慢慢说',
      uri: 'tune://podcast_rss/7',
      sourceId: 'podcast_rss',
    );

    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, episodeOfOneName),
    );

    expect(subtitle, '慢慢说');
  });

  testWidgets('a station writes what is airing', (tester) async {
    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, station),
    );

    expect(subtitle, '正在播放 · Miles Davis - So What');
  });

  testWidgets('a station without on-air words says it is live', (tester) async {
    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, quietStation),
    );

    expect(subtitle, '直播中');
  });

  testWidgets('a recording of a station says it is a recording', (
    tester,
  ) async {
    const recording = Song(
      id: 9,
      title: 'Old Time Radio',
      uri: 'tune://internet_archive/old-time-radio/1',
      sourceId: 'radio_recordings',
    );

    expect(rowShapeOf(recording), RowShape.radio);
    final subtitle = await read(
      tester,
      (context) => rowSubtitleOf(context, recording),
    );

    expect(subtitle, '录音');
  });

  testWidgets('a station writes nothing into the artist and album columns', (
    tester,
  ) async {
    final columns = await read(
      tester,
      (context) => rowColumnsOf(context, station),
    );

    expect(columns.artist, isEmpty);
    expect(columns.album, isEmpty);
  });

  testWidgets('a spoken track leaves a missing voice empty', (tester) async {
    final columns = await read(
      tester,
      (context) => rowColumnsOf(context, showWithoutVoice),
    );

    expect(columns.artist, isEmpty);
    expect(columns.album, '安静的书');
  });

  testWidgets('a song without an artist says the artist is unknown', (
    tester,
  ) async {
    final columns = await read(
      tester,
      (context) => rowColumnsOf(context, const Song(id: 8)),
    );

    expect(columns.artist, '未知艺术家');
    expect(columns.album, isEmpty);
  });

  testWidgets('a podcast wears the name of its kind', (tester) async {
    await tester.pumpWidget(app(const ContentKindMark(song: episode)));

    expect(find.byTooltip('播客'), findsOneWidget);
    expect(_mark(Icons.record_voice_over_rounded), findsOneWidget);
  });

  testWidgets('an audiobook wears the name of its kind', (tester) async {
    await tester.pumpWidget(app(const ContentKindMark(song: audiobook)));

    expect(find.byTooltip('有声书'), findsOneWidget);
    expect(_mark(Icons.record_voice_over_rounded), findsOneWidget);
  });

  testWidgets('a song and a station wear no kind mark', (tester) async {
    await tester.pumpWidget(app(const ContentKindMark(song: song)));
    expect(find.byType(IconGlyph), findsNothing);

    await tester.pumpWidget(app(const ContentKindMark(song: station)));
    expect(find.byType(IconGlyph), findsNothing);
  });

  testWidgets('the kind is a fact of a spoken track', (tester) async {
    final facts = await read(
      tester,
      (context) => trackFactsOf(context, episode),
    );
    final kind = facts.firstWhere((fact) => fact.label == '类型');

    expect(kind.value, '播客');
    expect(kind.sentence, '类型 · 播客');
  });

  testWidgets('the kind of a song is not written down', (tester) async {
    final facts = await read(
      tester,
      (context) => trackFactsOf(context, song),
    );

    expect(facts.where((fact) => fact.label == '类型'), isEmpty);
  });
}

Finder _mark(IconData icon) {
  return find.byWidgetPredicate(
    (widget) => widget is IconGlyph && widget.icon == icon,
  );
}
