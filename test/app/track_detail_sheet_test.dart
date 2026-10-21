import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/track_detail_table.dart';
import 'package:tune/shared/ui/track_meta.dart';

/// The details sheet is a table of properties.
///
/// The names of the facts stand in one column and their values in another
/// one, so the eye can run down the names and find the value it wants. The
/// values keep the face of their kind: a path, a number and an identifier in
/// the machine face, the words of a person in the body face.
void main() {
  const song = Song(
    id: 1,
    title: '夜曲',
    artist: '某歌手',
    album: '夜曲专辑',
    duration: 245000,
    uri: '/music/night.flac',
    year: 2024,
    genre: '流行',
    bitrate: 980,
    sampleRate: 96000,
    trackNumber: 3,
    trackTotal: 12,
    license: 'CC-BY',
    language: 'zh',
    size: 38000000,
    lyrics: '[00:00.00] 歌词',
    description: '一首很长的简介，写了很长很长，长到不该挤进一行里。',
    sourceData: {'id': 'one', 'suffix': 'mp3'},
    dateAdded: 1700000000000,
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

  /// The face a value of the sheet is written in.
  TextStyle styleOf(WidgetTester tester, Finder sheet, String value) {
    final selectable = find.ancestor(
      of: find.descendant(of: sheet, matching: find.text(value)),
      matching: find.byType(SelectableText),
    );

    return tester.widget<SelectableText>(selectable).style ?? const TextStyle();
  }

  /// Opens the details of a track and hands back the tree of the sheet.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(app(const TrackMeta(song: song, index: 0)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();
  }

  testWidgets('the names of the facts stand in one column', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final names = ['格式', '码率', '专辑', '年份'];
    final lefts = <double>{};
    for (final name in names) {
      lefts.add(tester.getTopLeft(find.descendant(of: sheet, matching: find.text(name))).dx);
    }

    expect(lefts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the values of the facts stand in one column', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final values = ['FLAC', '980 kbps', '夜曲专辑', '2024'];
    final lefts = <double>{};
    for (final value in values) {
      lefts.add(
        tester.getTopLeft(find.descendant(of: sheet, matching: find.text(value))).dx,
      );
    }

    expect(lefts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the addresses share the column of the names', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final name = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.text('格式')),
    );
    final path = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.text('文件路径')),
    );

    expect(path.dx, name.dx);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a value a machine wrote keeps the machine face', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    expect(
      styleOf(tester, sheet, 'FLAC').fontFamily,
      CompactTypography.monoFamily,
    );
    expect(
      styleOf(tester, sheet, '夜曲专辑').fontFamily,
      CompactTypography.sansFamily,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long description is a paragraph and not a line', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text(song.description!), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TrackDetailLine),
        matching: find.text(song.description!),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the words of a person are written in the body face', (
    tester,
  ) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    expect(
      styleOf(tester, sheet, '[00:00.00] 歌词').fontFamily,
      CompactTypography.sansFamily,
    );
    expect(
      styleOf(tester, sheet, 'id: one\nsuffix: mp3').fontFamily,
      CompactTypography.monoFamily,
    );
    expect(tester.takeException(), isNull);
  });
}
