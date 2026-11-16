import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/application/library_initial_view_provider.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';

/// 列头和行必须落在同一套列上：它们共用 [LibraryRowMetrics]，列表左右各留
/// pageGutter，列头要是没留，标题列会整列左移 24 像素，越往右偏得越多
/// ——「时长」直接压到窗口边上。
void main() {
  const songs = [
    Song(
      id: 1,
      title: 'Alpha',
      artist: 'Artist A',
      album: 'Album A',
      trackNumber: 1,
      duration: 60000,
      uri: '/music/a1.mp3',
    ),
    Song(
      id: 2,
      title: 'Beta',
      artist: 'Artist B',
      album: 'Album B',
      trackNumber: 2,
      duration: 125000,
      uri: '/music/a2.mp3',
    ),
  ];

  Widget app() {
    return ProviderScope(
      overrides: [
        libraryInitialViewProvider.overrideWithValue(LibraryViewMode.songs),
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: songs)),
        ),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LibraryPane()),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  testWidgets('the column header sits on the columns of the rows', (
    tester,
  ) async {
    await pumpAt(tester, const Size(760, 560));

    final headerTitle = tester.getTopLeft(find.text('标题')).dx;
    final firstRowTitle = tester.getTopLeft(find.text('Alpha')).dx;
    expect(
      headerTitle,
      moreOrLessEquals(firstRowTitle, epsilon: 1),
      reason:
          '标题列的列头与行必须同一条竖线：列表左右各有 pageGutter，'
          '列头不补这一圈就会整列左移 ${CompactTokens.pageGutter}',
    );

    // 行尾是 [时长][收藏]：收藏占住最右边 controlTiny + space4，
    // 所以「时长」的右边缘应该落在行里的数字上方，而不是贴着窗口边。
    final headerDurationRight = tester.getTopRight(find.text('时长')).dx;
    final rowDurationRight = tester.getTopRight(find.text('1:00')).dx;
    expect(
      headerDurationRight,
      moreOrLessEquals(rowDurationRight, epsilon: 1),
      reason: '「时长」的右边缘要和行里的时长数字对齐',
    );
    expect(
      headerDurationRight,
      lessThanOrEqualTo(
        760 - CompactTokens.pageGutter - CompactTokens.controlTiny,
      ),
      reason: '列头不许越过列表的右边距',
    );
  });

  testWidgets('the count keeps its distance from the search field', (
    tester,
  ) async {
    // 宽窗口里搜索框和结果数同一行：中间不留一道固定的缝，「2 首」会贴上
    // 输入框的描边。
    await pumpAt(tester, const Size(900, 560));

    final field = tester.getRect(find.byType(TextField));
    // 假控制器不数匹配数，结果数是「0 首」；这里只看它和搜索框的距离。
    final count = tester.getRect(find.textContaining('首').first);
    expect(
      count.left - field.right,
      greaterThanOrEqualTo(CompactTokens.space8),
      reason: '「2 首」贴在搜索框上就是这条缝没了',
    );
  });

  testWidgets('窄窗口把计数交给页头，搜索收成一颗图标', (tester) async {
    await pumpAt(tester, const Size(760, 560));

    // 页头只剩一个数，工具栏不再重复它；搜索行折起来，等图标叫它。
    expect(find.textContaining('首'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('library-search-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-search-toggle')));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the columns still line up in the narrow window', (tester) async {
    await pumpAt(tester, const Size(600, 520));

    expect(
      tester.getTopLeft(find.text('标题')).dx,
      moreOrLessEquals(tester.getTopLeft(find.text('Alpha')).dx, epsilon: 1),
    );
  });
}
