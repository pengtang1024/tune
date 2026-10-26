import 'dart:async';

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
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/favorite_button.dart';
import 'package:tune/shared/ui/icon_glyph.dart';

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

  Widget app({
    required Widget home,
    required List<Song> songs,
    PlaybackController? playback,
    LibraryController? library,
  }) {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        audioPlayerServiceProvider.overrideWithValue(audio),
        libraryControllerProvider.overrideWith(
          () => library ?? FakeLibraryController(LibraryState(songs: songs)),
        ),
        musicSourcesControllerProvider.overrideWith(
          () => FakeMusicSourcesController(const MusicSourcesState()),
        ),
        playbackControllerProvider.overrideWith(
          (ref) =>
              playback ??
              PlaybackController(
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
    expect(_mark(Icons.favorite_border_rounded), findsNWidgets(2));
    expect(_mark(Icons.favorite_rounded), findsNothing);

    await tester.tap(find.byType(FavoriteButton).first);
    await tester.pumpAndSettle();

    expect(_mark(Icons.favorite_rounded), findsOneWidget);
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

  testWidgets('a double click on a favorite keeps the mark', (tester) async {
    await tester.pumpWidget(
      app(home: const FavoritesPane(), songs: const [songA]),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(songA.uri);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.text('Alpha'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(
      container.read(favoritesControllerProvider).contains(songA.uri),
      isTrue,
      reason: 'a double click may add a mark but never takes one away',
    );
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('a double click on a heart does not take two marks away', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: const FavoritesPane(), songs: const [songA, songB]),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    final controller = container.read(favoritesControllerProvider.notifier);
    await controller.toggle(songA.uri);
    await controller.toggle(songB.uri);
    await tester.pumpAndSettle();
    expect(find.byType(FavoriteButton), findsNWidgets(2));

    final heart = tester.getCenter(find.byType(FavoriteButton).first);
    await tester.tapAt(heart);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(heart);
    await tester.pumpAndSettle();

    final favorites = container.read(favoritesControllerProvider);
    // The first click takes Alpha away; the second click must not land on
    // Beta, which moved up under the pointer.
    expect(favorites.contains(songA.uri), isFalse);
    expect(
      favorites.contains(songB.uri),
      isTrue,
      reason: 'a double click on one heart may not remove the next track',
    );
  });

  test('two marks in a row both reach the store', () async {
    final store = _LateFirstWritePersistence();
    final container = ProviderContainer(
      overrides: [persistenceServiceProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final controller = container.read(favoritesControllerProvider.notifier);
    // The second mark is written while the first one is still on its way.
    await Future.wait([
      controller.toggle(songA.uri),
      controller.toggle(songB.uri),
    ]);

    expect(container.read(favoritesControllerProvider).count, 2);
    expect(store.getStringList(FavoritesStore.key), [
      songA.uri,
      songB.uri,
    ], reason: 'the newer write lands on top of the older one');
  });

  testWidgets('the page says how many marks are not in the library', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: const FavoritesPane(), songs: const [songA]),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    // A track the library does not hold: marked from the online search and
    // never scanned, or its source is off now.
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(songB.uri);
    await tester.pumpAndSettle();

    // The empty state must not claim there is nothing marked.
    expect(find.text('还没有喜欢的曲子'), findsNothing);
    expect(find.text('标过的歌不在音乐库里'), findsOneWidget);
    // The count is the number of marks, not the number of listed tracks.
    expect(find.text('1 首'), findsOneWidget);
  });

  testWidgets('the page counts the marks that are not in the library', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: const FavoritesPane(), songs: const [songA, songB]),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    final controller = container.read(favoritesControllerProvider.notifier);
    await controller.toggle(songA.uri);
    await controller.toggle('/music/gone.mp3');
    await tester.pumpAndSettle();

    expect(find.text('2 首'), findsOneWidget);
    expect(find.text('另有 1 首标过，但不在音乐库里'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('the page says nothing about the library while it loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: const FavoritesPane(),
        songs: const [],
        library: _LoadingLibraryController(),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FavoritesPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle(songA.uri);
    await tester.pump();

    // The library did not load yet, so the page may not say that the mark
    // is outside of it.
    expect(find.text('另有 1 首标过，但不在音乐库里'), findsNothing);
    expect(find.text('1 首'), findsOneWidget);
  });

  testWidgets('the card at the bottom marks the track that is playing', (
    tester,
  ) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([songA]);

    await tester.pumpWidget(
      app(home: const PlayerDock(), songs: const [songA], playback: playback),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerDock)),
    );
    expect(
      container.read(favoritesControllerProvider).contains(songA.uri),
      isTrue,
      reason: 'the card at the bottom marks the track that is playing',
    );
  });
}

/// A library that is still loading and knows no track yet.
class _LoadingLibraryController extends LibraryController {
  @override
  Future<LibraryState> build() => Completer<LibraryState>().future;
}

/// A store that answers the first write late.
///
/// The delay lets a second write reach the file first, which is how the
/// order of the writes gets checked.
class _LateFirstWritePersistence extends FakePersistenceService {
  int _writes = 0;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _writes++;
    if (_writes == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    return super.setStringList(key, value);
  }
}

Finder _mark(IconData icon) {
  return find.byWidgetPredicate(
    (widget) => widget is IconGlyph && widget.icon == icon,
  );
}
