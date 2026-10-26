import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/presentation/discovery_pane.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
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

void main() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final songs = [
    for (var index = 0; index < 30; index++)
      Song(
        id: index,
        title: 'Song $index',
        artist: index < 6 ? 'Nujabes' : 'Artist $index',
        album: 'Album $index',
        uri: '/music/$index.mp3',
        dateAdded: now,
      ),
  ];

  late FakePersistenceService persistence;
  late FakeAudioPlayerService audio;
  late PlaybackController playback;

  setUp(() {
    persistence = FakePersistenceService();
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
  });

  tearDown(() {
    audio.dispose();
  });

  Widget app({List<Song> library = const []}) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        audioPlayerServiceProvider.overrideWithValue(audio),
        playbackControllerProvider.overrideWith((ref) => playback),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: library)),
        ),
        musicSourcesControllerProvider.overrideWith(
          () => FakeMusicSourcesController(
            MusicSourcesState(sources: BuiltInMusicSources.defaults),
          ),
        ),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DiscoveryPane()),
      ),
    );
  }

  testWidgets('the page shows a mix and a card section', (tester) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discovery-daily-mix')), findsOneWidget);
    expect(find.text('今日混音'), findsOneWidget);
    expect(find.text('Nujabes'), findsWidgets);
    expect(find.byIcon(Icons.more_horiz_rounded), findsWidgets);
  });

  testWidgets('the mix can be played and queued', (tester) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('discovery-daily-play')));
    await tester.pumpAndSettle();
    expect(playback.state.queue, isNotEmpty);

    playback.clearQueue();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discovery-daily-queue')));
    await tester.pumpAndSettle();
    expect(playback.state.queue, isNotEmpty);
  });

  testWidgets('a card marks the track as a favorite', (tester) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    final heart = find.byType(FavoriteButton).first;
    await tester.tap(heart);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoveryPane)),
    );
    expect(container.read(favoritesControllerProvider).count, 1);
  });

  testWidgets('a card can be dismissed and the undo brings it back', (
    tester,
  ) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    final cardSection = find.byKey(const ValueKey('discovery-section-fresh'));
    expect(cardSection, findsOneWidget);
    final menu = find.descendant(
      of: cardSection,
      matching: find.byIcon(Icons.more_horiz_rounded),
    );
    await tester.tap(menu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('不感兴趣').last);
    await tester.pumpAndSettle();

    expect(find.text('撤销'), findsOneWidget);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(find.text('撤销'), findsNothing);
  });

  testWidgets('the why sheet explains where the picks come from', (
    tester,
  ) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('discovery-why')));
    await tester.pumpAndSettle();

    expect(find.text('推荐怎么来的'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
  });

  testWidgets('an empty library offers a scan and a source', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('音乐库还是空的'), findsOneWidget);
    expect(find.byKey(const ValueKey('discovery-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('discovery-sources')), findsOneWidget);
  });

  testWidgets('the page fits the compact window at 1.3 text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('discovery-daily-mix')), findsOneWidget);
  });

  testWidgets('a shelf reaches its tail with the arrow at the compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = [
      for (var index = 0; index < 80; index++)
        Song(
          id: index,
          title: 'Song $index',
          artist: index < 6 ? 'Nujabes' : 'Artist $index',
          album: 'Album $index',
          uri: '/music/$index.mp3',
          dateAdded: now,
        ),
    ];
    await tester.pumpWidget(app(library: library));
    await tester.pumpAndSettle();

    final section = find.byKey(const ValueKey('discovery-section-fresh'));
    final shelf = find.byKey(const ValueKey('discovery-list-fresh'));
    await tester.ensureVisible(shelf);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: shelf, matching: find.byType(Scrollable)).first,
    );
    final forward = find.descendant(
      of: section,
      matching: find.byKey(const ValueKey('horizontal-shelf-forward')),
    );
    expect(forward, findsOneWidget);
    await tester.tap(forward);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('the page offers to turn on local listening history', (
    tester,
  ) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoveryPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/0.mp3');
    await tester.pumpAndSettle();

    expect(find.text('开启本地播放记录，推荐会更贴近你'), findsOneWidget);
    await tester.tap(find.text('开启'));
    await tester.pumpAndSettle();

    expect(find.text('开启本地播放记录，推荐会更贴近你'), findsNothing);
    expect(
      container.read(settingsControllerProvider).useListeningHistory,
      isTrue,
    );
  });

  testWidgets('an artist shelf offers an explicit online lookup', (
    tester,
  ) async {
    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoveryPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/0.mp3');
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/1.mp3');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('discovery-find-more-artist')),
      findsOneWidget,
    );
  });

  testWidgets('an artist shelf fits the compact window', (tester) async {
    tester.view.physicalSize = const Size(760, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(app(library: songs));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoveryPane)),
    );
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/0.mp3');
    await container
        .read(favoritesControllerProvider.notifier)
        .mark('/music/1.mp3');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('discovery-find-more-artist')),
      findsOneWidget,
    );
  });
}
