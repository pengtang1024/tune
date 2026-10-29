import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_marks_controller.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_task_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_mark.dart';
import 'package:tune/features/smart_lyrics/presentation/marks_page.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The one place every mark is seen (docs/smart-lyrics.md §7.4, M6): the
/// marks grouped by track, the open ones with the presses that answer
/// them, and the reword that writes the reader's words into the file the
/// reading chain tops.
void main() {
  const song = Song(id: 1, title: '月亮', artist: '歌手', uri: '/a.mp3');

  SmartLyricsMark mark({
    int? line,
    SmartLyricsMarkKind kind = SmartLyricsMarkKind.line,
    SmartLyricsMarkState state = SmartLyricsMarkState.uncleared,
  }) => SmartLyricsMark(
    id: 1,
    songId: song.id,
    line: line,
    kind: kind,
    source: 'system',
    state: state,
    createdAt: DateTime(2026, 10, 28),
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    List<SmartLyricsMarkGroup> groups = const [],
    SmartLyricsMarksController Function(Ref ref)? controller,
    LibraryPaths? paths,
    SmartLyricsTaskStore? store,
  }) async {
    final overrides = <Override>[
      smartLyricsMarksProvider.overrideWith((ref) => Future.value(groups)),
      if (controller != null)
        smartLyricsMarksControllerProvider.overrideWith(controller),
      if (paths != null)
        libraryPathsProvider.overrideWithValue(paths),
      if (store != null)
        smartLyricsTaskStoreProvider.overrideWithValue(store),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SmartLyricsMarksPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty library says there are no marks yet', (tester) async {
    await pumpPage(tester);

    expect(find.text('还没有标记——听到不对的行，点行尾的小旗'), findsOneWidget);
  });

  testWidgets('the marks are listed by track, and the open one answers the '
      'press', (tester) async {
    _RecordingMarks? marks;
    await pumpPage(
      tester,
      groups: [
        SmartLyricsMarkGroup(song: song, marks: [
          mark(line: 0),
          mark(kind: SmartLyricsMarkKind.song, state: SmartLyricsMarkState.revoked),
        ]),
      ],
      controller: (ref) => marks = _RecordingMarks(ref),
    );

    expect(find.text('月亮 — 歌手'), findsOneWidget);
    expect(find.text('第 1 行'), findsOneWidget);
    expect(find.text('等复解'), findsOneWidget);
    expect(find.text('整首不对'), findsOneWidget);
    expect(find.text('已撤销'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('smart-lyrics-reword')),
      findsOneWidget,
      reason: 'only the open line mark offers the reword',
    );
    expect(
      tester
          .widgetList<TextButton>(
            find.byKey(const ValueKey('smart-lyrics-revoke')),
          )
          .length,
      1,
      reason: 'the answered mark has nothing left to take back',
    );

    await tester.tap(find.byKey(const ValueKey('smart-lyrics-revoke')));
    await tester.pumpAndSettle();

    expect(marks!.revoked.single.line, 0, reason: 'the line mark, by its '
        'line — and nothing next to it');
  });

  testWidgets('the reword writes the words and answers the mark', (
    tester,
  ) async {
    final paths = _RecordingPaths()..sheet = '[00:12.50]月亮走我叶走';
    final store = _RecordingStore();
    await pumpPage(
      tester,
      groups: [
        SmartLyricsMarkGroup(song: song, marks: [mark(line: 0)]),
      ],
      paths: paths,
      store: store,
    );

    await tester.tap(find.byKey(const ValueKey('smart-lyrics-reword')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('smart-lyrics-reword-field')),
      '月亮走我也走',
    );
    await tester.tap(find.byKey(const ValueKey('smart-lyrics-reword-save')));
    await tester.pumpAndSettle();

    expect(paths.saved.single, '[00:12.50]月亮走我也走',
        reason: 'the words go to the file the reading chain tops');
    expect(store.reworded.single, (1, 0), reason: 'the mark is answered '
        'that way — and only that mark');
  });
}

/// The presses on record.
class _RecordingMarks extends SmartLyricsMarksController {
  _RecordingMarks(super.ref);

  final List<SmartLyricsMark> revoked = [];

  @override
  Future<void> revokeMark(SmartLyricsMark mark) async {
    revoked.add(mark);
  }
}

/// The paths the reword writes through, in memory.
class _RecordingPaths implements LibraryPaths {
  String? sheet;
  final List<String> saved = [];

  @override
  Future<String?> readLyrics(Song song) async => sheet;

  @override
  Future<String?> readSmartLyrics(Song song) async => null;

  @override
  Future<void> saveChosenLyrics(Song song, String lyrics) async {
    saved.add(lyrics);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the marks page test has no file system');
}

/// The store the reword answers the mark through.
class _RecordingStore extends SmartLyricsTaskStore {
  _RecordingStore() : super(database: () => throw UnimplementedError());

  final List<(int, int)> reworded = [];

  @override
  Future<void> rewordMark(int songId, int line) async {
    reworded.add((songId, line));
  }
}
