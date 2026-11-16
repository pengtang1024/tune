import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/domain/library_collection.dart';
import 'package:tune/features/library/presentation/library_collections_view.dart';
import 'package:tune/l10n/app_localizations.dart';

/// A collection is a shelf a reader opens, and one they can empty: the card
/// says what it holds and the two marks say what a tap does.
void main() {
  Widget app(Widget child) => MaterialApp(
    theme: CompactTheme.light,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  const collections = [
    LibraryCollection(
      sourceId: 'community_classical',
      name: '社区古典',
      trackCount: 199,
      itemCount: 12,
    ),
    LibraryCollection(
      sourceId: 'local',
      name: '本地音乐',
      trackCount: 42,
      itemCount: 5,
    ),
  ];

  testWidgets('a card names the collection and says what it holds', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(LibraryCollectionsView(collections: collections, onOpen: (_) {})),
    );

    expect(find.text('社区古典'), findsOneWidget);
    expect(find.text('本地音乐'), findsOneWidget);
    expect(find.text('199 首'), findsOneWidget);
    expect(find.textContaining('12 个条目'), findsOneWidget);
  });

  testWidgets('a tap opens the collection', (tester) async {
    LibraryCollection? opened;
    await tester.pumpWidget(
      app(
        LibraryCollectionsView(
          collections: collections,
          onOpen: (collection) => opened = collection,
        ),
      ),
    );

    await tester.tap(find.text('本地音乐'));
    await tester.pumpAndSettle();

    expect(opened?.sourceId, 'local');
  });

  testWidgets('the pruning mark appears with the pointer, not before', (
    tester,
  ) async {
    LibraryCollection? cleared;
    await tester.pumpWidget(
      app(
        LibraryCollectionsView(
          collections: collections,
          onOpen: (_) {},
          onClear: (collection) => cleared = collection,
        ),
      ),
    );

    expect(find.byIcon(Icons.clear_all_rounded), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(find.text('本地音乐')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.clear_all_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear_all_rounded));
    await tester.pumpAndSettle();
    expect(cleared?.sourceId, 'local');
  });

  testWidgets('an empty library says there is nothing to open', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(LibraryCollectionsView(collections: const [], onOpen: (_) {})),
    );

    expect(find.text('换个关键词，或清除搜索条件'), findsOneWidget);
  });
}
