import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/library/presentation/library_pane.dart';
import 'package:tune/features/shell/presentation/compact_shell.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';

import 'compact_layout_test.dart' show FakeLibraryController;
import 'fake_audio_player_service.dart';

void main() {
  const songs = [
    Song(
      id: 1,
      title: 'Album A first',
      artist: 'Artist A',
      album: 'Album A',
      trackNumber: 1,
      duration: 60000,
      uri: '/music/a1.mp3',
    ),
    Song(
      id: 2,
      title: 'Album A second',
      artist: 'Artist A',
      album: 'Album A',
      trackNumber: 2,
      duration: 60000,
      uri: '/music/a2.mp3',
    ),
    Song(
      id: 3,
      title: 'Album B first',
      artist: 'Artist B',
      album: 'Album B',
      trackNumber: 1,
      duration: 60000,
      uri: '/music/b1.mp3',
    ),
  ];

  Widget app({required Widget home}) {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(FakePersistenceService()),
        defaultPlayerServiceProvider.overrideWithValue(
          FakeDefaultPlayerService(),
        ),
        audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(const LibraryState(songs: songs)),
        ),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('the library opens an album from the cover grid', (tester) async {
    tester.view.physicalSize = const Size(900, 563);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        home: const CompactShell(currentPath: '/library', child: LibraryPane()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album A'), findsOneWidget);
    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);

    await tester.tap(find.text('Album A'));
    await tester.pumpAndSettle();

    expect(find.text('Album A first'), findsOneWidget);
    expect(find.text('Album A second'), findsOneWidget);
    expect(find.text('Album B first'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album B'), findsOneWidget);
    expect(find.text('Album A first'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
