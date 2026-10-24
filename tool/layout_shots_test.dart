// Layout screenshot harness (development tool, not part of the test suite).
//
// Run with:
//   flutter test tool/layout_shots_test.dart
//
// Writes one PNG per page to `build/layout-shots/` so the layout can be
// compared before and after a change.
import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/discovery/presentation/discovery_pane.dart';
import 'package:tune/features/favorites/presentation/favorites_pane.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/search/presentation/online_search_sheet.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../test/services/fake_persistence.dart';
import 'package:tune/shared/ui/track_detail_sheet.dart';

import '../test/app/fake_audio_player_service.dart';
import '../test/app/fake_song_download_service.dart';
import '../test/app/fake_stream_url_resolver.dart';

const _songs = [
  Song(
    id: 1,
    title: 'Nocturne in E-flat major, Op. 9 No. 2',
    artist: 'A rather long artist name that keeps going',
    album: 'Nocturnes',
    duration: 245000,
    uri: '/music/a.mp3',
  ),
  Song(
    id: 2,
    title: 'Beta',
    artist: 'Artist B',
    duration: 120000,
    uri: '/music/b.mp3',
  ),
  Song(
    id: 3,
    title: 'Gamma',
    artist: 'Artist C',
    duration: 90000,
    uri: '/music/c.mp3',
  ),
  Song(
    id: 4,
    title: 'Delta',
    artist: 'Artist D',
    duration: 300000,
    uri: '/music/d.mp3',
  ),
];

final _rootKey = GlobalKey();
List<Override> _overrides = const [];

