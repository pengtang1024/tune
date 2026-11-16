import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/library_sort.dart';
import 'package:tune/features/library/presentation/library_toolbar.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The toolbar never hides a rule silently: a list that leaves dirty rows out
/// says how many and offers the way back.
void main() {
  Widget app(Widget child) => ProviderScope(
    child: MaterialApp(
      theme: CompactTheme.light,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  Widget toolbar({
    int hidden = 0,
    VoidCallback? onShow,
    LibraryFilter filter = const LibraryFilter(kinds: {}),
    bool compact = false,
    bool searchOpen = false,
  }) {
    return LibraryToolbar(
      controller: TextEditingController(),
      query: '',
      count: 10,
      hiddenMissingDuration: hidden,
      kind: null,
      sources: const [],
      sourceLabels: const {},
      sourceFilter: null,
      sort: LibrarySort.title,
      filter: filter,
      onQueryChanged: (_) {},
      onClearQuery: () {},
      onSourceFilter: (_) {},
      onSort: (_) {},
      onFilter: () {},
      onShowMissingDuration: onShow ?? () {},
      compact: compact,
      searchOpen: searchOpen,
    );
  }

  testWidgets(
    'the toolbar states how many tracks hide for a missing duration',
    (tester) async {
      var shown = false;
      await tester.pumpWidget(
        app(toolbar(hidden: 3, onShow: () => shown = true)),
      );

      expect(find.text('已隐藏 3 条时长缺失的曲目'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('library-show-missing-duration')),
      );
      expect(shown, isTrue);
    },
  );

  testWidgets('nothing hidden means no note', (tester) async {
    await tester.pumpWidget(app(toolbar()));

    expect(
      find.byKey(const ValueKey('library-hidden-missing-duration')),
      findsNothing,
    );
  });

  testWidgets('窄窗口的工具栏不再放搜索框与结果数', (tester) async {
    await tester.pumpWidget(app(toolbar(compact: true)));

    expect(find.byType(TextField), findsNothing);
    expect(find.text('10 首'), findsNothing);
    // 这一行留的是改列表内容的那几颗：筛选、排序、搜索。
    expect(find.byKey(const ValueKey('library-filter')), findsOneWidget);
  });

  testWidgets('窄窗口点开搜索时搜索行随状态出现', (tester) async {
    await tester.pumpWidget(app(toolbar(compact: true, searchOpen: true)));

    expect(find.byType(TextField), findsOneWidget);
  });
}
