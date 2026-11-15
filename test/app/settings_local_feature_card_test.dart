import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/system/machine_profile.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/local_components/application/machine_profile_provider.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_local_components_card.dart';
import 'package:tune/l10n/app_localizations.dart';

import '../services/fake_persistence.dart';

/// The components controller the card reads, without a disk or a network.
class _FakeController extends LocalComponentsController {
  _FakeController(this.states);

  final Map<String, LocalComponentState> states;
  final List<String> downloaded = [];

  @override
  Future<Map<String, LocalComponentState>> build() async => states;

  @override
  Future<bool> download(String id) async {
    downloaded.add(id);
    return true;
  }
}

Map<String, LocalComponentState> allMissing() => {
  for (final spec in LocalComponentRegistry.all)
    spec.id: const LocalComponentState(LocalComponentPhase.notInstalled),
};

/// One card per feature, the tiers behind it, and the detail list folded away
/// (docs/local-components.md §7.1).
void main() {
  const strong = MachineProfile(
    availableMemoryMb: 16384,
    freeDiskBytes: 100 * 1024 * 1024 * 1024,
    cores: 16,
  );

  Future<void> pump(
    WidgetTester tester, {
    required Map<String, LocalComponentState> states,
    MachineProfile profile = strong,
    _FakeController? controller,
  }) async {
    final fake = controller ?? _FakeController(states);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localComponentsControllerProvider.overrideWith(() => fake),
          settingsControllerProvider.overrideWith(
            (ref) => SettingsController(FakePersistenceService()),
          ),
          machineProfileProvider.overrideWith((ref) async => profile),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: SettingsLocalComponentsCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the page shows one card per feature the platform can run', (
    tester,
  ) async {
    await pump(tester, states: allMissing());

    expect(
      find.byKey(const ValueKey('feature-card-translation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feature-card-lyrics')), findsOneWidget);
    expect(find.byKey(const ValueKey('feature-card-transcode')), findsOneWidget);
    expect(find.text('翻译'), findsOneWidget);
    expect(find.text('智能歌词（本地出词）'), findsOneWidget);
  });

  testWidgets('the machine recommendation marks a tier and selects it', (
    tester,
  ) async {
    await pump(tester, states: allMissing());

    expect(
      find.byKey(const ValueKey('feature-recommended-translation')),
      findsOneWidget,
    );
    expect(find.text('推荐：适合本机'), findsWidgets);
  });

  testWidgets('when nothing is measured the mark claims no machine', (
    tester,
  ) async {
    await pump(
      tester,
      states: allMissing(),
      profile: const MachineProfile(cores: 4),
    );

    expect(find.text('默认：适合多数电脑'), findsWidgets);
    expect(find.text('推荐：适合本机'), findsNothing,
        reason: 'a value the probe could not read is never shown as a fact');
  });

  testWidgets('the technical list stays folded until asked', (tester) async {
    await pump(tester, states: allMissing());

    expect(
      find.byKey(const ValueKey('component-status-translation-runtime')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('feature-details-translation')),
    );
    await tester.pumpAndSettle();

    expect(find.text('llama.cpp 运行时（llama-cli）'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('component-status-translation-runtime')),
      findsOneWidget,
    );
  });

  testWidgets('a half finished feature offers to continue, not to restart', (
    tester,
  ) async {
    final states = allMissing();
    states[LocalComponentRegistry.translationRuntime.id] =
        const LocalComponentState(
          LocalComponentPhase.ready,
          installedBytes: 1024,
          canDelete: true,
        );
    await pump(tester, states: states);

    expect(find.textContaining('部分完成'), findsOneWidget);
    expect(find.textContaining('继续'), findsOneWidget);
    expect(find.text('安装'), findsWidgets,
        reason: 'the other features still start from scratch');
  });

  testWidgets('picking a lyrics tier before installing keeps the pick', (
    tester,
  ) async {
    await pump(tester, states: allMissing());

    final small = find.byKey(const ValueKey('feature-tier-lyrics-small'));
    await tester.ensureVisible(small);
    await tester.pumpAndSettle();
    await tester.tap(small);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: small,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
      reason: 'the recommendation must not pull the choice back',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('feature-tier-lyrics-large-v3-turbo')),
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsNothing,
    );
  });

  testWidgets('the technical list hides parts another platform owns', (
    tester,
  ) async {
    await pump(tester, states: allMissing());

    final details = find.byKey(const ValueKey('feature-details-lyrics'));
    await tester.ensureVisible(details);
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('component-status-lyrics-whisper-onnx-model-small'),
      ),
      findsNothing,
      reason: 'an Android-only engine has no place in a Linux install',
    );
    expect(
      find.byKey(const ValueKey('component-status-lyrics-sherpa-runtime')),
      findsOneWidget,
    );
  });

  testWidgets('a system ffmpeg still offers a bundled copy', (tester) async {
    final states = allMissing();
    states[LocalComponentRegistry.ffmpeg.id] = const LocalComponentState(
      LocalComponentPhase.notInstalled,
      systemAvailable: true,
    );
    final controller = _FakeController(states);
    await pump(tester, states: states, controller: controller);

    expect(find.text('使用系统已安装版本'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feature-system-note-transcode')),
      findsOneWidget,
      reason: 'the card says the system binary comes first',
    );
    expect(
      find.byKey(const ValueKey('feature-action-transcode')),
      findsNothing,
      reason: 'nothing is missing, so there is no install to repeat',
    );

    final bundled = find.byKey(const ValueKey('feature-bundled-transcode'));
    await tester.ensureVisible(bundled);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bundled, matching: find.textContaining('自带的')),
      findsOneWidget,
    );

    await tester.tap(bundled);
    await tester.pumpAndSettle();

    expect(controller.downloaded, ['ffmpeg'],
        reason: 'the fallback goes through the same download and check');
  });
}
