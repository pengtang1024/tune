import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/equalizer_sheet.dart';

/// Guards the equalizer panel.
///
/// The panel is the only surface of the feature and two pages open it, so the
/// bands it draws, the band a drag belongs to, and the frozen shape of a
/// platform without a backend are all worth a test.
void main() {
  const frequencies = <String>[
    '31',
    '62',
    '125',
    '250',
    '500',
    '1000',
    '2000',
    '4000',
    '8000',
    '16000',
  ];

  const presetLabels = <String>[
    '平坦',
    '流行',
    '摇滚',
    '爵士',
    '古典',
    '重低音',
    '人声',
    '电子',
  ];

  /// Opens the panel the way the player and the settings page do: through
  /// [showEqualizerPanel], so the sheet under test is the one that ships.
  Future<void> openPanel(
    WidgetTester tester, {
    required EqualizerSettings settings,
    bool available = true,
    ValueChanged<bool>? onEnabledChanged,
    void Function(int band, double gain)? onGainChanged,
    ValueChanged<String>? onPresetChanged,
    VoidCallback? onReset,
  }) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showEqualizerPanel(
                  context,
                  settings: settings,
                  available: available,
                  onEnabledChanged: onEnabledChanged ?? (enabled) {},
                  onGainChanged: onGainChanged ?? (band, gain) {},
                  onPresetChanged: onPresetChanged ?? (presetId) {},
                  onReset: onReset ?? () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the panel draws the ten bands and the eight curves', (
    tester,
  ) async {
    await openPanel(
      tester,
      settings: const EqualizerSettings(
        enabled: true,
        gains: <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    );

    expect(find.text('均衡器'), findsOneWidget);
    expect(find.text('启用均衡器'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
    expect(find.text('提升的频段会用等量预放抵消，避免削波'), findsOneWidget);

    for (final frequency in frequencies) {
      expect(
        find.text('$frequency Hz'),
        findsOneWidget,
        reason: 'each band says the frequency it acts on',
      );
    }

    expect(find.byType(Slider), findsNWidgets(10));
    expect(find.byType(ChoiceChip), findsNWidgets(8));
    for (final label in presetLabels) {
      expect(
        find.descendant(
          of: find.byType(ChoiceChip),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'the curve $label has its own chip',
      );
    }
    expect(
      find.text('自定义'),
      findsNothing,
      reason: 'a flat curve is a preset, not a hand-moved one',
    );
  });

  testWidgets('dragging a slider reports the band it belongs to', (
    tester,
  ) async {
    final changes = <(int, double)>[];
    await openPanel(
      tester,
      settings: const EqualizerSettings.flat(),
      onGainChanged: (band, gain) => changes.add((band, gain)),
    );

    final band = find.byKey(const ValueKey<String>('equalizer-band-3'));
    expect(band, findsOneWidget);

    // The slider is turned on its end, so a drag towards the top of the window
    // is a drag to the right for the slider itself.
    await tester.drag(band, const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty, reason: 'the drag reaches the panel');
    expect(
      changes.every((change) => change.$1 == 3),
      isTrue,
      reason: 'only the dragged band moves',
    );
    expect(
      changes.last.$2,
      greaterThan(0),
      reason: 'a drag towards the top of the window raises the gain',
    );
  });

  testWidgets('a curve moved by hand is marked as custom', (tester) async {
    await openPanel(
      tester,
      settings: EqualizerSettings(
        enabled: true,
        gains: EqualizerSettings.normalizeGains(<double>[
          3,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ]),
      ),
    );

    expect(
      find.descendant(of: find.byType(Chip), matching: find.text('自定义')),
      findsOneWidget,
      reason: 'the hand-moved curve is marked at the end of the chips',
    );
    expect(
      find.descendant(of: find.byType(ChoiceChip), matching: find.text('平坦')),
      findsOneWidget,
      reason: 'the chips stay available, none of them is lit',
    );
  });

  testWidgets('a platform without a backend shows why and takes no change', (
    tester,
  ) async {
    var enabledCalls = 0;
    var gainCalls = 0;
    var presetCalls = 0;

    await openPanel(
      tester,
      settings: const EqualizerSettings.flat(enabled: true),
      available: false,
      onEnabledChanged: (enabled) => enabledCalls++,
      onGainChanged: (band, gain) => gainCalls++,
      onPresetChanged: (presetId) => presetCalls++,
    );

    expect(find.text('这个平台的播放后端不支持均衡器'), findsOneWidget);

    final sliders = tester.widgetList<Slider>(find.byType(Slider));
    expect(sliders.length, 10);
    expect(
      sliders.every((slider) => slider.onChanged == null),
      isTrue,
      reason: 'a slider that cannot sound is not draggable',
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.length, 8);
    expect(
      chips.every((chip) => chip.onSelected == null),
      isTrue,
      reason: 'a preset that cannot sound is not offered',
    );

    // The switch of the shared row has no disabled state of its own, so the
    // panel has to prove that a tap on it writes nothing.
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(enabledCalls, 0);

    await tester.tap(
      find.byKey(const ValueKey<String>('equalizer-band-5')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(gainCalls, 0);

    await tester.tap(find.byType(ChoiceChip).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(presetCalls, 0);
  });
}
