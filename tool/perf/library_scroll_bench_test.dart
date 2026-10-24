// Benchmark: how much a library list costs while it scrolls.
//
// The rows of the library are the heaviest thing the app draws: every row
// carries a cover, a few hints and three actions. This measures the cost of
// one scroll step with a big library, and counts what one row is made of.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/library/presentation/library_track_card.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/hint_layer.dart';

import '../../test/app/fake_audio_player_service.dart';

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;

  @override
  Future<LibraryState> build() async => LibraryState(songs: songs);
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

/// Counts the elements below [element] and how many of each kind there are.
int _count(Element element, Map<String, int> groups) {
  groups.update(
    element.widget.runtimeType.toString(),
    (value) => value + 1,
    ifAbsent: () => 1,
  );
  var total = 1;
  element.visitChildren((child) {
    total += _count(child, groups);
  });
  return total;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

void main() {
  testWidgets('library list: the cost of a scroll step', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final library = _FakeLibraryController(buildLibrary(20000));

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(() => library),
        ],
        // The app mounts one hint layer above the navigator, so the row
        // never holds a card of its own. The bench has to do the same or it
        // measures a tree the app never draws.
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

    // Ten scroll steps, the middle one is the number to compare: a single
    // drag includes the warm-up of the first rows.
    final steps = <double>[];
    for (var i = 0; i < 10; i++) {
      final sw = Stopwatch()..start();
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pump();
      sw.stop();
      steps.add(sw.elapsedMicroseconds / 1000);
    }
    // ignore: avoid_print
    print(
      'library 20000 songs: one scroll step median = '
      '${_median(steps).toStringAsFixed(1)}ms '
      '(min ${steps.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}ms, '
      'max ${steps.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}ms)',
    );

    // How heavy is one row? Every row that scrolls into view is built from
    // scratch, so the weight of a row is the weight of a scroll step.
    final card = find.byType(LibraryTrackCard).first;
    final groups = <String, int>{};
    var total = 0;
    tester.element(card).visitChildren((child) {
      total += _count(child, groups);
    });
    // ignore: avoid_print
    print('one row: $total elements');
    final summary = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in summary.take(16)) {
      // ignore: avoid_print
      print('  ${entry.key} x${entry.value}');
    }

    // A hint of a row that is not under the pointer must not hold an overlay.
    // ignore: avoid_print
    print('overlays in the viewport: ${groups['OverlayPortal'] ?? 0}');

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
