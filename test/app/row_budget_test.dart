import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_row_metrics.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_layer.dart';
import 'package:tune/shared/ui/hint_trigger.dart';

import 'fake_audio_player_service.dart';

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;

  @override
  Future<LibraryState> build() async => LibraryState(songs: songs);
}

/// A track of the shape the benchmark uses: a local file whose only facts
/// are its format and that it sits on this machine.
Song _song(int i) {
  return Song(
    id: i,
    title: 'Track title $i',
    artist: 'Artist ${i % 500}',
    album: 'Album ${i % 900}',
    duration: 200000,
    uri: '/music/track-$i.mp3',
  );
}

/// A track that shows every fact a row can show.
Song _richSong(int i) {
  return Song(
    id: i,
    title: 'Track title $i',
    artist: 'Artist ${i % 500}',
    album: 'Album ${i % 900}',
    duration: 200000,
    uri: '/music/track-$i.flac',
    type: 'flac',
    bitrate: 900,
    sampleRate: 96000,
    size: 40 * 1024 * 1024,
  );
}

/// Guards the weight of one row of the library.
///
/// A row that scrolls into view is built from scratch, so the number of
/// elements it holds is the number the frame has to make. The budget says a
/// row stays a row and not a page; the portal count says the hints of the
/// row do not carry a card of their own.
void main() {
  testWidgets('a library row stays inside its budget and holds no overlay', (
    tester,
  ) async {
    await _pumpLibrary(tester, _song);

    final row = find.byType(LibraryTrackCard).first;
    final elements = _count(tester.element(row));

    expect(
      elements,
      lessThanOrEqualTo(170),
      reason: 'one row holds $elements elements',
    );
    expect(
      find.descendant(of: row, matching: find.byType(OverlayPortal)),
      findsNothing,
      reason: 'a row asks the hint layer for a card, it does not own one',
    );
    expect(
      find.descendant(of: row, matching: find.byType(RawTooltip)),
      findsNothing,
      reason: 'a row inside the app never falls back to the old tooltip',
    );

    // The row still says every hint it keeps: the title, the artist, the
    // album and the three actions. The file facts moved to the details.
    expect(
      find.descendant(of: row, matching: find.byType(HintTrigger)),
      findsNWidgets(4),
    );
  });

  testWidgets('a row with every column stays under the heavy-row ceiling', (
    tester,
  ) async {
    await _pumpLibrary(tester, _richSong);

    final row = find.byType(LibraryTrackCard).first;
    final elements = _count(tester.element(row));

    expect(
      elements,
      lessThanOrEqualTo(190),
      reason: 'a row with every column holds $elements elements',
    );
    expect(
      find.descendant(of: row, matching: find.byType(HintTrigger)),
      findsNWidgets(4),
    );
  });

  testWidgets('a row with a source badge stays under the ceiling', (
    tester,
  ) async {
    await _pumpRow(
      tester,
      const Song(
        id: 7,
        title: 'Track title',
        artist: 'Artist',
        album: 'Album',
        duration: 200000,
        uri: '/music/track.flac',
        type: 'flac',
        sourceId: 'itunes',
      ),
      source: const SourceLabel(name: 'iTunes', type: 'itunes'),
    );

    final row = find.byType(LibraryTrackCard).first;
    final elements = _count(tester.element(row));

    expect(
      elements,
      lessThanOrEqualTo(190),
      reason: 'a row with a source badge holds $elements elements',
    );
    expect(
      find.descendant(of: row, matching: find.byType(HintTrigger)),
      findsNWidgets(5),
    );
  });

  testWidgets('the list fixes the row extent only at a normal text scale', (
    tester,
  ) async {
    await _pumpLibrary(tester, _song);

    expect(
      tester.widget<ListView>(find.byType(ListView).first).itemExtent,
      CompactTokens.libraryRowHeight,
    );

    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pump();

    expect(
      tester.widget<ListView>(find.byType(ListView).first).itemExtent,
      isNull,
      reason: 'a larger text needs a row that can grow',
    );
  });
}

Future<void> _pumpRow(
  WidgetTester tester,
  Song song, {
  SourceLabel? source,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => HintLayer(child: child!),
        home: Scaffold(
          body: LibraryTrackCard(
            song: song,
            index: 0,
            selected: false,
            playing: false,
            isFavorite: false,
            source: source,
            metrics: LibraryRowMetrics.at(width: 1800, textScale: 1),
            onTap: _noop,
            onDoubleTap: _noop,
            waitsForDoubleClick: false,
            onAddToQueue: _noop,
            onToggleFavorite: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  Song Function(int index) songOf,
) async {
  final audio = FakeAudioPlayerService();
  addTearDown(audio.dispose);
  final library = _FakeLibraryController([
    for (var i = 0; i < 40; i++) songOf(i),
  ]);

  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        libraryControllerProvider.overrideWith(() => library),
      ],
      // The app mounts one hint layer above the navigator, so the row never
      // holds a card of its own. The test has to do the same or it measures
      // a tree the app never draws.
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
}

void _noop() {}

int _count(Element element) {
  var total = 1;
  element.visitChildren((child) {
    total += _count(child);
  });
  return total;
}
