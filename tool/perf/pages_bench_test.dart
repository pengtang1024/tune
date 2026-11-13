// Benchmarks: what a scan progress tick and a favorite toggle rebuild on the
// pages outside the library list. Run with:
// flutter test tool/perf/pages_bench_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
import 'package:tune/features/favorites/domain/favorites_state.dart';
import 'package:tune/features/favorites/presentation/favorites_pane.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/queue/presentation/queue_panel.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/application/source_health_reports.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../../test/app/fake_audio_player_service.dart';
import '../../test/app/fake_song_download_service.dart';
import '../../test/app/fake_stream_url_resolver.dart';
import '../../test/services/fake_persistence.dart';

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;

  @override
  Future<LibraryState> build() async =>
      LibraryState(songs: songs, total: songs.length);

  void pushProgress(double progress) {
    final current = state.valueOrNull!;
    state = AsyncData(
      current.copyWith(
        scanStatus: LibraryScanStatus.scanning,
        scanProgress: progress,
      ),
    );
  }
}

class _FakeFavorites extends FavoritesController {
  _FakeFavorites(this.initial);

  final Set<String> initial;

  @override
  FavoritesState build() => FavoritesState(ids: Set.unmodifiable(initial));

  void toggleOne(String uri) {
    final ids = Set<String>.of(state.ids);
    if (!ids.remove(uri)) ids.add(uri);
    state = FavoritesState(ids: Set.unmodifiable(ids));
  }
}

class _FakeSources extends MusicSourcesController {
  _FakeSources(this.seed);

  final MusicSourcesState seed;

  @override
  Future<MusicSourcesState> build() async => seed;
}

List<Song> buildLibrary(int count) {
  return [
    for (var i = 0; i < count; i++)
      Song(
        id: i,
        title: 'Track title $i',
        artist: 'Artist ${i % 500}',
        album: 'Album ${i % 900}',
        duration: 200000,
        uri: '/music/track-$i.mp3',
        sourceId: 'source-${i % 12}',
      ),
  ];
}

/// Runs [body] with the desktop surface the app runs on.
Future<void> onDesktop(WidgetTester tester, Future<void> Function() body) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await body();
}

int countRebuilds(List<String> hits) => hits.length;

