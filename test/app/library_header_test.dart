import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/presentation/library_header.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The heading of the library offers what the page is scoped to and the wall
/// of albums; both entries are named, so the reader does not have to guess
/// what an icon does.
void main() {
  Widget app(Widget child) => MaterialApp(
    theme: CompactTheme.light,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  LibraryHeader header({
    VoidCallback? onAlbums,
    bool albumsActive = false,
  }) {
    return LibraryHeader(
      summary: '5,106 项内容 · 984 张专辑 · 15 个来源',
      onAddAll: null,
      onScan: () {},
      scanning: false,
      onSearchOnline: null,
      onAlbums: onAlbums,
      albumsActive: albumsActive,
      treeExpanded: false,
      onToggleTree: () {},
    );
  }

  testWidgets('the albums entry opens the wall', (tester) async {
    var opened = 0;
    await tester.pumpWidget(app(header(onAlbums: () => opened += 1)));

    await tester.tap(find.byKey(const ValueKey('library-albums')));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('a library without albums leaves the entry out', (tester) async {
    await tester.pumpWidget(app(header()));

    expect(find.byKey(const ValueKey('library-albums')), findsNothing);
  });
}
