import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/domain/library_category.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/presentation/library_category_view.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The category view of docs/library-browse.md: a card names a value and
/// a count, and a click hands the value back to the page.
void main() {
  testWidgets('a genre card hands its value back', (tester) async {
    LibraryCategoryKind? kind;
    Object? value;
    await tester.pumpWidget(
      MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LibraryCategoryView(
            kind: LibraryCategoryKind.genres,
            onKindChanged: (_) {},
            songs: const [],
            facets: const LibraryFacets(genres: {'jazz': 3}),
            sourceLabels: const {},
            onSelect: (nextKind, nextValue) {
              kind = nextKind;
              value = nextValue;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('爵士'), findsOneWidget);
    await tester.tap(find.textContaining('爵士'));
    await tester.pumpAndSettle();

    expect(kind, LibraryCategoryKind.genres);
    expect(value, 'jazz');
  });
}