/// Loads the bundled fonts so the shots show the real type instead of the
/// fallback boxes the test environment would use.
Future<void> _loadFonts() async {
  const families = {
    'Fraunces': 'assets/fonts/Fraunces/Fraunces-Variable.ttf',
    'Instrument Sans':
        'assets/fonts/InstrumentSans/InstrumentSans-Variable.ttf',
    'JetBrains Mono': 'assets/fonts/JetBrainsMono/JetBrainsMono-Regular.ttf',
    'Noto Sans SC': 'assets/fonts/NotoSansSC/NotoSansSC-VF.ttf',
    'Noto Serif SC': 'assets/fonts/NotoSerifSC/NotoSerifSC-VF.ttf',
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        Future.value(File(entry.value).readAsBytesSync().buffer.asByteData()),
      );
    await loader.load();
  }
  // The icon font lives in the Flutter cache, not in the project, so the
  // shots show the real glyphs instead of a box for every icon.
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  // The first pump builds whatever was just pushed, the second one lets the
  // animation of a sheet settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  // `toImage` and the file write are real async work: inside the fake async
  // zone of `testWidgets` they would never complete, so they run outside it.
  await tester.runAsync(() async {
    final boundary =
        _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = (await image.toByteData(
      format: ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final file = File('build/layout-shots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

void main() {
  late FakePersistenceService persistence;

  setUpAll(() async {
    // The harness lives outside `test/`, so the analyzer does not treat this
    // file as a test and refuses the test-only mock. It is a mock here too.
    // ignore: invalid_use_of_visible_for_testing_member
    persistence = FakePersistenceService();
    // The shot of the favorites needs tracks that are marked. One of them is
    // not in the library, so the shot shows what the page says about a mark
    // it cannot name.
    persistence.values['favorite_tracks'] = [
      '/music/a.mp3',
      '/music/c.mp3',
      'tune://demo:1/9',
    ];
    await _loadFonts();
  });

  // The shots have to show the app as it runs, and the app runs on Linux.
  // The test suite pretends to be Android, and Android draws with another
  // density and a padded tap target, so a shot taken without this line
  // shows buttons that are eight pixels taller than the ones a user sees.
  //
  // The override has to be undone inside the body of the test, because the
  // framework checks its own debug variables before the tear down runs.

  Widget app({required Widget home, Brightness brightness = Brightness.light}) {
    return ProviderScope(
      overrides: _overrides,
      child: RepaintBoundary(
        key: _rootKey,
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? CompactTheme.dark
              : CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
  }

  Future<void> surface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> capture(WidgetTester tester, String suffix) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue(_songs);
    // The override set stays the same for every page: Riverpod refuses to
    // add or remove overrides while the scope is alive.
    _overrides = [
      persistenceServiceProvider.overrideWithValue(persistence),
      audioPlayerServiceProvider.overrideWithValue(audio),
      playbackControllerProvider.overrideWith((ref) => playback),
      libraryControllerProvider.overrideWith(
        () => _FakeLibraryController(
          const LibraryState(songs: _songs, statusMessage: '4 首歌曲'),
        ),
      ),
      lyricsControllerProvider.overrideWith(() => _FakeLyricsController()),
    ];

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await _shot(tester, 'library$suffix');

    // The queue is a panel over the library now. The library itself is the
    // page behind it, so the shot shows the reader's context as well.
    await tester.tap(find.byTooltip('播放队列'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'queue_panel$suffix');
    await tester.tap(find.byTooltip('播放队列'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/discover',
          child: DiscoveryPane(),
        ),
      ),
    );
    await _shot(tester, 'discover$suffix');

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/favorites',
          child: FavoritesPane(),
        ),
      ),
    );
    await _shot(tester, 'favorites$suffix');

    await tester.pumpWidget(
      app(
        home: const CompactShell(
          currentPath: '/settings',
          child: SettingsPane(),
        ),
      ),
    );
    await _shot(tester, 'settings$suffix');

    // The playback rules are the first card below the first screen.
    final settingsScroll = find.descendant(
      of: find.byType(SettingsPane),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(settingsScroll, const Offset(0, -480));
    await tester.pumpAndSettle();
    await _shot(tester, 'settings_playback$suffix');

    // The health weights live below the discovery and playback cards.
    final healthAdjust = find.byKey(
      const ValueKey('settings-source-health-adjust'),
    );
    await tester.ensureVisible(healthAdjust);
    await tester.pumpAndSettle();
    await _shot(tester, 'settings_health$suffix');

    await tester.tap(healthAdjust);
    await tester.pumpAndSettle();
    await _shot(tester, 'settings_health_dialog$suffix');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/sources', child: SourcesPane()),
      ),
    );
    await _shot(tester, 'sources$suffix');

    await tester.pumpWidget(
      app(
        home: NowPlayingPage(
          queuePanelBuilder: (context, onClose) =>
              QueuePanel(onClose: onClose, showTransport: true),
        ),
      ),
    );
    await _shot(tester, 'now_playing$suffix');

    // The queue panel is part of the player, so the full view has one too.
    await tester.tap(find.byTooltip('播放队列'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'now_playing_queue$suffix');
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    // The lyrics are a capability of the playing view, not a page of their
    // own: the shot shows what the reader sees after pressing the button.
    await tester.tap(find.byTooltip('歌词'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, 'now_playing_lyrics$suffix');
  }

  /// Captures the sheets that float over the pages.
  Future<void> captureSheets(WidgetTester tester, String suffix) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue(_songs);
    _overrides = [
      persistenceServiceProvider.overrideWithValue(persistence),
      audioPlayerServiceProvider.overrideWithValue(audio),
      playbackControllerProvider.overrideWith((ref) => playback),
      libraryControllerProvider.overrideWith(
        () => _FakeLibraryController(
          const LibraryState(songs: _songs, statusMessage: '4 首歌曲'),
        ),
      ),
      onlineSearchControllerProvider.overrideWith(
        () => _FakeOnlineSearchController(),
      ),
    ];

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pump();
    unawaited(showOnlineSearchSheet(tester.element(find.byType(LibraryPane))));
    await _shot(tester, 'search_sheet$suffix');
  }

  /// Captures the sheet of a track, on its own tree.
  Future<void> captureTrackSheet(WidgetTester tester, String suffix) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue(_songs);
    _overrides = [
      persistenceServiceProvider.overrideWithValue(persistence),
      audioPlayerServiceProvider.overrideWithValue(audio),
      playbackControllerProvider.overrideWith((ref) => playback),
      libraryControllerProvider.overrideWith(
        () => _FakeLibraryController(
          const LibraryState(songs: _songs, statusMessage: '4 首歌曲'),
        ),
      ),
    ];

    await tester.pumpWidget(app(home: const NowPlayingPage()));
    await tester.pump();
    unawaited(
      showTrackDetailSheet(
        tester.element(find.byType(NowPlayingPage)),
        _songs.first,
      ),
    );
    await _shot(tester, 'track_sheet$suffix');
  }

  testWidgets('capture pages', (tester) async {
    await onLinux(() async {
      await surface(tester, const Size(1280, 800));
      await capture(tester, '');
    });
  });

  testWidgets('capture pages in the smallest window', (tester) async {
    await onLinux(() async {
      await surface(tester, const Size(760, 520));
      await capture(tester, '_narrow');
    });
  });

  testWidgets('capture pages in the small window', (tester) async {
    await onLinux(() async {
      await surface(tester, const Size(900, 563));
      await capture(tester, '_small');
    });
  });

  testWidgets('capture the search sheet', (tester) async {
    await onLinux(() async {
      await surface(tester, const Size(1280, 800));
      await captureSheets(tester, '');
    });
  });

  testWidgets('capture the sheet of a track', (tester) async {
    await onLinux(() async {
      await surface(tester, const Size(1280, 800));
      await captureTrackSheet(tester, '');
    });
  });
}

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.seed);

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

/// A lyrics controller that holds a sheet, so the shot shows the lyrics.
class _FakeLyricsController extends LyricsController {
  @override
  Future<LyricsState> build() async {
    return LyricsState(
      songId: 1,
      document: LyricsDocument.parse('''
[ti:Nocturne in E-flat major]
[ar:A rather long artist name that keeps going]
[00:04.00]The night is quiet and the city sleeps
[00:09.50]A melody wanders through the open window
[00:15.00]And the hours pass without a sound
[00:21.25]Until the first light finds the room
[00:27.00]A nocturne in E-flat major, Op. 9 No. 2
'''),
    );
  }
}

/// A search that already found something, so the shot shows a result row.
class _FakeOnlineSearchController extends OnlineSearchController {
  @override
  Future<OnlineSearchState> build() async {
    return OnlineSearchState(
      query: 'jazz',
      results: {
        'demo:1': SourceScanResult(
          sourceId: 'demo:1',
          status: SourceScanStatus.success,
          songs: const [
            Song(
              id: 91,
              title: 'Nocturne in E-flat major, Op. 9 No. 2',
              artist: 'A rather long artist name that keeps going',
              album: 'Nocturnes',
              duration: 245000,
              uri: 'tune://demo:1/91',
            ),
            Song(
              id: 92,
              title: 'Gamma',
              artist: 'Artist C',
              album: 'Night Pieces',
              duration: 90000,
              uri: 'tune://demo:1/92',
            ),
          ],
        ),
      },
    );
  }
}

/// Runs [body] as if the app ran on the desktop.
///
/// The test suite pretends to be Android, and Android draws with another
/// density and a padded tap target, so the numbers taken without this are
/// not the numbers the app paints.
Future<void> onLinux(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
