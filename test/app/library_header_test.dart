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
    VoidCallback? onSearchOnline,
    bool compact = false,
    bool searchOpen = false,
    VoidCallback? onSearch,
  }) {
    return LibraryHeader(
      summary: '5,106 项内容 · 984 张专辑 · 15 个来源',
      count: 420,
      kind: null,
      compact: compact,
      searchOpen: searchOpen,
      onSearch: onSearch ?? () {},
      onAddAll: null,
      onScan: () {},
      scanning: false,
      onSearchOnline: onSearchOnline,
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

  testWidgets('窄窗口的页头只剩标题、当前列表的计数和一颗搜索图标', (tester) async {
    await tester.pumpWidget(app(header(compact: true)));

    // 一个数：列表现在有多少条，单位跟着内容走。页头原来的「5,106 项内容」
    // 和工具栏的计数并排摆着，读者分不清哪个才是这一页的重点。
    expect(find.text('420 首'), findsOneWidget);
    expect(find.text('5,106 项内容 · 984 张专辑 · 15 个来源'), findsNothing);
    expect(find.byKey(const ValueKey('library-search-toggle')), findsOneWidget);
    // 页级动作不再占标题行的宽度。
    expect(find.byKey(const ValueKey('library-albums')), findsNothing);
  });

  testWidgets('窄窗口里搜索图标开关搜索行', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(header(compact: true, onSearch: () => taps += 1)),
    );

    await tester.tap(find.byKey(const ValueKey('library-search-toggle')));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('窄窗口里专辑墙与在线搜索进 ⋯ 菜单', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      app(
        header(
          compact: true,
          onAlbums: () => opened += 1,
          onSearchOnline: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('library-more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-more-albums')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-more-online')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-more-albums')));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
