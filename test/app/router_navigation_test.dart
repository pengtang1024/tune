import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

/// The shell hands the navigator of the router to the page area, and the
/// router moves between the pages on its own. A second switch in the shell
/// would keep two navigators alive at the same time, and the key of the
/// router belongs to only one of them.
void main() {
  testWidgets('switching the pages of the shell keeps one navigator', (
    tester,
  ) async {
    final persistence = FakePersistenceService();
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => playback),
          libraryControllerProvider.overrideWith(
            () => _FakeLibraryController(
              const LibraryState(songs: [], statusMessage: '4 首歌曲'),
            ),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              locale: const Locale('zh', 'CN'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

    for (final path in ['/queue', '/favorites', '/library', '/sources']) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        path,
        reason: 'the page of $path has to be the one that is shown',
      );
    }

    router.push('/now-playing');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    // A deep link to a page that is gone lands on the library.
    router.go('/a-page-that-is-gone');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/library',
    );
  });
}

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.seed);

  final LibraryState seed;

  @override
  Future<LibraryState> build() async => seed;
}
