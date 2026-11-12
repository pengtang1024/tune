import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/layout/window_form_controller.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/window_layout_store.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/shell/presentation/mini_player_bar.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

const song = Song(
  id: 1,
  title: 'Window form',
  artist: 'Tune',
  duration: 180000,
  uri: '/music/window-form.mp3',
);

void main() {
  late FakePersistenceService persistence;
  late FakeAudioPlayerService audio;
  late PlaybackController playback;

  setUp(() async {
    persistence = FakePersistenceService();
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([song]);
  });

  tearDown(() => audio.dispose());

  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({required Widget home}) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(audio),
        playbackControllerProvider.overrideWith((ref) => playback),
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

  /// The page below the shell, holding text that only a kept page keeps.
  Widget probePage() {
    return const Scaffold(
      body: Center(child: TextField()),
    );
  }

  testWidgets('the dock shrinks the shell to the mini bar and back', (
    tester,
  ) async {
    // Wide enough for the window actions at the end of the dock.
    await setSurface(tester, const Size(1120, 700));

    await tester.pumpWidget(
      app(
        home: CompactShell(currentPath: '/library', child: probePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kept');
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.picture_in_picture_alt_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayerBar), findsOneWidget);
    expect(find.byType(PlayerDock), findsNothing);
    // The page stays in the tree while the window is small: its text is
    // still there, only offstage.
    expect(find.text('kept', skipOffstage: false), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(MiniPlayerBar),
        matching: find.byIcon(Icons.open_in_full_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayerBar), findsNothing);
    expect(find.byType(PlayerDock), findsOneWidget);
    expect(find.text('kept'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved mini form opens as the bar and lays out at its size', (
    tester,
  ) async {
    persistence.values[WindowLayoutStore.formKey] = WindowForm.mini.name;
    await setSurface(tester, const Size(360, 132));

    await tester.pumpWidget(
      app(
        home: CompactShell(currentPath: '/library', child: probePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayerBar), findsOneWidget);
    expect(find.text('Window form', skipOffstage: false), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the now playing page takes the immersive form and gives it back', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 600));

    await tester.pumpWidget(app(home: const NowPlayingPage()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPage)),
    );
    expect(container.read(windowFormProvider), WindowForm.normal);
    expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pumpAndSettle();

    expect(container.read(windowFormProvider), WindowForm.immersive);
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
    expect(
      persistence.getString(WindowLayoutStore.formKey),
      WindowForm.immersive.name,
    );

    await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
    await tester.pumpAndSettle();

    expect(container.read(windowFormProvider), WindowForm.normal);
    expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving the now playing page leaves the immersive form', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 600));

    // The page closes itself with the router, so the test needs one.
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/now-playing'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/now-playing',
          builder: (context, state) => const NowPlayingPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          defaultPlayerServiceProvider.overrideWithValue(
            FakeDefaultPlayerService(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => playback),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NowPlayingPage)),
    );
    expect(container.read(windowFormProvider), WindowForm.immersive);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(NowPlayingPage), findsNothing);
    expect(container.read(windowFormProvider), WindowForm.normal);
    expect(tester.takeException(), isNull);
  });
}