void main() {
  testWidgets('favorites page: a progress tick and a toggle', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final songs = buildLibrary(20000);
    final library = _FakeLibraryController(songs);
    final favorites = _FakeFavorites({
      for (var i = 0; i < 500; i++) songs[i * 3].uri,
    });
    final hits = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      hits.add(element.widget.runtimeType.toString());
    };

    await onDesktop(tester, () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(audio),
            libraryControllerProvider.overrideWith(() => library),
            favoritesControllerProvider.overrideWith(() => favorites),
          ],
          child: MaterialApp(
            theme: CompactTheme.light,
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: FavoritesPane()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      hits.clear();
      library.pushProgress(0.42);
      await tester.pump();
      final first = countRebuilds(hits);
      hits.clear();

      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        library.pushProgress(0.4 + i * 0.01);
        await tester.pump();
      }
      sw.stop();
      // ignore: avoid_print
      print('favorites page: one progress tick rebuilt $first elements');
      // ignore: avoid_print
      print(
        'favorites page: 20 progress ticks = ${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMicroseconds / 20 / 1000).toStringAsFixed(1)}ms each)',
      );
      hits.clear();

      favorites.toggleOne(songs[0].uri);
      await tester.pump();
      // ignore: avoid_print
      print(
        'favorites page: one favorite toggle rebuilt '
        '${countRebuilds(hits)} elements',
      );
    });

    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('sources page: a progress tick', (tester) async {
    final library = _FakeLibraryController(buildLibrary(20000));
    final sources = _FakeSources(
      MusicSourcesState(
        sources: [
          BuiltInMusicSources.jamendo,
          BuiltInMusicSources.ccmixter,
          BuiltInMusicSources.radio,
          BuiltInMusicSources.subsonic,
          BuiltInMusicSources.jellyfin,
        ],
      ),
    );
    final health = {
      for (final source in sources.seed.sources) source.id: _healthReport(),
    };
    final persistence = FakePersistenceService()..values['language_code'] = 'zh';
    final hits = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      hits.add(element.widget.runtimeType.toString());
    };

    await onDesktop(tester, () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            persistenceServiceProvider.overrideWithValue(persistence),
            musicSourcesControllerProvider.overrideWith(() => sources),
            libraryControllerProvider.overrideWith(() => library),
            sourceHealthReportsProvider.overrideWithValue(health),
          ],
          child: MaterialApp(
            theme: CompactTheme.light,
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: MusicSourcesSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The transition into scanning adds the bar; measure the ticks after it.
      library.pushProgress(0.1);
      await tester.pump();
      hits.clear();

      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        library.pushProgress(0.1 + i * 0.01);
        await tester.pump();
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'sources page: 20 progress ticks = ${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMicroseconds / 20 / 1000).toStringAsFixed(1)}ms each), '
        '${countRebuilds(hits)} elements',
      );
    });

    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('queue panel: a favorite toggle', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    final queue = buildLibrary(500);
    await controller.playQueue(queue);
    final favorites = _FakeFavorites({queue[3].uri});
    final hits = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      hits.add(element.widget.runtimeType.toString());
    };

    await onDesktop(tester, () async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(audio),
            playbackControllerProvider.overrideWith((ref) => controller),
            favoritesControllerProvider.overrideWith(() => favorites),
          ],
          child: MaterialApp(
            theme: CompactTheme.light,
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 420,
                height: 900,
                child: QueuePanel(onClose: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      hits.clear();
      favorites.toggleOne(queue[3].uri);
      await tester.pump();
      // ignore: avoid_print
      print(
        'queue panel: one favorite toggle rebuilt '
        '${countRebuilds(hits)} elements',
      );
    });

    debugOnRebuildDirtyWidget = null;
  });

  testWidgets('shell and now playing: a mark on another track', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final controller = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await controller.playQueue([_songA, _songB]);
    final favorites = _FakeFavorites({_songB.uri});
    final hits = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      hits.add(element.widget.runtimeType.toString());
    };

    Future<int> togglingOther(Widget home) async {
      await onDesktop(tester, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              audioPlayerServiceProvider.overrideWithValue(audio),
              playbackControllerProvider.overrideWith((ref) => controller),
              favoritesControllerProvider.overrideWith(() => favorites),
            ],
            child: MaterialApp(
              theme: CompactTheme.light,
              locale: const Locale('zh', 'CN'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      hits.clear();
      favorites.toggleOne(_songB.uri);
      await tester.pump();
      return countRebuilds(hits);
    }

    final dock = await togglingOther(
      const CompactShell(currentPath: '/library', child: SizedBox.shrink()),
    );
    final page = await togglingOther(const NowPlayingPage());
    // ignore: avoid_print
    print('shell dock: a mark on another track rebuilt $dock elements');
    // ignore: avoid_print
    print('now playing page: a mark on another track rebuilt $page elements');

    debugOnRebuildDirtyWidget = null;
  });
}

const _songA = Song(
  id: 1,
  title: 'Alpha',
  artist: 'Artist A',
  album: 'Album A',
  duration: 180000,
  uri: '/music/a.mp3',
);

const _songB = Song(
  id: 2,
  title: 'Beta',
  artist: 'Artist B',
  album: 'Album B',
  duration: 180000,
  uri: '/music/b.mp3',
);

SourceHealthReport _healthReport() => const SourceHealthReport(
  availability: 100,
  configuration: 100,
  scan: 100,
  freshness: 100,
  output: 100,
  speed: 100,
  reliability: 100,
  stability: 100,
  playable: 100,
  artwork: 100,
  metadata: 100,
  activity: 100,
  score: 90,
  healthy: true,
);
