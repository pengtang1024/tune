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
import 'package:tune/shared/ui/hint_layer.dart';

import 'fake_audio_player_service.dart';

class _FakeLibraryController extends LibraryController {
  _FakeLibraryController(this.songs);

  final List<Song> songs;

  @override
  Future<LibraryState> build() async => LibraryState(songs: songs);

  @override
  Future<void> setQuery(String query) async {
    state = AsyncData((state.valueOrNull ?? LibraryState(songs: songs)).copyWith(query: query));
  }

  @override
  Future<void> setSourceFilter(String? sourceId) async {
    state = AsyncData(
      (state.valueOrNull ?? LibraryState(songs: songs)).copyWith(
        sourceFilter: sourceId,
      ),
    );
  }
}

Song _song(int i) => Song(
  id: i,
  title: 'Track title $i',
  artist: 'Artist ${i % 500}',
  album: 'Album ${i % 900}',
  duration: 200000,
  uri: '/music/track-$i.mp3',
);

/// Guards the cache of the row list.
///
/// The page rebuilds for its header, its toolbar and the desktop around it.
/// A rebuild that changes nothing a row paints must hand the same list back
/// to the framework, or the viewport is built again for no reason (measured
/// at about a third of a second for twenty rows).
void main() {
  testWidgets('a page rebuild that changes no row leaves the rows alone', (
    tester,
  ) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final library = _FakeLibraryController([
      for (var i = 0; i < 40; i++) _song(i),
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

    final rebuilt = <String, int>{};
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce) return;
      final name = element.widget.runtimeType.toString();
      rebuilt.update(name, (value) => value + 1, ifAbsent: () => 1);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    // A page rebuild with the same songs, labels and width.
    tester.element(find.byType(LibraryPane)).markNeedsBuild();
    await tester.pump();

    expect(rebuilt['LibraryPane'] ?? 0, 1);
    expect(
      rebuilt['LibraryTrackCard'] ?? 0,
      0,
      reason: 'a page rebuild must not rebuild the rows it already has',
    );

    // A rebuild that does change the list still rebuilds it.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    container.read(libraryControllerProvider.notifier).setQuery('Track title 3');
    await tester.pump();

    expect(
      rebuilt['LibraryTrackCard'] ?? 0,
      greaterThan(0),
      reason: 'a query changes which rows are on the screen',
    );
  });
}
