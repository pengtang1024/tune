import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/meta_badge.dart';
import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';

import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';

void main() {
  const songs = [
    Song(
      id: 1,
      title: 'Album A first',
      artist: 'Artist A',
      album: 'Album A',
      trackNumber: 1,
      duration: 60000,
      uri: '/music/a1.mp3',
    ),
    Song(
      id: 2,
      title: 'Album A second',
      artist: 'Artist A',
      album: 'Album A',
      trackNumber: 2,
      duration: 60000,
      uri: '/music/a2.mp3',
    ),
    Song(
      id: 3,
      title: 'Album B first',
      artist: 'Artist B',
      album: 'Album B',
      trackNumber: 1,
      duration: 60000,
      uri: '/music/b1.mp3',
    ),
  ];

  Widget app({required Widget home, List<Song> librarySongs = songs}) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(LibraryState(songs: librarySongs)),
        ),
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

  testWidgets('the library opens an album from the cover grid', (tester) async {
    tester.view.physicalSize = const Size(900, 563);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);

    await tester.tap(find.text('Album A'));
    await tester.pumpAndSettle();

    expect(find.text('Album A first'), findsOneWidget);
    expect(find.text('Album A second'), findsOneWidget);
    expect(find.text('Album B first'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the album of the playing track carries the playback mark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 563);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    await container
        .read(playbackControllerProvider.notifier)
        .playQueue([songs.first]);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one kind of album needs no section header', (tester) async {
    tester.view.physicalSize = const Size(900, 563);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('音乐 · '), findsNothing);
    expect(find.text('Album A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('songs, shows and books stand in three sections', (
    tester,
  ) async {
    const mixed = [
      Song(
        id: 1,
        title: 'Song',
        artist: 'Artist',
        album: 'Record',
        duration: 1000,
        uri: '/music/1.mp3',
      ),
      Song(
        id: 2,
        title: 'Episode 1',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        uri: 'tune://podcast/1',
      ),
      Song(
        id: 3,
        title: 'Episode 2',
        album: 'The Show',
        sourceId: 'podcast_rss-1',
        uri: 'tune://podcast/2',
      ),
      Song(
        id: 4,
        title: 'Chapter 1',
        album: 'The Book',
        sourceId: 'librivox',
        uri: 'tune://librivox/1',
      ),
    ];
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        librarySongs: mixed,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('音乐 · 1'), findsOneWidget);
    expect(find.text('播客 · 1'), findsOneWidget);
    expect(find.text('有声书 · 1'), findsOneWidget);
    expect(find.text('1 首'), findsOneWidget);
    expect(find.text('2 集'), findsOneWidget);
    expect(find.text('1 章'), findsOneWidget);
    expect(find.byType(MetaBadge), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
