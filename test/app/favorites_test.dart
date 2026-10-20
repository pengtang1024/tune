import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/favorites/data/favorites_store.dart';
import 'package:tune/features/favorites/presentation/favorites_pane.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/favorite_button.dart';

import '../services/fake_persistence.dart';
import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';
import 'music_sources_section_test.dart' show FakeMusicSourcesController;

/// The tracks the user marks with a heart.
///
/// The controller is the one place that knows which tracks are liked, and
/// the store keeps the answer so a heart survives a restart of the app.
void main() {
  const songA = Song(
    id: 1,
    title: 'Alpha',
    artist: 'Artist A',
    duration: 180000,
    uri: '/music/a.mp3',
  );
  const songB = Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    duration: 120000,
    uri: '/music/b.mp3',
  );

  late FakePersistenceService persistence;

  setUp(() {
    persistence = FakePersistenceService();
  });

  Widget app({required Widget home, required List<Song> songs}) {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        audioPlayerServiceProvider.overrideWithValue(audio),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: songs)),
        ),
        musicSourcesControllerProvider.overrideWith(
          () => FakeMusicSourcesController(const MusicSourcesState()),
        ),
        playbackControllerProvider.overrideWith(
          (ref) => PlaybackController(
            audio,
            FakeSongDownloadService(),
            FakeStreamUrlResolver(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    );
  }

  test('a marked track stays marked after a restart', () async {
    final container = ProviderContainer(
      overrides: [persistenceServiceProvider.overrideWithValue(persistence)],
    );
    addTearDown(container.dispose);

    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(songA.uri);
    expect(
      container.read(favoritesControllerProvider).contains(songA.uri),
      isTrue,
    );

    // The store holds the answer, so a new container reads it back.
    final reloaded = ProviderContainer(
      overrides: [persistenceServiceProvider.overrideWithValue(persistence)],
    );
    addTearDown(reloaded.dispose);

    expect(
      reloaded.read(favoritesControllerProvider).contains(songA.uri),
      isTrue,
    );
    expect(persistence.getStringList(FavoritesStore.key), [songA.uri]);
  });

  test('a mark is taken away by a second click', () async {
    final container = ProviderContainer(
      overrides: [persistenceServiceProvider.overrideWithValue(persistence)],
    );
    addTearDown(container.dispose);

    final controller = container.read(favoritesControllerProvider.notifier);
    await controller.toggle(songA.uri);
    await controller.toggle(songA.uri);

    expect(
      container.read(favoritesControllerProvider).contains(songA.uri),
      isFalse,
    );
    expect(persistence.getStringList(FavoritesStore.key), isEmpty);
  });

  testWidgets('the row of the library marks a track with a heart', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: const LibraryPane(), songs: const [songA, songB]),
    );
    await tester.pumpAndSettle();

    // Nothing is marked yet, so the hearts are empty.
    expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await tester.tap(find.byType(FavoriteButton).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(
      find.byTooltip('取消收藏'),
      findsOneWidget,
      reason: 'the heart of a marked track says how to take the mark away',
    );
  });

  testWidgets('the page of the favorites lists the marked tracks', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: const FavoritesPane(), songs: const [songA, songB]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('还没有喜欢的曲子'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(songA.uri);
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);

    // Taking the mark away takes the track out of the page.
    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsNothing);
  });
}
