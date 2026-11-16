import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';

import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';

/// A library of one kind is read in two levels: rows that name a group, and
/// the tracks of the row the reader opened. Opening is a click on the row;
/// going back is the first row of the list, not a button in the heading.
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

  /// Episodes of one show, as a podcast source writes them.
  const episodes = [
    Song(
      id: 11,
      title: 'Episode 1',
      album: 'The Show',
      sourceId: 'podcast_rss-1',
      duration: 1800000,
      uri: 'tune://podcast/1',
    ),
    Song(
      id: 12,
      title: 'Episode 2',
      album: 'The Show',
      sourceId: 'podcast_rss-1',
      duration: 1800000,
      uri: 'tune://podcast/2',
    ),
  ];

  /// Chapters of one book, as an audiobook source writes them.
  const chapters = [
    Song(
      id: 21,
      title: 'Chapter 1',
      album: 'The Book',
      sourceId: 'librivox',
      duration: 600000,
      uri: 'tune://librivox/1',
    ),
    Song(
      id: 22,
      title: 'Chapter 2',
      album: 'The Book',
      sourceId: 'librivox',
      duration: 600000,
      uri: 'tune://librivox/2',
    ),
  ];

  Widget app({
    required Widget home,
    List<Song> librarySongs = songs,
    LibraryFilter filter = LibraryFilter.songs,
    FakeLibraryController Function(LibraryState state)? controller,
  }) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
        libraryControllerProvider.overrideWith(
          () => controller?.call(
                LibraryState(songs: librarySongs, filter: filter),
              ) ??
              FakeLibraryController(
                LibraryState(songs: librarySongs, filter: filter),
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

  void sizeOf(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('the library opens on one row per album', (tester) async {
    sizeOf(tester, const Size(900, 563));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    // 一首曲子一行是「五条同样的信息」；一张专辑一行才是一条信息。
    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Artist A'), findsOneWidget);
    expect(find.text('2 首'), findsOneWidget);
    expect(find.text('1 首'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);
    expect(find.text('Album A second'), findsNothing);
  });

  testWidgets('a group row opens the tracks, the first row leads back', (
    tester,
  ) async {
    sizeOf(tester, const Size(900, 563));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Album A'));
    await tester.pumpAndSettle();

    expect(find.text('Album A first'), findsOneWidget);
    expect(find.text('Album A second'), findsOneWidget);
    expect(find.text('Album B first'), findsNothing);
    expect(find.byKey(const ValueKey('library-group-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-group-back')));
    await tester.pumpAndSettle();

    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each kind counts its own unit', (tester) async {
    sizeOf(tester, const Size(900, 563));

    Future<void> pumpKind(
      List<Song> librarySongs,
      ContentKind kind,
      String count,
    ) async {
      await tester.pumpWidget(
        app(
          home: const CompactShell(
            currentPath: '/library',
            child: LibraryPane(),
          ),
          librarySongs: librarySongs,
          filter: LibraryFilter(kinds: {kind}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(count), findsOneWidget);
    }

    await pumpKind(episodes, ContentKind.podcast, '2 集');
    // 一个 ProviderScope 的 override 不能换掉它已经建好的控制器：
    // 拆掉作用域再挂下一类，否则第二页读的还是上一页的库。
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpKind(chapters, ContentKind.audiobook, '2 章');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row brings its own tracks, so it never opens blank', (
    tester,
  ) async {
    sizeOf(tester, const Size(1120, 760));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        // This controller answers nothing for an album key: the rows still
        // open, because a row carries the tracks it was built from.
        controller: _EmptyAlbumController.new,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Album A').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-group-back')), findsOneWidget);
    expect(find.text('Album A first'), findsOneWidget);
  });
}

/// A library whose album rows hold no tracks: the row still names the album,
/// but opening it would show a page with nothing on it.
class _EmptyAlbumController extends FakeLibraryController {
  _EmptyAlbumController(super.seed);

  @override
  Future<List<Song>> albumSongs(String key) async => const [];
}
