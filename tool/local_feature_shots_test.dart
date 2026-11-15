// Screenshot harness for the local feature cards (development tool).
//
// Run with:
//   flutter test tool/local_feature_shots_test.dart
//
// Writes one PNG per state to `build/local-feature-shots/`.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/data/services/system/machine_profile.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';
import 'package:tune/features/local_components/application/machine_profile_provider.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/presentation/settings_local_components_card.dart';
import 'package:tune/features/settings/presentation/settings_local_feature_card.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/settings_card_shell.dart';

import '../test/services/fake_persistence.dart';

var _rootKey = GlobalKey();

class _FakeComponents extends LocalComponentsController {
  _FakeComponents(this.states);

  final Map<String, LocalComponentState> states;

  @override
  Future<Map<String, LocalComponentState>> build() async => states;
}

Future<void> _loadFonts() async {
  const families = {
    'Fraunces': 'assets/fonts/Fraunces/Fraunces-Variable.ttf',
    'Instrument Sans':
        'assets/fonts/InstrumentSans/InstrumentSans-Variable.ttf',
    'JetBrains Mono': 'assets/fonts/JetBrainsMono/JetBrainsMono-Regular.ttf',
    'Noto Sans SC': 'assets/fonts/NotoSansSC/NotoSansSC-VF.ttf',
    'Noto Serif SC': 'assets/fonts/NotoSerifSC/NotoSerifSC-VF.ttf',
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        Future.value(File(entry.value).readAsBytesSync().buffer.asByteData()),
      );
    await loader.load();
  }
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    final boundary =
        _rootKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = (await image.toByteData(
      format: ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final file = File('build/local-feature-shots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

Map<String, LocalComponentState> _missing() => {
  for (final spec in LocalComponentRegistry.all)
    spec.id: const LocalComponentState(LocalComponentPhase.notInstalled),
};

void main() {
  setUpAll(_loadFonts);
  var scopes = 0;

  Future<void> pump(
    WidgetTester tester, {
    required Map<String, LocalComponentState> states,
    required Widget body,
  }) async {
    tester.view.physicalSize = const Size(900, 1250);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _rootKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        key: ValueKey('scope-${scopes++}'),
        overrides: [
          localComponentsControllerProvider.overrideWith(
            () => _FakeComponents(states),
          ),
          settingsControllerProvider.overrideWith(
            (ref) => SettingsController(FakePersistenceService()),
          ),
          machineProfileProvider.overrideWith(
            (ref) async => const MachineProfile(
              availableMemoryMb: 16384,
              freeDiskBytes: 100 * 1024 * 1024 * 1024,
              cores: 16,
            ),
          ),
        ],
        child: RepaintBoundary(
          key: _rootKey,
          child: MaterialApp(
            theme: CompactTheme.light,
            locale: const Locale('zh', 'CN'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(CompactTokens.space24),
                child: Center(
                  child: SizedBox(
                    width: 760,
                    child: Builder(
                      builder: (context) => SettingsPanel(
                        icon: settingsSectionIcon(SettingsSection.components),
                        title: settingsSectionLabel(
                          context,
                          SettingsSection.components,
                        ),
                        child: body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the four local feature states', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await pump(
      tester,
      states: _missing(),
      body: const SettingsLocalComponentsCard(),
    );
    await _shot(tester, '1-default');

    await tester.tap(
      find.byKey(const ValueKey('feature-details-translation')),
    );
    await tester.pumpAndSettle();
    await _shot(tester, '2-details');

    final partial = _missing();
    partial[LocalComponentRegistry.translationRuntime.id] =
        const LocalComponentState(
          LocalComponentPhase.ready,
          installedBytes: 38 * 1024 * 1024,
          canDelete: true,
        );
    await pump(
      tester,
      states: partial,
      body: const SettingsLocalComponentsCard(),
    );
    await _shot(tester, '4-partial');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the recommended tier of the translation card', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await pump(
      tester,
      states: _missing(),
      body: SettingsLocalFeatureCard(
        feature: LocalFeatureRegistry.translation,
      ),
    );
    await _shot(tester, '3-recommended');
    debugDefaultTargetPlatformOverride = null;
  });
}
