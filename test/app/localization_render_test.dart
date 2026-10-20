import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/core/l10n/localization_bridge.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/now_playing_page.dart';
import 'package:tune/features/search/application/online_search_controller.dart';
import 'package:tune/features/search/domain/online_search_state.dart';
import 'package:tune/features/queue/presentation/queue_pane.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';
import 'localization_words.dart';

/// Guards the interface as a reader sees it.
///
/// The catalogue test reads the words of the translations; this test draws
/// the screens and reads the words off the tree, so it catches what the
/// catalogue cannot see:
///
/// * a text that never went through the catalogue,
/// * a language that leaks into another one (Chinese in the English
///   interface, English in the Chinese interface),
/// * a label that is longer than the room it gets, which is what an English
///   label does to a layout built for a Chinese one.
///
/// Every screen is drawn on a navigator of its own, so a window that stays
/// open on one screen cannot reach the next one.
late FakePersistenceService persistence;
late FakeAudioPlayerService audio;
late PlaybackController playback;

void main() {
  setUpAll(() async {
    persistence = FakePersistenceService();
  });

  setUp(() async {
    audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);

    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([songA, remoteSong]);
  });

  testWidgets('the Chinese interface writes no text of another language', (
    tester,
  ) async {
    final texts = await _textsOfEveryScreen(tester, const Locale('zh', 'CN'));

    for (final text in texts) {
      if (!_latin.hasMatch(text)) continue;
      if (_han.hasMatch(text)) continue;
      if (_testData.contains(text)) continue;
      if (_languageNames.contains(text)) continue;
      if (_allowedWord.hasMatch(text)) continue;
      if (_properName.hasMatch(text)) continue;

      fail('the Chinese interface writes "$text"');
    }
  });

  testWidgets('the English interface writes no text of another language', (
    tester,
  ) async {
    final texts = await _textsOfEveryScreen(tester, const Locale('en'));

    for (final text in texts) {
      if (!_han.hasMatch(text)) continue;
      fail('the English interface writes "$text"');
    }
  });

  testWidgets('every screen fits the words of both languages', (tester) async {
    for (final size in const [Size(1400, 900), Size(760, 483)]) {
      for (final locale in const [Locale('zh', 'CN'), Locale('en')]) {
        await _drawEveryScreen(tester, locale, size);
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'a screen of $locale does not fit its words at $size',
        );
      }
    }
  });
}

/// The songs the test puts in the library.
const songA = Song(
  id: 1,
  title: 'A very long song title that should be ellipsized',
  artist: 'A very long artist name that should be ellipsized',
  duration: 245000,
  uri: '/music/a.mp3',
);

/// A song of an online source.
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

/// The names of the tracks are the data of the test, not a text of the
/// interface, so they stay the way they are.
const _testData = {
  'A very long song title that should be ellipsized',
  'A very long artist name that should be ellipsized',
  'Piano Melody',
  'Open Artist',
};

/// The language names the settings page lists in their own language.
const _languageNames = {'繁體中文', '简体中文', 'English'};

/// The words of the Latin script.
final _latin = RegExp(r'[A-Za-z]');

/// The words of the Han script.
final _han = RegExp(r'[\u4e00-\u9fff]');

/// The words that stay the way they are.
///
/// A number, a duration, a version, a path and the quality of a source are
/// the same in every language, so they never count as a language of their
/// own.
final _allowedWord = RegExp(
  r'^('
  r'\d{1,2}:\d{2}(:\d{2})?' // a duration
  r'|\d+' // a count
  r'|v?\d+(\.\d+)+' // a version
  r'|/\S+' // a path
  r'|MP3 · \d+ kbps' // a quality of a source
  r')$',
);

/// The names that stay the same in every language.
final _properName = RegExp(
  '^(?:${[...properNames, ...formatNames].map(RegExp.escape).join('|')})\$',
  caseSensitive: false,
);

/// The words of every screen of the app.
///
/// The screens are drawn one after the other and every text a reader can see
/// is collected: the text of the widgets, the tooltips and the words of the
/// input fields.
Future<List<String>> _textsOfEveryScreen(
  WidgetTester tester,
  Locale locale,
) async {
  final texts = <String>{};

  await _drawEveryScreen(tester, locale, const Size(1400, 900), collect: texts);

  return texts.toList()..sort();
}

