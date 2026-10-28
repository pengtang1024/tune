import 'dart:async';
import 'dart:convert';
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
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';
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
    // The smart generation is on the sheet, but without a key it waits.
    expect(find.text('智能生成'), findsOneWidget);
    final generate = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('智能生成'),
        matching: find.byType(TextButton),
      ),
    );
    expect(generate.onPressed, isNull, reason: 'no key pasted: the button waits');
  });

  testWidgets('a key pasted wakes the smart generation up', (tester) async {
    final persistence = FakePersistenceService()
      ..values['smart_lyrics'] = jsonEncode(
        const SmartLyricsConfig(apiKey: 'sk-test').toJson(),
      );

    await _pumpPanel(
      tester,
      state: const LyricsState(songId: 1),
      song: song,
      persistence: persistence,
    );

    final generate = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('智能生成'),
        matching: find.byType(TextButton),
      ),
    );
    expect(generate.onPressed, isNotNull);
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

  testWidgets('a machine sheet says what it is and offers the search again', (
    tester,
  ) async {
    final database = _FakeDatabase();
    final paths = _FakeLibraryPaths()..smartSheets[1] = '[00:01.00]机器词';

    await _pumpPanel(tester, database: database, song: song, paths: paths);

    expect(find.text('机器词'), findsOneWidget);
    expect(find.text('机器稿：票池生成，重新查找可以找更好的词'), findsOneWidget);

    // A real sheet the search finds later tops the machine's — that is the
    // whole point of the reading order.
    database.answers[1] = '[00:02.00]真词';
    await tester.tap(find.text('重新查找'));
    await tester.pumpAndSettle();

    expect(find.text('真词'), findsOneWidget);
    expect(find.text('机器词'), findsNothing);
  });

  testWidgets('a generation shows its progress and can be stopped', (
    tester,
  ) async {
    final service = _GatedService();
    final persistence = FakePersistenceService()
      ..values['smart_lyrics'] = jsonEncode(
        const SmartLyricsConfig(apiKey: 'sk-test').toJson(),
      );

    await _pumpPanel(
      tester,
      state: const LyricsState(songId: 1),
      song: song,
      persistence: persistence,
      extra: [smartLyricsServiceProvider.overrideWithValue(service)],
    );

    await tester.tap(find.text('智能生成'));
    await tester.pumpAndSettle();

    expect(find.textContaining('正在生成歌词'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    await tester.tap(find.text('取消'));
    service.gate!.complete(const SmartLyricsOutcome.cancelled());
    await tester.pumpAndSettle();

    expect(find.text('智能生成'), findsOneWidget, reason: 'the run is over: '
        'the missing state is back, nothing half-written stays');
  });

  testWidgets('a finished generation swaps the words in', (tester) async {
    final service = _GatedService();
    final lyrics = _FakeLyricsController(const LyricsState(songId: 1));
    final persistence = FakePersistenceService()
      ..values['smart_lyrics'] = jsonEncode(
        const SmartLyricsConfig(apiKey: 'sk-test').toJson(),
      );

    await _pumpPanel(
      tester,
      controller: lyrics,
      song: song,
      persistence: persistence,
      extra: [smartLyricsServiceProvider.overrideWithValue(service)],
    );

    await tester.tap(find.text('智能生成'));
    await tester.pump();

    // The service writes the sheet next to the audio, then answers; the
    // panel learns the words the way it learns every sheet — by reading.
    service.gate!.complete(
      SmartLyricsOutcome(saved: true, votes: 3, origins: const ['lrclib']),
    );
    lyrics.fixed = LyricsState(
      songId: 1,
      document: LyricsDocument.parse('[00:01.00]机器词'),
      smart: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('机器词'), findsOneWidget);
    expect(find.text('机器稿：票池生成，重新查找可以找更好的词'), findsOneWidget);
  });
}

/// The panel under test, with the lyrics state and the track in reach.
Future<void> _pumpPanel(
  WidgetTester tester, {
  LyricsState? state,
  LyricsController? controller,
  LyricsProvider? database,
  Song? song,
  FakePersistenceService? persistence,
  LibraryPaths? paths,
  List<Override> extra = const [],
}) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.dispose);
  // The provider owns the controller; the test hands in a persistence that
  // already holds the values the scene needs.
  final settingsPersistence = persistence ?? FakePersistenceService();
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
    settingsControllerProvider.overrideWith(
      (ref) => SettingsController(settingsPersistence),
    ),
    ...extra,
  ];

  if (database != null) {
    overrides.add(
      libraryPathsProvider.overrideWithValue(
        paths ?? _FakeLibraryPaths(),
      ),
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

  /// The state the panel reads; a test that plays the pipeline changes it
  /// before the next rebuild, the way the file on the disk would.
  LyricsState fixed;

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

  /// The machine sheets, kept apart from the sheets the reader matched.
  final Map<int, String> smartSheets = {};

  @override
  Future<void> saveSmartLyrics(Song song, String lyrics) async =>
      smartSheets[song.id] = lyrics;

  @override
  Future<String?> readSmartLyrics(Song song) async => smartSheets[song.id];


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

/// The service of the smart pipeline that waits for the test to let the
/// run come home.
class _GatedService extends SmartLyricsService {
  _GatedService() : super(engines: const [], humanPool: const [], paths: _FakeLibraryPaths());

  /// The run waits here; the test completes it with the outcome it chose.
  Completer<SmartLyricsOutcome>? gate;

  /// The tracks the pipeline was asked to work on.
  final List<Song> asked = [];

  @override
  Future<SmartLyricsOutcome> generate(Song song, {bool Function()? cancelled}) {
    asked.add(song);
    gate ??= Completer<SmartLyricsOutcome>();
    return gate!.future;
  }
}
