import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_header.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/queue/presentation/queue_track_row.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';

import 'package:tune/shared/ui/artwork_thumb.dart';
import 'package:tune/shared/ui/page_heading.dart';

import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

/// The layout of the shell has to hold together at any size.
///
/// The tests below pin the places where a drift would show: the transport of
/// the dock has to sit on the middle of it, the library and the queue have to
/// write a track in the same columns, and the pages have to share one left
/// edge.
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

  late FakePersistenceService persistence;
  late FakeAudioPlayerService audio;
  late PlaybackController playback;

  setUpAll(() async {
    persistence = FakePersistenceService();
  });

  setUp(() async {
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([songA, songB, songC]);
  });

  tearDown(() => audio.dispose());

  Future<void> surface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({required Widget home}) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        audioPlayerServiceProvider.overrideWithValue(audio),
        // The settings ask the desktop whether Tune is the default player;
        // the real service would shell out to the desktop of the machine
        // the tests run on.
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        playbackControllerProvider.overrideWith((ref) => playback),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(
            const LibraryState(songs: [songA, songB, songC]),
          ),
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

  testWidgets('the play button of the dock sits on the middle of it', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));
    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/library',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    final dock = tester.getRect(find.byType(PlayerDock));
    final play = tester.getRect(
      find.descendant(
        of: find.byType(PlayerDock),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.play_arrow_rounded ||
                  widget.icon == Icons.pause_rounded),
        ),
      ),
    );

    expect(
      play.center.dx,
      moreOrLessEquals(dock.center.dx, epsilon: 0.5),
      reason: 'the play button has to stand on the centre of the dock',
    );
  });

  testWidgets('the queue panel keeps its rows inside its card', (tester) async {
    await surface(tester, const Size(1280, 800));

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/library',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.queue_music_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final panel = tester.getRect(find.byType(QueuePanel));
    final row = tester.getRect(find.byType(QueueTrackRow).first);

    expect(
      panel.width,
      moreOrLessEquals(CompactTokens.sidePanelWidthMax),
      reason: 'the panel keeps its readable measure on a wide page',
    );
    expect(
      panel.right,
      moreOrLessEquals(1280 - CompactTokens.sidePanelGutter),
      reason: 'the panel keeps the same gutter from the window edge',
    );
    expect(
      row.left,
      greaterThanOrEqualTo(panel.left),
      reason: 'a row may not run out of the card',
    );
    expect(
      row.right,
      lessThanOrEqualTo(panel.right),
      reason: 'a row may not run out of the card',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the heading and the list of a page share one left edge', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pump();
    final libraryHeading = tester.getRect(
      find.descendant(
        of: find.byType(LibraryPane),
        matching: find.byType(LibraryHeader),
      ),
    );
    final libraryCard = tester.getRect(find.byType(LibraryTrackCard).first);

    expect(
      libraryCard.left,
      moreOrLessEquals(libraryHeading.left, epsilon: 0.5),
      reason: 'the list has to start where the heading starts',
    );
  });

  testWidgets('the rows of the library stand next to each other', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pump();

    final first = tester.getRect(find.byType(LibraryTrackCard).at(0));
    final second = tester.getRect(find.byType(LibraryTrackCard).at(1));

    expect(
      second.top,
      moreOrLessEquals(first.bottom, epsilon: 0.5),
      reason:
          'a card around every track puts a gutter between two tracks, and the '
          'gutter is a track the reader cannot see',
    );
  });

  testWidgets('the now playing page keeps its block in the middle', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));
    await tester.pumpWidget(app(home: const NowPlayingPage()));
    await tester.pump();

    final page = tester.getRect(find.byType(NowPlayingPage));
    // The cover and the text are one block, so the block itself has to sit
    // in the middle of the page.
    final block = tester.getRect(
      find
          .descendant(of: find.byType(Center), matching: find.byType(Row))
          .first,
    );
    final artwork = tester.getRect(find.byType(ArtworkThumb).first);

    expect(
      block.center.dx,
      moreOrLessEquals(page.center.dx, epsilon: 1),
      reason: 'the cover and the text have to stand in the middle of the page',
    );
    expect(
      artwork.left,
      moreOrLessEquals(block.left, epsilon: 1),
      reason: 'the cover opens the block of the page',
    );
  });

  testWidgets('every page starts its content at the same place', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));
    final lefts = <double>[];

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pump();
    lefts.add(
      tester
          .getRect(
            find
                .descendant(
                  of: find.byType(LibraryPane),
                  matching: find.byType(LibraryHeader),
                )
                .first,
          )
          .left,
    );

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/sources', child: SourcesPane()),
      ),
    );
    await tester.pump();
    lefts.add(
      tester
          .getRect(
            find
                .descendant(
                  of: find.byType(SourcesPane),
                  matching: find.byType(PageHeading),
                )
                .first,
          )
          .left,
    );

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/settings',
          child: SettingsPane(),
        ),
      ),
    );
    await tester.pump();
    lefts.add(tester.getRect(find.byType(SettingsPageHeader).first).left);

    for (final left in lefts) {
      expect(
        left,
        moreOrLessEquals(
          CompactTokens.sidebarWidth + CompactTokens.pageGutter,
          epsilon: 0.5,
        ),
        reason: 'every page of the shell starts at the same place',
      );
    }
  });

  testWidgets('the search field of the library keeps a readable width', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));
    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pump();

    final field = tester.getRect(find.byType(TextField).first);

    expect(
      field.width,
      lessThanOrEqualTo(CompactTokens.searchFieldMaxWidth),
      reason: 'the field of the search must not stretch into a thin ribbon',
    );
    expect(
      field.left,
      moreOrLessEquals(
        CompactTokens.sidebarWidth + CompactTokens.pageGutter,
        epsilon: 1,
      ),
      reason:
          'the field of the search starts where the heading of the page starts',
    );
  });
}
