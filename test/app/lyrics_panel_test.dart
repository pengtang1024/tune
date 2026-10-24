import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/music_sources/music_source_service.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/application/lyrics_controller.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/features/player/presentation/lyrics_panel.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

void main() {
  const song = Song(
    id: 1,
    title: 'So What',
    artist: 'Miles Davis',
    uri: '/music/so-what.mp3',
    duration: 60000,
  );

  testWidgets('a track without lyrics offers the next step', (tester) async {
    await _pumpPanel(
      tester,
      state: const LyricsState(songId: 1),
      song: song,
    );

    expect(find.text('这首歌没有歌词'), findsOneWidget);
    expect(find.text('重新查找'), findsOneWidget);
    expect(find.text('选择歌词文件'), findsOneWidget);
  });

  testWidgets('a request that failed offers to try again', (tester) async {
    await _pumpPanel(
      tester,
      controller: _FailingController(),
      song: song,
    );

    expect(find.text('歌词加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('选择歌词文件'), findsOneWidget);
  });

  testWidgets('a file that cannot be read says so', (tester) async {
    await _pumpPanel(
      tester,
      state: const LyricsState(songId: 1, invalid: true),
      song: song,
    );

    expect(find.text('这个文件里没有歌词'), findsOneWidget);
    expect(find.text('选择歌词文件'), findsOneWidget);
  });

  testWidgets('the lines of the sheet are shown', (tester) async {
    final document = LyricsDocument.parse('''
[00:12.00]First line
[00:20.00]Second line
''');

    await _pumpPanel(
      tester,
      state: LyricsState(songId: 1, document: document),
      song: song,
    );

    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
  });

  testWidgets('a track that plays nothing says so', (tester) async {
    await _pumpPanel(tester, state: const LyricsState());

    expect(find.text('还没有正在播放的曲目'), findsOneWidget);
  });

  testWidgets('the lyrics are asked for while they are unknown', (tester) async {
    await _pumpPanel(tester, controller: _WaitingController(), song: song);

    expect(find.text('正在加载歌词'), findsOneWidget);
  });

  testWidgets('the retry asks for the lyrics again', (tester) async {
    final controller = _FakeLyricsController(const LyricsState(songId: 1));

    await _pumpPanel(tester, controller: controller, song: song);

    await tester.tap(find.text('重新查找'));
    await tester.pumpAndSettle();

    expect(controller.reloads, 1);
  });

  testWidgets('the panel does not change a provider while it is built', (
    tester,
  ) async {
    // The panel only shows what the controller knows: a provider must not be
    // changed while the widget tree is being built.
    final database = _FakeDatabase()..answers[1] = '[00:12.00]First line';

    await _pumpPanel(tester, database: database, song: song);

    expect(tester.takeException(), isNull);
    expect(find.text('First line'), findsOneWidget);
  });
}

/// The panel under test, with the lyrics state and the track in reach.
Future<void> _pumpPanel(
  WidgetTester tester, {
  LyricsState? state,
  LyricsController? controller,
  LyricsProvider? database,
  Song? song,
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.dispose);
  final playback = PlaybackController(
    audio,
    FakeSongDownloadService(),
    FakeStreamUrlResolver(),
  );
  if (song != null) await playback.playQueue([song]);

  final overrides = <Override>[
    persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
    audioPlayerServiceProvider.overrideWithValue(audio),
    playbackControllerProvider.overrideWith((ref) => playback),
  ];

  if (database != null) {
    overrides.add(
      libraryPathsProvider.overrideWithValue(_FakeLibraryPaths()),
    );
    overrides.add(
      musicSourceServiceProvider.overrideWithValue(
        MusicSourceService(
          scanner: CrossPlatformMusicScannerImpl(),
          store: MusicSourceStore(FakePersistenceService()),
          lyricsProvider: database,
        ),
      ),
    );
  } else {
    overrides.add(
      lyricsControllerProvider.overrideWith(
        () => controller ?? _FakeLyricsController(state ?? const LyricsState()),
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LyricsPanel()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A lyrics controller that holds the state the test gives it.
class _FakeLyricsController extends LyricsController {
  _FakeLyricsController(this.fixed);

  final LyricsState fixed;

  /// The number of times the reader was asked to try again.
  int reloads = 0;

  @override
  Future<LyricsState> build() async => fixed;

  @override
  Future<void> reload(Song song) async {
    reloads++;
  }
}

/// A lyrics controller whose answer never arrives.
class _WaitingController extends LyricsController {
  @override
  Future<LyricsState> build() => Completer<LyricsState>().future;
}

/// A lyrics controller whose request fails.
class _FailingController extends LyricsController {
  @override
  Future<LyricsState> build() async => throw StateError('the source is down');
}

/// The files of the app, kept in memory.
class _FakeLibraryPaths implements LibraryPaths {
  @override
  Future<String?> readLyrics(Song song) async => null;

  @override
  Future<void> saveLyrics(Song song, String lyrics) async {}

  @override
  Future<void> saveChosenLyrics(Song song, String lyrics) async {}


  @override
  Future<Directory> folderFor(Song song) async =>
      throw UnsupportedError('the test has no file system');

  @override
  String nameFor(Song song) => song.title;

  @override
  Future<File> coverFileFor(Song song, String extension) async =>
      throw UnsupportedError('the test has no file system');

  @override
  Future<File> lyricsFileFor(Song song) async =>
      throw UnsupportedError('the test has no file system');

  /// The rest of the library is of no use to the lyrics.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('the test has no file system');
}

/// A lyrics database that answers from a table.
class _FakeDatabase implements LyricsProvider {
  final Map<int, String?> answers = {};

  @override
  Future<String?> lookup(Song song) async => answers[song.id];
}
