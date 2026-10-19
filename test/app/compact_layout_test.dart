import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/impl/shared_preferences_service.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/queue/presentation/queue_pane.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import 'fake_audio_player_service.dart';

void main() {
  const songA = Song(
    id: 1,
    title: 'A very long song title that should be ellipsized',
    artist: 'A very long artist name that should be ellipsized',
    duration: 245000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    duration: 120000,
    uri: '/music/b.mp3',
  );
  const songC = Song(
    id: 3,
    title: 'Gamma',
    artist: 'Artist C',
    duration: 90000,
    uri: '/music/c.mp3',
  );
  const remoteSong = Song(
    id: 4,
    title: 'Piano Melody',
    artist: 'Open Artist',
    duration: 10000,
    uri: 'tune://openverse/abc',
    sourceId: 'openverse',
    externalId: 'abc',
    streamUrl: 'https://example.com/a.mp3',
  );

  late SharedPreferencesService persistence;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    persistence = SharedPreferencesService();
    await persistence.init();
  });

  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({required Widget home, required List<Override> overrides}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesServiceProvider.overrideWithValue(persistence),
        ...overrides,
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('compact shell has no overflow at 900x563', (tester) async {
    await setSurface(tester, const Size(900, 563));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/library',
          child: SizedBox.shrink(),
        ),
        overrides: [audioPlayerServiceProvider.overrideWithValue(audio)],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tune'), findsOneWidget);
    expect(find.text('音乐库'), findsOneWidget);
  });

  testWidgets('compact shell has no overflow at 760x483', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/queue',
          child: SizedBox.shrink(),
        ),
        overrides: [audioPlayerServiceProvider.overrideWithValue(audio)],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('播放队列'), findsOneWidget);
  });

  testWidgets('compact shell has no overflow at 1100x663', (tester) async {
    await setSurface(tester, const Size(1100, 663));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('A very long song title that should be ellipsized'),
      findsOneWidget,
    );
  });

  testWidgets('library pane lays out songs at 760x483', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              const LibraryState(
                songs: [songA, songB, songC],
                statusMessage: '3 首歌曲',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('A very long song title that should be ellipsized'),
      findsOneWidget,
    );

    await tester.tap(
      find.text('A very long song title that should be ellipsized'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(audio.playedSong?.uri, songA.uri);
  });

  testWidgets('library source filter narrows the song list', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              const LibraryState(songs: [songA, remoteSong]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(songA.title), findsOneWidget);
    expect(find.text(remoteSong.title), findsOneWidget);
    expect(find.byTooltip('Openverse'), findsOneWidget);

    await tester.tap(find.byTooltip('筛选来源'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Openverse').last);
    await tester.pumpAndSettle();

    expect(find.text(remoteSong.title), findsOneWidget);
    expect(find.text(songA.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library keeps partial source failures visible', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    const message = '已更新 1 首歌曲，1 个音源失败';

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              LibraryState(
                songs: const [songA],
                scanStatus: LibraryScanStatus.completed,
                statusMessage: message,
                sourceSummaries: {
                  'openverse': SourceScanSummary(
                    sourceId: 'openverse',
                    status: SourceScanStatus.failed,
                    songCount: 0,
                    scannedAt: DateTime(2026),
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue pane lays out rows at 760x483', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final controller = PlaybackController(audio);
    await controller.playQueue([songA, songB, songC]);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/queue', child: QueuePane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => controller),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('播放队列'), findsNWidgets(2));
  });

  testWidgets('settings pane lays out at 760x483', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/settings',
          child: SettingsPane(),
        ),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(const LibraryState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('音乐库'), findsOneWidget);
  });

  testWidgets('settings theme chip updates controller', (tester) async {
    await setSurface(tester, const Size(760, 483));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/settings',
          child: SettingsPane(),
        ),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(const LibraryState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPane)),
    );
    expect(
      container.read(settingsControllerProvider).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.text('深色模式'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsControllerProvider).themeMode,
      ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('library search field follows controller query reset', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 563));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              const LibraryState(songs: [songA, songB]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );

    container.read(libraryControllerProvider.notifier).setQuery('Beta');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Beta',
    );

    container.read(libraryControllerProvider.notifier).setQuery('');
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings scan and clear actions follow library scan state', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 563));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/settings',
          child: SettingsPane(),
        ),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(
              const LibraryState(scanStatus: LibraryScanStatus.scanning),
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '扫描中'))
          .onPressed,
      isNull,
    );
    final clearButton = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('清空音乐库'),
        matching: find.byWidgetPredicate((widget) => widget is TextButton),
      ),
    );
    expect(clearButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

class FakeLibraryController extends LibraryController {
  FakeLibraryController(this.seed);

  final LibraryState seed;

  @override
  Future<LibraryState> build() async => seed;

  @override
  Future<void> scan(List<String> paths, {bool auto = false}) async {}

  @override
  void setQuery(String query) {
    state = AsyncData((state.valueOrNull ?? seed).copyWith(query: query));
  }
}
