import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/library_filter.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/application/library_initial_view_provider.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_layer.dart';

import 'fake_audio_player_service.dart';

/// A library that writes what each row is.
///
/// A row of an episode, a chapter, a station and a sound effect used to look
/// exactly like a row of a song; the only way to tell them apart was to open
/// the details panel. The row now writes the kind beside the title, and the
/// word takes the reader to the rest of that kind.
class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;
  LibraryFilter? lastFilter;

  @override
  Future<LibraryState> build() async => LibraryState(songs: songs);

  @override
  Future<void> setFilter(LibraryFilter filter) async {
    lastFilter = filter;
    final current = state.valueOrNull ?? LibraryState(songs: songs);
    final narrowed = filter.kinds.isEmpty
        ? songs
        : songs.where((s) => filter.kinds.contains(contentKindOf(s))).toList();
    state = AsyncData(
      current.copyWith(songs: narrowed, filter: filter, matching: narrowed.length),
    );
  }
}

Song _song({
  required int id,
  required String title,
  String? sourceId,
  String? genre,
  bool live = false,
}) => Song(
  id: id,
  title: title,
  artist: 'Artist',
  album: 'Album',
  duration: live ? 0 : 200000,
  uri: '/music/$id.mp3',
  sourceId: sourceId,
  genre: genre,
  isLiveStream: live,
);

void main() {
  final songs = [
    _song(id: 1, title: 'My song'),
    _song(id: 2, title: 'An episode', sourceId: 'podcast_rss'),
    _song(id: 3, title: 'A chapter', sourceId: 'librivox'),
    _song(id: 4, title: 'A station', sourceId: 'radio', live: true),
    _song(id: 5, title: 'A door slam', genre: 'non-music'),
  ];

  Future<_FakeLibraryController> open(WidgetTester tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final library = _FakeLibraryController(songs);

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryInitialViewProvider.overrideWithValue(LibraryViewMode.songs),
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(() => library),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => HintLayer(child: child!),
          home: const Scaffold(body: LibraryPane()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return library;
  }

  testWidgets('each row writes what it is, and only a song writes nothing', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('播客'), findsOneWidget);
    expect(find.text('有声书'), findsOneWidget);
    expect(find.text('电台'), findsOneWidget);
    expect(find.text('音效'), findsOneWidget);
    expect(find.text('音乐'), findsNothing);
  });

  testWidgets('the word narrows the page to its own kind', (tester) async {
    final library = await open(tester);

    await tester.tap(find.text('播客'));
    await tester.pumpAndSettle();

    expect(library.lastFilter?.kinds, {ContentKind.podcast});
    expect(find.text('An episode'), findsOneWidget);
    expect(find.text('My song'), findsNothing);
  });
}
