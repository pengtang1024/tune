import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/providers/audio_player_service_provider.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/settings/presentation/settings_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_default_player_service.dart';
import '../services/fake_persistence.dart';

import 'fake_audio_player_service.dart';

/// The action that makes Tune the program the desktop opens audio files with.
///
/// The button asks the desktop to name Tune as the handler of every audio
/// type the player understands, and the pane says so afterwards.
void main() {
  Widget app({
    required Widget home,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    );
  }

  /// Opens the settings with a desktop that answers as [service] does.
  Future<void> openSettings(
    WidgetTester tester,
    FakeDefaultPlayerService service,
  ) async {
    final audio = FakeAudioPlayerService();
    addTearDown(audio.dispose);
    final persistence = FakePersistenceService();

    await tester.pumpWidget(
      app(
        home: const SettingsPane(),
        overrides: [
          persistenceServiceProvider.overrideWithValue(persistence),
          audioPlayerServiceProvider.overrideWithValue(audio),
          defaultPlayerServiceProvider.overrideWithValue(service),
          libraryControllerProvider.overrideWith(
            () => FakeLibraryController(const LibraryState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the button makes Tune the handler of every audio type', (
    tester,
  ) async {
    final service = FakeDefaultPlayerService();
    await openSettings(tester, service);

    // The card of the desktop sits below the fold of the pane.
    final button = find.text('设为默认播放器');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Every type the player understands is handed to the desktop, not just
    // the one the pane reads back.
    expect(service.madeDefault, supportedAudioMimeTypes);
    expect(find.text('已是默认播放器'), findsOneWidget);
    expect(find.text('Tune 已经是默认播放器了'), findsOneWidget);

    // The toast goes away on its own, so the test leaves no timer behind.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pane says when the desktop entry is missing', (
    tester,
  ) async {
    final service = FakeDefaultPlayerService(entryInstalled: false);
    await openSettings(tester, service);

    expect(
      find.text('还没有安装桌面项，先运行 linux/install-desktop-entry.sh'),
      findsOneWidget,
    );
    expect(find.text('已是默认播放器'), findsNothing);
    expect(tester.takeException(), isNull);
  });
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
