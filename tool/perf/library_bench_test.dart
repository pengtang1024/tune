// Benchmark: the library page and the cost of one scan progress update on a
// big library. Run with: flutter test tool/perf/library_bench_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../../test/app/fake_audio_player_service.dart';

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;

  @override
  Future<LibraryState> build() async => LibraryState(songs: songs);

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

void main() {
  testWidgets('library page: one scan progress update', (tester) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final library = _FakeLibraryController(buildLibrary(20000));
    final hits = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      hits.add(element.widget.runtimeType.toString());
    };

    // The desktop the app runs on: the default test surface is 800x600 and
    // the rows overflow there, which is noise in this measurement.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(audio),
          libraryControllerProvider.overrideWith(() => library),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LibraryPane(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    hits.clear();
    library.pushProgress(0.42);
    await tester.pump();
    final afterProgress = hits.length;
    hits.clear();

    final sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      library.pushProgress(0.4 + i * 0.01);
      await tester.pump();
    }
    sw.stop();

    final groups = <String, int>{};
    for (final type in hits) {
      groups[type] = (groups[type] ?? 0) + 1;
    }
    final summary = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print(
      'library 20000 songs: one progress update rebuilt $afterProgress elements',
    );
    // ignore: avoid_print
    print(
      'library 20000 songs: 20 progress updates = ${sw.elapsedMilliseconds}ms '
      '(${(sw.elapsedMicroseconds / 20 / 1000).toStringAsFixed(1)}ms each)',
    );
    for (final entry in summary.take(10)) {
      // ignore: avoid_print
      print('  ${entry.key} x${entry.value}');
    }
    debugOnRebuildDirtyWidget = null;
  });
}
