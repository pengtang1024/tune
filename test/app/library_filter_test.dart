import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_facets.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_filter_chips.dart';
import 'package:tune/features/library/presentation/library_filter_panel.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The filter panel and the chips of docs/library-browse.md: a click
/// changes the filter at once, and a chip takes its own value back out.
class _FilterController extends LibraryController {
  @override
  Future<LibraryState> build() async => const LibraryState();

  @override
  Future<void> setFilter(LibraryFilter filter) async {
    state = AsyncData(state.requireValue.copyWith(filter: filter));
  }
}

void main() {
  Widget app({required Widget child, required List<Override> overrides}) {
    return ProviderScope(
      overrides: [
        libraryControllerProvider.overrideWith(_FilterController.new),
        libraryFacetsProvider.overrideWith(
          (ref) async => const LibraryFacets(
            genres: {'jazz': 3, 'rock': 2},
            decades: {1990: 2},
            languages: {'zh': 4},
            formats: {'mp3': 5},
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('a genre chip narrows the filter at once', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      app(
        child: const LibraryFilterPanel(sourceLabels: {}),
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryFilterPanel)),
    );

    await tester.tap(find.textContaining('爵士'));
    await tester.pumpAndSettle();

    expect(
      container.read(libraryControllerProvider).requireValue.filter.genres,
      {'jazz'},
    );
  });

  testWidgets('a chip takes its value back out', (tester) async {
    LibraryFilter? next;
    await tester.pumpWidget(
      app(
        child: LibraryFilterChips(
          filter: const LibraryFilter(genres: {'jazz'}),
          sourceLabels: const {},
          onChanged: (value) => next = value,
        ),
        overrides: [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(next, LibraryFilter.empty);
  });
}
