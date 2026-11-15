import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/content_kind.dart';
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
    ContentKind? selectedKind = ContentKind.music,
    ValueChanged<ContentKind>? onKind,
    bool showKindMenu = true,
    VoidCallback? onAlbums,
    bool albumsActive = false,
  }) {
    return LibraryHeader(
      summary: '5,106 项内容 · 984 张专辑 · 15 个来源',
      onAddAll: null,
      onScan: () {},
      scanning: false,
      onSearchOnline: null,
      selectedKind: selectedKind,
      onKind: onKind ?? (_) {},
      showKindMenu: showKindMenu,
      onAlbums: onAlbums,
      albumsActive: albumsActive,
      treeExpanded: false,
      onToggleTree: () {},
    );
  }

  testWidgets('the content menu names the scope and offers every kind', (
    tester,
  ) async {
    ContentKind? picked;
    await tester.pumpWidget(app(header(onKind: (kind) => picked = kind)));

    expect(find.text('音乐'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-content-kind')));
    await tester.pumpAndSettle();

    expect(find.text('有声书'), findsOneWidget);
    expect(find.text('电台'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<ContentKind>, '播客'),
    );
    await tester.pumpAndSettle();

    expect(picked, ContentKind.podcast);
  });

  testWidgets('a library of songs offers no content menu', (tester) async {
    await tester.pumpWidget(app(header(showKindMenu: false)));

    expect(
      find.byKey(const ValueKey('library-content-kind')),
      findsNothing,
    );
    expect(find.text('电台'), findsNothing);
  });

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
