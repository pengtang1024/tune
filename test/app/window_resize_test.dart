import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/layout/window_form_controller.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/data/services/window_layout_store.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/features/shell/presentation/mini_player_bar.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/shared/ui/hint_layer.dart';

import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';
import 'fake_audio_player_service.dart';
import 'fake_song_download_service.dart';
import 'fake_stream_url_resolver.dart';

const song = Song(
  id: 1,
  title: 'Window form',
  artist: 'Tune',
  duration: 180000,
  uri: '/music/window-form.mp3',
);

class _FakeLibraryController extends LibraryController {
  @override
  Future<LibraryState> build() async =>
      LibraryState(songs: [for (var i = 0; i < 40; i++) _track(i)]);
}

Song _track(int i) => Song(
  id: i,
  title: 'Track title $i',
  artist: 'Artist $i',
  album: 'Album $i',
  duration: 200000,
  uri: '/music/track-$i.mp3',
);

/// The size the window is restored to, which is not the size the bar is.
const _desktop = Size(1120, 700);

/// The size of the bar.
const _mini = Size(360, 88);

/// Frames between the bar and the restored window.
///
/// The window service raises the minimum before it grows the window, so the
/// shell is asked to draw widths below its minimum and heights below its dock.
/// Every one of them is drawn as the bar; the shell only draws once the window
/// can hold it.
const _frames = [
  Size(360, 88),
  Size(480, 200),
  Size(700, 480),
  Size(760, 100),
  Size(760, 249),
  Size(760, 250),
  Size(760, 520),
  Size(900, 600),
  Size(1120, 815),
];

void main() {
  late FakePersistenceService persistence;
  late FakeAudioPlayerService audio;
  late PlaybackController playback;
  late List<FlutterErrorDetails> errors;

  setUp(() async {
    persistence = FakePersistenceService();
    audio = FakeAudioPlayerService();
    playback = PlaybackController(
      audio,
      FakeSongDownloadService(),
      FakeStreamUrlResolver(),
    );
    await playback.playQueue([song]);
    errors = [];
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
    audio.dispose();
  });

  var shells = 0;

  /// Lays the shell out at [size] with a fresh subtree.
  ///
  /// The subtree is replaced on every frame because a RenderFlex reports its
  /// overflow once: the same render object would hide the second squeeze.
  Future<ProviderContainer> pumpShell(
    WidgetTester tester,
    Widget page,
    Size size,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          defaultPlayerServiceProvider.overrideWithValue(
            FakeDefaultPlayerService(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
          playbackControllerProvider.overrideWith((ref) => playback),
          libraryControllerProvider.overrideWith(_FakeLibraryController.new),
        ],
        child: MaterialApp(
          theme: CompactTheme.light,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => HintLayer(child: child!),
          home: CompactShell(
            key: ValueKey(shells++),
            currentPath: '/library',
            child: page,
          ),
        ),
      ),
    );
    // The pages build their state in a microtask; the next frame lays out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return ProviderScope.containerOf(
      tester.element(find.byType(CompactShell)),
    );
  }

  Future<void> restoreAt(WidgetTester tester, Widget page, Size size) async {
    final container = await pumpShell(tester, page, _desktop);
    errors.clear();

    // Offstage keeps the shell mounted while the bar is up, and it lays the
    // shell out all the same: a hidden page must not overflow in that frame.
    container.read(windowFormProvider.notifier).setForm(WindowForm.mini);
    tester.view.physicalSize = _mini;
    await tester.pump();
    await tester.pump();
    expect(errors, isEmpty, reason: 'the bar frame must not overflow');

    container.read(windowFormProvider.notifier).setForm(WindowForm.normal);
    tester.view.physicalSize = size;
    await tester.pump();
    await tester.pump();
    expect(
      errors,
      isEmpty,
      reason: 'restoring at ${size.width}x${size.height} must not overflow',
    );

    // The arrangement follows what the window can hold, not the form alone.
    final holdsShell =
        size.width >= 760 && size.height >= LayoutBreakpoints.shellMinHeight;
    expect(
      find.byType(MiniPlayerBar),
      holdsShell ? findsNothing : findsOneWidget,
    );
    if (holdsShell) {
      expect(find.byType(PlayerDock), findsOneWidget);
    }
  }

  testWidgets('the shell survives every frame between the bar and the window', (
    tester,
  ) async {
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      for (final page in <Widget>[const LibraryPane(), const SettingsPane()]) {
        for (final size in _frames) {
          await restoreAt(tester, page, size);
        }
      }
    } finally {
      FlutterError.onError = previous;
    }
  });
}
