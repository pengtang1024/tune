import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/data/playback_session_store.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/player/presentation/now_playing_track_info.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/side_panel_host.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

/// A phone stacks the now playing page and lifts its queue from the bottom.
void main() {
  const song = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    duration: 180000,
    uri: '/music/a.mp3',
  );

  Future<void> pumpNowPlaying(WidgetTester tester, Size size) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final store = PlaybackSessionStore(FakePersistenceService());
    await store.saveQueue(
      queue: const [song],
      currentUri: song.uri,
      playMode: PlayMode.sequential,
      history: const [],
    );
    final controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
      sessionStore: store,
    );

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NowPlayingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the cover sits above the words on a phone', (tester) async {
    await pumpNowPlaying(tester, const Size(390, 844));

    final artwork = tester.getRect(find.byType(ArtworkThumb).first);
    final info = tester.getRect(find.byType(NowPlayingTrackInfo));

    expect(info.top, greaterThanOrEqualTo(artwork.bottom));
    expect(
      artwork.center.dx,
      moreOrLessEquals(390 / 2, epsilon: 1),
      reason: 'the stacked block is centered, not left aligned',
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the queue rises from the bottom edge', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SidePanelHost(
            open: true,
            bottomSheet: true,
            onClose: () {},
            barrierLabel: 'close',
            panelBuilder: (context) =>
                const SizedBox.expand(key: ValueKey('queue')),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byKey(const ValueKey('queue')));
    expect(
      rect.bottom,
      moreOrLessEquals(844 - CompactTokens.sidePanelGutter, epsilon: 1),
    );
    expect(rect.height, lessThan(844 * 0.8));
    expect(rect.left, greaterThan(0));
    expect(rect.right, lessThan(390));
  });
}
