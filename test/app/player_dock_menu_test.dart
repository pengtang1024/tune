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
import 'package:tune/shared/ui/equalizer_sheet.dart';
import 'package:tune/shared/ui/favorite_button.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

const song = Song(
  id: 1,
  title: 'A song',
  artist: 'An artist',
  duration: 245000,
  uri: '/music/a.mp3',
);

/// Guards how many actions the dock shows at once.
///
/// The bar keeps three and folds the shape of the window and the equalizer
/// behind one menu: an extra icon on every width is what the row could not
/// pay for before.
void main() {
  testWidgets('the dock folds the window action and the equalizer into a menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 700);
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

    final dock = find.byType(PlayerDock);
    expect(
      find.descendant(of: dock, matching: find.byType(FavoriteButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dock,
        matching: find.byIcon(Icons.queue_music_rounded),
      ),
      findsOneWidget,
    );
    final more = find.descendant(
      of: dock,
      matching: find.byKey(const ValueKey<String>('dock-more')),
    );
    expect(more, findsOneWidget);
    // The folded actions stay out of the bar itself.
    expect(
      find.descendant(
        of: dock,
        matching: find.byIcon(Icons.picture_in_picture_alt_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: dock,
        matching: find.byIcon(Icons.equalizer_rounded),
      ),
      findsNothing,
    );

    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.picture_in_picture_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.equalizer_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(EqualizerSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
