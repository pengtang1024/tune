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
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_group_rows.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
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
    FakeAudioPlayerService? audio,
  }) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(
          audio ?? FakeAudioPlayerService(),
        ),
        libraryControllerProvider.overrideWith(
          () =>
              controller?.call(
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

  testWidgets('one-track albums gather into a single row', (tester) async {
    sizeOf(tester, const Size(900, 563));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    // 两首以上的专辑仍是一行组：信息收在一条里，点进去才看曲目。
    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('2 首'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);

    // 只有一首的专辑不是一张专辑可浏览：它们聚成一行，列表不再逐条铺开。
    expect(find.text('单曲'), findsOneWidget);
    expect(find.text('1 首'), findsOneWidget);
    expect(find.text('Album B first'), findsNothing);
    expect(find.byType(LibraryTrackCard), findsNothing);

    final list = tester.widget<ListView>(
      find.descendant(
        of: find.byType(LibraryGroupRows),
        matching: find.byType(ListView),
      ),
    );
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.addAutomaticKeepAlives, isFalse);
  });

  testWidgets('the gathered row opens its tracks instead of playing', (
    tester,
  ) async {
    sizeOf(tester, const Size(1120, 760));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('单曲'));
    await tester.pumpAndSettle();

    // 点它只是打开这一组，不播放；内页有返回行。
    expect(audio.playedSong, isNull);
    expect(find.text('Album B first'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-group-back')), findsOneWidget);
  });

  testWidgets('a double click marks a track of the gathered row', (
    tester,
  ) async {
    sizeOf(tester, const Size(1120, 760));
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('单曲'));
    await tester.pumpAndSettle();

    // 双击的第二下是收藏；这套语义只有一份实现。
    await tester.tap(find.byType(LibraryTrackCard));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(LibraryTrackCard));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    expect(
      container.read(favoritesControllerProvider).contains('/music/b1.mp3'),
      isTrue,
    );
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

    // 一首的那张专辑在「单曲」组里，回到列表时不会直接铺出来。
    expect(find.text('单曲'), findsOneWidget);
    expect(find.text('Album B first'), findsNothing);
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

  testWidgets('a row does not write its artist twice', (tester) async {
    sizeOf(tester, const Size(1120, 760));

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
        controller: _SameNameController.new,
      ),
    );
    await tester.pumpAndSettle();

    // The album names itself after its artist: one line, not two. The
    // tooltip repeats the name for pointers, so only the row's own text
    // counts here.
    expect(
      find.descendant(
        of: find.byType(LibraryGroupRows),
        matching: find.text('0114 Ligaya'),
      ),
      findsOneWidget,
    );
  });
}

/// A library whose album rows hold no tracks: the row still names the album,
/// but opening it would show a page with nothing on it.
class _EmptyAlbumController extends FakeLibraryController {
  _EmptyAlbumController(super.seed);

  @override
  Future<List<Song>> albumSongs(String key) async => const [];
}

/// A library whose one album carries the same words as its artist.
///
/// The album has two tracks, so it stays a group row: a one-track group is
/// drawn as a track row, and a track row writes its artist and album.
const _sameNameSeed = LibraryState(
  filter: LibraryFilter.songs,
  songs: [
    Song(
      id: 1,
      uri: 'tune://internet_archive/ligaya',
      title: 'Ligaya',
      artist: '0114 Ligaya',
      album: '0114 Ligaya',
      duration: 200000,
      sourceId: 'community_music',
    ),
    Song(
      id: 2,
      uri: 'tune://internet_archive/ligaya-2',
      title: 'Sa Aking Puso',
      artist: '0114 Ligaya',
      album: '0114 Ligaya',
      duration: 210000,
      sourceId: 'community_music',
    ),
  ],
  total: 2,
);

class _SameNameController extends FakeLibraryController {
  // The seed is the one this test needs, not the helper's default list.
  // ignore: unused_element_parameter
  _SameNameController(LibraryState seed) : super(_sameNameSeed);
}
