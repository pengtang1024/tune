import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/queue/presentation/queue_track_row.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/source_badge.dart';
import '../services/fake_persistence.dart';

import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

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

  late FakePersistenceService persistence;

  setUpAll(() async {
    persistence = FakePersistenceService();
  });

  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// The row of the library that shows [title].
  ///
  /// The player bar shows the title of the track that plays, so a plain text
  /// finder finds the title twice as soon as a track plays.
  Finder libraryRowOf(String title) {
    return find.descendant(
      of: find.byType(LibraryTrackCard),
      matching: find.text(title),
    );
  }

  Widget app({
    required Widget home,
    required List<Override> overrides,
    Locale locale = const Locale('zh', 'CN'),
  }) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        ...overrides,
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  /// Pumps the shell, fills the queue and opens the queue panel from the dock.
  Future<PlaybackController> pumpQueuePanel(
    WidgetTester tester, {
    required Size size,
    List<Song> songs = const [songA, songB, songC],
    Widget child = const SizedBox.shrink(),
    Locale locale = const Locale('zh', 'CN'),
  }) async {
    await setSurface(tester, size);
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    if (songs.isNotEmpty) {
      await controller.playQueue(songs);
    }

    await tester.pumpWidget(
      app(
        home: CompactShell(currentPath: '/library', child: child),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => controller),
        ],
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.queue_music_rounded),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
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
          currentPath: '/library',
          child: SizedBox.shrink(),
        ),
        overrides: [audioPlayerServiceProvider.overrideWithValue(audio)],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('音乐库'), findsOneWidget);
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

  testWidgets('library track click plays the track it picked', (tester) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );

    await tester.tap(libraryRowOf(songB.title));
    await tester.pumpAndSettle();

    final state = container.read(playbackControllerProvider);
    expect(state.queue.map((song) => song.uri), [songB.uri]);
    expect(state.currentSong?.uri, songB.uri);
    expect(audio.playedSong?.uri, songB.uri);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library track click keeps the queue that is already there', (
    tester,
  ) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    container.read(playbackControllerProvider.notifier).addToQueue(songA);

    await tester.tap(libraryRowOf(songB.title));
    await tester.pumpAndSettle();

    final state = container.read(playbackControllerProvider);
    expect(state.queue.map((song) => song.uri), [songA.uri, songB.uri]);
    expect(state.currentSong?.uri, songB.uri);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library double click likes the track and plays it', (
    tester,
  ) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );

    await tester.tap(libraryRowOf(songB.title));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(libraryRowOf(songB.title));
    await tester.pumpAndSettle();

    expect(
      container.read(favoritesControllerProvider).contains(songB.uri),
      isTrue,
    );
    final playback = container.read(playbackControllerProvider);
    expect(playback.queue.map((song) => song.uri), [songB.uri]);
    expect(playback.currentSong?.uri, songB.uri);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library single click plays the track right away', (
    tester,
  ) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );

    await tester.tap(libraryRowOf(songB.title));
    await tester.pump();

    // The click plays the track without waiting for a second click.
    final playback = container.read(playbackControllerProvider);
    expect(playback.queue.map((song) => song.uri), [songB.uri]);
    expect(playback.currentSong?.uri, songB.uri);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library double click only likes the track when asked for it', (
    tester,
  ) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    final settings = container.read(settingsControllerProvider.notifier);
    await settings.setOnlyLikeOnDoubleClick(true);
    await tester.pump();

    await tester.tap(libraryRowOf(songC.title));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(libraryRowOf(songC.title));
    await tester.pumpAndSettle();

    expect(
      container.read(favoritesControllerProvider).contains(songC.uri),
      isTrue,
    );
    expect(container.read(playbackControllerProvider).queue, isEmpty);
    expect(tester.takeException(), isNull);

    await settings.setOnlyLikeOnDoubleClick(false);
  });

  testWidgets('library queue all button adds the whole visible list', (
    tester,
  ) async {
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
              const LibraryState(songs: [songA, songB, songC]),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );

    await tester.tap(find.byTooltip('将整个列表加入队列'));
    await tester.pumpAndSettle();

    final state = container.read(playbackControllerProvider);
    expect(state.queue.map((song) => song.uri), [
      songA.uri,
      songB.uri,
      songC.uri,
    ]);
    expect(state.currentSong?.uri, songA.uri);
    expect(tester.takeException(), isNull);
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
    expect(find.byTooltip('Openverse · 开放版权聚合'), findsOneWidget);
    // The mark of the source is an icon: the name of the source waits in the
    // tooltip, so the row keeps its shape whatever the source is called.
    expect(find.byType(SourceBadge), findsOneWidget);

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

  testWidgets('queue panel opens from the dock and leaves the dock usable', (
    tester,
  ) async {
    final controller = await pumpQueuePanel(
      tester,
      size: const Size(900, 563),
      child: const Center(child: Text('library page')),
    );

    expect(find.byType(QueuePanel), findsOneWidget);
    expect(find.text('library page'), findsOneWidget);

    // The panel covers the page but not the dock. A reader can pause while
    // looking at the queue, which is the reason the panel is not a route.
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.pause_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.state.isPlaying, isFalse);
    expect(find.byType(QueuePanel), findsOneWidget);

    // The same button closes the panel.
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.queue_music_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QueuePanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel lays out its rows at 760x483', (tester) async {
    await pumpQueuePanel(tester, size: const Size(760, 483));

    expect(tester.takeException(), isNull);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('播放队列'), findsOneWidget);
    // The content area is 564 wide, so the panel fills it and keeps the same
    // gutter on both sides.
    expect(
      tester.getRect(find.byType(QueuePanel)).width,
      moreOrLessEquals(540),
    );
  });

  testWidgets('queue panel rows show the remote source name', (tester) async {
    await pumpQueuePanel(
      tester,
      size: const Size(760, 483),
      songs: const [remoteSong],
    );

    expect(
      find.descendant(
        of: find.byType(QueuePanel),
        matching: find.text(remoteSong.title),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Openverse · 开放版权聚合'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QueuePanel),
        matching: find.byType(SourceBadge),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel shows its empty state', (tester) async {
    await pumpQueuePanel(tester, size: const Size(760, 483), songs: const []);

    expect(find.byType(QueuePanel), findsOneWidget);
    expect(find.text('播放队列是空的'), findsOneWidget);
    expect(find.text('去音乐库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel tolerates 1.3 text scaling at 760x483', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpQueuePanel(tester, size: const Size(760, 483));

    expect(find.byType(QueuePanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel tolerates 1.3 text scaling in English at 900x600', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpQueuePanel(
      tester,
      size: const Size(900, 600),
      locale: const Locale('en'),
    );

    expect(find.byType(QueuePanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel closes with escape, the page or back', (
    tester,
  ) async {
    await pumpQueuePanel(tester, size: const Size(900, 563));
    expect(find.byType(QueuePanel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.queue_music_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsOneWidget);

    // The scrim covers the page but not the sidebar or the dock.
    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);

    // The system back action closes the panel before it leaves the shell.
    await tester.tap(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byIcon(Icons.queue_music_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queue panel keeps the queue operations', (tester) async {
    final controller = await pumpQueuePanel(tester, size: const Size(900, 563));

    // Play a row from the panel.
    await tester.tap(
      find.descendant(of: find.byType(QueuePanel), matching: find.text('Beta')),
    );
    await tester.pumpAndSettle();
    expect(controller.state.currentSong?.uri, songB.uri);

    final betaRow = find.ancestor(
      of: find.descendant(
        of: find.byType(QueuePanel),
        matching: find.text('Beta'),
      ),
      matching: find.byType(QueueTrackRow),
    );

    // Mark a row. Another test may have marked this track already, so the
    // direction of the mark is read from the state instead of assumed.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QueuePanel)),
    );
    final wasFavorite = container
        .read(favoritesControllerProvider)
        .contains(songB.uri);
    await tester.tap(
      find.descendant(
        of: betaRow,
        matching: find.byTooltip(wasFavorite ? '取消收藏' : '加入收藏'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(favoritesControllerProvider).contains(songB.uri),
      isNot(wasFavorite),
    );

    // Remove a row.
    final gammaRow = find.ancestor(
      of: find.descendant(
        of: find.byType(QueuePanel),
        matching: find.text('Gamma'),
      ),
      matching: find.byType(QueueTrackRow),
    );
    await tester.tap(
      find.descendant(of: gammaRow, matching: find.byTooltip('移除')),
    );
    await tester.pumpAndSettle();
    expect(controller.state.queue.map((song) => song.uri), [
      songA.uri,
      songB.uri,
    ]);

    // Empty the queue through the confirmation of the header.
    await tester.tap(
      find.descendant(of: find.byType(QueuePanel), matching: find.text('清空')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '清空'));
    await tester.pumpAndSettle();

    expect(controller.state.queue, isEmpty);
    expect(find.text('播放队列是空的'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the queue panel of the now playing page closes back to it', (
    tester,
  ) async {
    await setSurface(tester, const Size(900, 600));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await controller.playQueue([songA, songB]);

    await tester.pumpWidget(
      app(
        home: NowPlayingPage(
          queuePanelBuilder: (context, onClose) => QueuePanel(onClose: onClose),
        ),
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => controller),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('播放队列'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsOneWidget);
    expect(find.byType(NowPlayingPage), findsOneWidget);

    // Escape closes the panel, not the full view.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);
    expect(find.byType(NowPlayingPage), findsOneWidget);

    // The close action of the panel does the same.
    await tester.tap(find.byTooltip('播放队列'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);
    expect(find.byType(NowPlayingPage), findsOneWidget);

    // The system back action closes the panel first as well.
    await tester.tap(find.byTooltip('播放队列'));
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QueuePanel), findsNothing);
    expect(find.byType(NowPlayingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings pane tolerates 1.3 text scaling at 760x483', (
    tester,
  ) async {
    await setSurface(tester, const Size(760, 483));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
    // The page writes its title in the language of the interface, so the
    // heading and the entry of the sidebar carry the same word.
    expect(find.text('设置'), findsNWidgets(2));
    expect(find.text('偏好'), findsOneWidget);
    // The card names the library once: the eyebrow names the section the
    // card belongs to, so only the sidebar and the title carry the word.
    expect(find.text('音乐库'), findsNWidgets(2));
    expect(find.text('收藏'), findsNWidgets(2));
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

  testWidgets('settings playback card switches the click behavior', (
    tester,
  ) async {
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
      container.read(settingsControllerProvider).replaceQueueOnClick,
      isFalse,
    );
    expect(find.text('单击歌曲时替换播放队列'), findsOneWidget);

    final row = find
        .ancestor(of: find.text('单击歌曲时替换播放队列'), matching: find.byType(Row))
        .first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsControllerProvider).replaceQueueOnClick,
      isTrue,
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
