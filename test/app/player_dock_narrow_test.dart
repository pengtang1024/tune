import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

const song = Song(
  id: 1,
  title: 'A very long song title that should be ellipsized',
  artist: 'A very long artist name that should be ellipsized',
  duration: 245000,
  uri: '/music/a.mp3',
);

/// Guards the dock of the narrowest window.
///
/// Below 720 the slider of the volume goes away, but the mute button has to
/// stay: without it the narrow window has no volume control at all. The
/// transport also has to keep sitting on the centre of the bar.
void main() {
  testWidgets('the narrow dock mutes and does not overflow', (tester) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final persistence = FakePersistenceService();
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([song]);

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
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CompactShell(
            currentPath: '/library',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mute = find.descendant(
      of: find.byType(PlayerDock),
      matching: find.byIcon(Icons.volume_up_rounded),
    );
    expect(mute, findsOneWidget, reason: 'the narrow dock keeps the mute');
    expect(tester.takeException(), isNull, reason: 'the dock fits the window');

    await tester.tap(mute);
    await tester.pumpAndSettle();

    expect(playback.state.volume, 0);
    expect(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.volume_off_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // The two sides of the bar share the room evenly, so the transport stays
    // on the centre of the dock after the volume control kept its button.
    final dockCentre = tester.getCenter(find.byType(PlayerDock)).dx;
    final playCentre = tester.getCenter(find.byIcon(Icons.pause_rounded)).dx;
    expect(
      playCentre,
      closeTo(dockCentre, 1),
      reason: 'the transport sits on the centre of the bar',
    );
  });
}
