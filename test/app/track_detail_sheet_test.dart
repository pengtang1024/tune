import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import 'package:tune/shared/ui/track_meta.dart';

/// The details panel is a row of chips.
///
/// Every fact of a track is a chip: the icon says which fact it is, the chip
/// writes the name of the fact and its value. The addresses are the one thing
/// a chip cannot write out — they are longer than a line — so each of them
/// names itself and hands the address to a chip of its own.
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

  /// Opens the details of a track and hands back the tree of the sheet.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(app(const TrackMeta(song: song, index: 0)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet carries a heart that marks the track', (tester) async {
    var marked = false;
    await tester.pumpWidget(
      app(
        TrackMeta(
          song: song,
          index: 0,
          isFavorite: true,
          onToggleFavorite: () => marked = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看详情'));
    await tester.pumpAndSettle();

    final heart = find.byIcon(Icons.favorite_rounded);
    expect(heart, findsOneWidget);
    await tester.tap(heart);
    expect(marked, isTrue);
  });

  testWidgets('the sheet has no heart when the track cannot be marked', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  testWidgets('every fact of the track is a chip', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final chips = find.descendant(
      of: sheet,
      matching: find.byType(MetaChip),
    );

    expect(chips, findsWidgets);
    expect(
      find.descendant(of: chips, matching: find.text('格式')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chips, matching: find.text('FLAC')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the facts share the rows of a chip strip', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final chips = find.descendant(
      of: sheet,
      matching: find.byType(MetaChip),
    );
    final rows = <double>{};
    for (final chip in chips.evaluate()) {
      rows.add(tester.getTopLeft(find.byWidget(chip.widget)).dy);
    }

    // The chips stand in rows and not in a column: a chip strip that takes
    // one row per fact is a list in another name.
    expect(rows.length, lessThan(chips.evaluate().length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an address is not written out in the line', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    expect(
      find.descendant(of: sheet, matching: find.text('/music/night.flac')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.byType(CopyChip)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the name of an address stands in front of its chip', (
    tester,
  ) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);

    final name = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.text('文件路径')),
    );
    final chip = tester.getTopLeft(
      find.descendant(of: sheet, matching: find.byType(CopyChip)),
    );

    expect(chip.dx, greaterThan(name.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pointer on the chip shows the address', (tester) async {
    await openSheet(tester);
    final sheet = find.byType(BottomSheet);
    final chip = find.descendant(of: sheet, matching: find.byType(CopyChip));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(chip));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('/music/night.flac'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a click on the chip takes the address away', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await openSheet(tester);
    final sheet = find.byType(BottomSheet);
    final chip = find.descendant(of: sheet, matching: find.byType(CopyChip));

    await tester.tap(chip);
    // The toast stays for a moment and the pump waits for the timer of the
    // toast as well, so the sheets are pumped one frame at a time.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copied, '/music/night.flac');
    expect(find.text('已复制到剪贴板'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long description is a paragraph and not a chip', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text(song.description!), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MetaChip),
        matching: find.text(song.description!),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
