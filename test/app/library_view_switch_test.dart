import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/features/library/domain/library_layout.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/features/library/presentation/library_view_switch.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_trigger.dart';

/// The switch only offers what the content can actually show: a podcast has no
/// category wall and a radio has no albums, so the button is not there at all.
void main() {
  Widget app({
    required LibraryViewMode view,
    required List<LibraryViewMode> views,
    LibraryGroupingLabel? groupingLabel,
    void Function(LibraryViewMode)? onChanged,
  }) => MaterialApp(
    theme: CompactTheme.light,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: LibraryViewSwitch(
          view: view,
          views: views,
          groupingLabel: groupingLabel,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('music offers every view', (tester) async {
    await tester.pumpWidget(
      app(view: LibraryViewMode.albums, views: LibraryViewMode.values),
    );

    for (final mode in LibraryViewMode.values) {
      expect(
        find.byIcon(_iconOf(mode)),
        findsOneWidget,
        reason: '$mode should have a button',
      );
    }
  });

  testWidgets('a podcast only offers shows and episodes', (tester) async {
    final layout = libraryLayoutFor(ContentKind.podcast);
    await tester.pumpWidget(
      app(
        view: layout.primary,
        views: layout.views,
        groupingLabel: layout.groupingLabel,
      ),
    );

    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    expect(find.byIcon(Icons.category_rounded), findsNothing);
    expect(find.byIcon(Icons.view_column_rounded), findsNothing);
    expect(find.byIcon(Icons.collections_bookmark_rounded), findsNothing);
  });

  testWidgets('the album button is called shows for a podcast', (tester) async {
    final layout = libraryLayoutFor(ContentKind.podcast);
    await tester.pumpWidget(
      app(
        view: layout.primary,
        views: layout.views,
        groupingLabel: layout.groupingLabel,
      ),
    );

    final trigger = tester.widget<HintTrigger>(
      find.ancestor(
        of: find.byIcon(Icons.grid_view_rounded),
        matching: find.byType(HintTrigger),
      ),
    );
    expect(trigger.message, '节目');
  });

  testWidgets('pressing a button reports the view it stands for', (
    tester,
  ) async {
    final picked = <LibraryViewMode>[];
    await tester.pumpWidget(
      app(
        view: LibraryViewMode.albums,
        views: LibraryViewMode.values,
        onChanged: picked.add,
      ),
    );

    await tester.tap(find.byIcon(Icons.view_list_rounded));
    expect(picked, [LibraryViewMode.songs]);
  });
}

IconData _iconOf(LibraryViewMode mode) => switch (mode) {
  LibraryViewMode.songs => Icons.view_list_rounded,
  LibraryViewMode.columns => Icons.view_column_rounded,
  LibraryViewMode.categories => Icons.category_rounded,
  LibraryViewMode.albums => Icons.grid_view_rounded,
  LibraryViewMode.collections => Icons.collections_bookmark_rounded,
};
