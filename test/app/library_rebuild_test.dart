import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/favorites/application/favorites_controller.dart';
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
}

Song _song(int i) => Song(
  id: i,
  title: 'Track title $i',
  artist: 'Artist ${i % 500}',
  album: 'Album ${i % 900}',
  duration: 200000,
  uri: '/music/track-$i.mp3',
);

/// Guards who listens to what while a row is on the screen.
///
/// The page used to watch the whole favorites state and the whole health
/// report, so liking one track rebuilt every row in the viewport. A row now
/// listens to its own three values: the mark, whether it is the current
/// track, and whether that track plays.
void main() {
  testWidgets('liking a track rebuilds one row, not the page', (tester) async {
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

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LibraryPane)),
    );
    final rebuilt = <String, int>{};
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (builtOnce) return;
      final name = element.widget.runtimeType.toString();
      rebuilt.update(name, (value) => value + 1, ifAbsent: () => 1);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    container.read(favoritesControllerProvider.notifier).toggle(_song(3).uri);
    await tester.pump();

    expect(
      rebuilt['LibraryPane'] ?? 0,
      0,
      reason: 'a mark belongs to a row, not to the page',
    );
    expect(
      rebuilt['LibraryTrackCard'] ?? 0,
      1,
      reason: 'only the row whose mark changed rebuilds',
    );
    final elements = rebuilt.values.fold(0, (sum, count) => sum + count);
    expect(
      elements,
      lessThanOrEqualTo(120),
      reason: 'liking a track rebuilt $elements elements, not a pageful',
    );
  });
}
