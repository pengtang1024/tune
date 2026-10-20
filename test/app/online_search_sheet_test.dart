import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/l10n/app_localizations.dart';

void main() {
  testWidgets('online search sheet renders grouped results', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicSourcesControllerProvider.overrideWith(
            () => _FakeSourcesController(),
          ),
          onlineSearchControllerProvider.overrideWith(
            () => _FakeOnlineSearchController(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showOnlineSearchSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('在线搜索'), findsWidgets);
    expect(find.text('搜索已启用的在线音源；结果不会写入音乐库'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.tap(find.text('搜索'));
    await tester.pumpAndSettle();

    expect(find.text('DEMO SOURCE', findRichText: true), findsOneWidget);
    expect(find.text('Song hello'), findsOneWidget);
    expect(find.text('播放全部'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search sheet closes when the reader taps outside it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicSourcesControllerProvider.overrideWith(
            () => _FakeSourcesController(),
          ),
          onlineSearchControllerProvider.overrideWith(
            () => _FakeOnlineSearchController(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showOnlineSearchSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    // The room above the sheet belongs to the barrier, so a tap there closes
    // the sheet instead of being swallowed by the empty part of it.
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSourcesController extends MusicSourcesController {
  @override
  Future<MusicSourcesState> build() async {
    return const MusicSourcesState(
      sources: [
        MusicSourceConfig(
          id: 'plugin_demo',
          name: 'Demo Source',
          kind: MusicSourceKind.plugin,
          settings: {'pluginFile': 'demo.js', 'query': 'hello'},
        ),
      ],
    );
  }
}

class _FakeOnlineSearchController extends OnlineSearchController {
  @override
  Future<OnlineSearchState> build() async => const OnlineSearchState();

  @override
  Future<void> search(String query) async {
    state = AsyncData(
      OnlineSearchState(
        query: query,
        results: {
          'plugin_demo': SourceScanResult(
            sourceId: 'plugin_demo',
            status: SourceScanStatus.success,
            songs: [
              SourceSongFactory.create(
                sourceId: 'plugin_demo',
                externalId: '1',
                title: 'Song $query',
                artist: 'Artist',
                duration: 5000,
                streamUrl: 'https://example.com/1.mp3',
              ),
            ],
          ),
        },
      ),
    );
  }
}
