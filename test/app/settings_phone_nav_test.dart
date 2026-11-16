import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/settings/presentation/settings_pane_nav.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';

/// 手机形态里设置页用一排 chip 换页，不再让左侧那条图标栏吃掉正文宽度。
void main() {
  Future<void> openSettings(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(
            FakePersistenceService(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
          defaultPlayerServiceProvider.overrideWithValue(
            FakeDefaultPlayerService(),
          ),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(const LibraryState()),
          ),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsPane(
              capabilities: AppCapabilities.forPlatform(AppPlatform.linux),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('手机里左侧图标栏换成一行 chip，正文拿到整条宽度', (tester) async {
    await openSettings(tester, const Size(390, 844));

    expect(find.byType(SettingsNavRail), findsNothing);
    expect(find.byKey(const ValueKey('settings-nav-strip')), findsOneWidget);
    // 每一档都带着名字出现：只有图标的竖栏在手机上认不出来。
    expect(
      find.byKey(const ValueKey('settings-nav-appearance')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings-nav-playback')), findsOneWidget);
    // 一排放不下十档：往右拖，后面的档位才进视野。
    expect(find.byKey(const ValueKey('settings-nav-about')), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('settings-nav-strip')),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-nav-about')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面窗口再窄也保留左侧栏，不换成 chip', (tester) async {
    await openSettings(tester, const Size(700, 700));

    expect(find.byType(SettingsNavRail), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-nav-strip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点 chip 换组时正文跟着滚到那一组，chip 也留在视野里', (tester) async {
    await openSettings(tester, const Size(390, 844));

    final playback = find.byKey(const ValueKey('settings-nav-playback'));
    expect(playback, findsOneWidget);
    expect(tester.getRect(playback).right, lessThanOrEqualTo(390));

    await tester.tap(playback);
    await tester.pumpAndSettle();

    // 正文滚过去了：播放卡片顶边落在视口里，第一组已经滚出屏幕。
    final card = tester.getRect(
      find.byKey(const ValueKey('settings-card-playback')),
    );
    expect(card.top, greaterThanOrEqualTo(0));
    expect(card.top, lessThan(844));
    final appearance = tester.getRect(
      find.byKey(const ValueKey('settings-card-appearance')),
    );
    expect(appearance.top, lessThan(0));
    expect(tester.takeException(), isNull);
  });
}

class FakeLibraryController extends LibraryController {
  FakeLibraryController(this.seed);

  final LibraryState seed;

  @override
  Future<LibraryState> build() async => seed;
}