/// Draws every screen of the app in a language.
Future<void> _drawEveryScreen(
  WidgetTester tester,
  Locale locale,
  Size size, {
  Set<String>? collect,
}) async {
  final strings = lookupAppLocalizations(locale);

  // The library with the shell around it.
  await _draw(tester, locale, size, 'library', const CompactShell(
    currentPath: '/library',
    child: LibraryPane(),
  ));
  _collect(tester, collect);

  // The sheet that tells everything about a track.
  final details = find.byTooltip(strings.trackDetailsTooltip);
  if (details.evaluate().isNotEmpty) {
    await tester.ensureVisible(details.first);
    await tester.pumpAndSettle();
    await tester.tap(details.first);
    await tester.pumpAndSettle();
    expect(
      find.byType(BottomSheet).evaluate(),
      isNotEmpty,
      reason: 'the sheet of the track did not open',
    );
    _collect(tester, collect);
    await _closeWindow(tester);
  }

  // The search sheet that rises out of the library.
  final search = find.widgetWithText(OutlinedButton, strings.searchOnlineTitle);
  expect(
    search,
    findsOneWidget,
    reason: 'the library has no button that opens the search sheet',
  );
  await tester.ensureVisible(search);
  await tester.pumpAndSettle();
  await tester.tap(search);
  await tester.pumpAndSettle();
  expect(
    find.byType(BottomSheet).evaluate(),
    isNotEmpty,
    reason: 'the search sheet did not open',
  );
  _collect(tester, collect);
  await _closeWindow(tester);

  // The queue.
  await _draw(tester, locale, size, 'queue', const CompactShell(
    currentPath: '/queue',
    child: QueuePane(),
  ));
  _collect(tester, collect);

  // The settings.
  await _draw(tester, locale, size, 'settings', const CompactShell(
    currentPath: '/settings',
    child: SettingsPane(),
  ));
  _collect(tester, collect);

  // The sources with the settings of one of them.
  await _draw(tester, locale, size, 'sources', const CompactShell(
    currentPath: '/sources',
    child: SourcesPane(),
  ));
  _collect(tester, collect);

  final config = find.byKey(const ValueKey('source-config-jamendo'));
  if (config.evaluate().isNotEmpty) {
    await tester.ensureVisible(config);
    await tester.pumpAndSettle();
    await tester.tap(config);
    await tester.pumpAndSettle();
    expect(
      find.byType(AlertDialog).evaluate(),
      isNotEmpty,
      reason: 'the settings of the source did not open',
    );
    _collect(tester, collect);
    await _closeWindow(tester);
  }

  // The page that plays the track.
  await _draw(tester, locale, size, 'now-playing', const NowPlayingPage());
  _collect(tester, collect);
}

/// Draws one screen on a navigator of its own.
///
/// The key of the window keeps every screen apart, so the window of the
/// screen before cannot keep its own windows (the search sheet, the dialog
/// of a source) open and block the screen that follows.
Future<void> _draw(
  WidgetTester tester,
  Locale locale,
  Size size,
  String screen,
  Widget home,
) async {
  await tester.pumpWidget(
    _app(tester, locale, size, screen, home),
  );
  await tester.pumpAndSettle();
}

/// Closes the window that lies on top of the screen.
Future<void> _closeWindow(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

/// Reads the words of the screen that is on the tree.
void _collect(WidgetTester tester, Set<String>? collect) {
  if (collect == null) return;

  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final data = widget.data;
    if (data != null && data.trim().isNotEmpty) collect.add(data);
    final span = widget.textSpan;
    if (span != null) collect.addAll(_spanTexts(span));
  }

  for (final widget in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final message = widget.message;
    if (message != null && message.trim().isNotEmpty) collect.add(message);
  }

  for (final widget in tester.widgetList<TextField>(find.byType(TextField))) {
    final decoration = widget.decoration;
    for (final slot in [
      decoration?.labelText,
      decoration?.hintText,
      decoration?.helperText,
      decoration?.errorText,
      decoration?.prefixText,
      decoration?.suffixText,
    ]) {
      if (slot != null && slot.trim().isNotEmpty) collect.add(slot);
    }
  }
}

/// The words of a text that is made of several parts.
Iterable<String> _spanTexts(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  final text = span.text;
  if (text != null && text.trim().isNotEmpty) yield text;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _spanTexts(child);
  }
}

/// The screens of the app, drawn in a language.
Widget _app(
  WidgetTester tester,
  Locale locale,
  Size size,
  String screen,
  Widget home,
) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // The settings hold the language of the app, so the table the services
  // read speaks the same language as the interface.
  final localeStore = FakePersistenceService()
    ..values['language_code'] = locale.languageCode
    ..values['country_code'] = locale.countryCode;

  return ProviderScope(
    overrides: [
      persistenceServiceProvider.overrideWithValue(persistence),
      settingsControllerProvider.overrideWith(
        (ref) => SettingsController(localeStore),
      ),
      audioPlayerServiceProvider.overrideWithValue(audio),
      playbackControllerProvider.overrideWith((ref) => playback),
      libraryControllerProvider.overrideWith(
        () => FakeLibraryController(
          const LibraryState(songs: [songA, remoteSong]),
        ),
      ),
      onlineSearchControllerProvider.overrideWith(
        () => FakeOnlineSearchController(),
      ),
      musicSourcesControllerProvider.overrideWith(
        () => FakeMusicSourcesController(
          MusicSourcesState(sources: BuiltInMusicSources.defaults),
        ),
      ),
    ],
    child: MaterialApp(
      key: ValueKey('$screen-$locale-$size'),
      theme: CompactTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => LocalizationBridge(
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    ),
  );
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

class FakeMusicSourcesController extends MusicSourcesController {
  FakeMusicSourcesController(this.seed);

  final MusicSourcesState seed;

  @override
  Future<MusicSourcesState> build() async => seed;

  @override
  Future<void> setEnabled(String sourceId, bool enabled) async {}

  @override
  Future<void> updateSettings(String id, Map<String, String> settings) async {}
}

/// The search results the test draws.
///
/// The sheet of the online search names every source it groups its results
/// by, so the results have to be on the tree when the sheet is checked.
class FakeOnlineSearchController extends OnlineSearchController {
  @override
  Future<OnlineSearchState> build() async {
    return OnlineSearchState(
      query: 'piano',
      results: {
        'openverse': SourceScanResult(
          sourceId: 'openverse',
          status: SourceScanStatus.success,
          songs: const [remoteSong],
        ),
        'wikimedia': SourceScanResult(
          sourceId: 'wikimedia',
          status: SourceScanStatus.failed,
          message: AppStrings.instance.searchFailedShort,
        ),
      },
    );
  }
}
