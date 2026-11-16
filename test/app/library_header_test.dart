import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/features/library/presentation/library_header.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The heading of the library names the page and, in a narrow window, the one
/// count of the list; it has no entry that changes how the list is read.
void main() {
  Widget app(Widget child) => MaterialApp(
    theme: CompactTheme.light,
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  LibraryHeader header({
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
      treeExpanded: false,
      onToggleTree: () {},
    );
  }

  testWidgets('页头不再有专辑视图入口', (tester) async {
    await tester.pumpWidget(app(header()));

    // 专辑就是列表里的一行，页头没有第二个入口可点。
    expect(find.byKey(const ValueKey('library-albums')), findsNothing);
    expect(find.text('专辑视图'), findsNothing);
  });

  testWidgets('窄窗口里页头把摘要收成一个计数', (tester) async {
    await tester.pumpWidget(app(header(compact: true)));

    expect(find.text('420 首'), findsOneWidget);
    expect(find.text('5,106 项内容 · 984 张专辑 · 15 个来源'), findsNothing);
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

  testWidgets('窄窗口里在线搜索进 ⋯ 菜单', (tester) async {
    await tester.pumpWidget(
      app(header(compact: true, onSearchOnline: () {})),
    );

    await tester.tap(find.byKey(const ValueKey('library-more')));
    await tester.pumpAndSettle();

    // 专辑入口跟着视图开关一起删了；页级动作只剩在线搜索、扫描和加队列。
    expect(find.byKey(const ValueKey('library-more-albums')), findsNothing);
    expect(find.byKey(const ValueKey('library-more-online')), findsOneWidget);
  });
}
