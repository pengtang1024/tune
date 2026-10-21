import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

/// Switching between the sections of the shell keeps the tree whole.
///
/// The navigator of the router carries a global key. The shell used to keep
/// the page of the old section and the page of the new one in the tree at the
/// same time, so two navigators with the same key stood in one tree: Flutter
/// tears the tree apart for a frame, and the section on the screen at that
/// moment loses a piece of itself.
void main() {
  testWidgets('switching a section keeps the tree whole', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    // ignore: invalid_use_of_visible_for_testing_member
    final persistence = FakePersistenceService();

    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return CompactShell(currentPath: state.uri.path, child: child);
          },
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const Text('library page'),
            ),
            GoRoute(
              path: '/queue',
              builder: (context, state) => const Text('queue page'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => playback),
        ],
        child: MaterialApp.router(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/queue');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('queue page'), findsOneWidget);
  });
}
