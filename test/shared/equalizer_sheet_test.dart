import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/equalizer_sheet.dart';

/// Guards the two equalizer panels.
///
/// The player opens a short panel — a switch and four curves — and the settings
/// page opens the full editor. Both are the only surfaces of the feature, so
/// what each draws, the band a drag belongs to, and the frozen shape of a
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

  const quickLabels = <String>['平坦', '流行', '摇滚', '重低音'];

  const editorOnlyLabels = <String>[
    '爵士',
    '古典',
    '原声',
    '人声',
    '嘻哈',
    '电子',
    '现场',
    '轻柔',
  ];

  const quickHint = '更细的频段和全部预设见 设置 › 播放';

  Future<void> pumpPanel(
    WidgetTester tester, {
    required void Function(BuildContext context) open,
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
                onPressed: () => open(context),
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

  /// Opens the panel the player opens, through the shipping entry point.
  Future<void> openQuickPanel(
    WidgetTester tester, {
    EqualizerSettings settings = const EqualizerSettings.flat(enabled: true),
    bool available = true,
    ValueChanged<bool>? onEnabledChanged,
    ValueChanged<String>? onPresetChanged,
  }) {
    return pumpPanel(
      tester,
      open: (context) => showEqualizerQuickPanel(
        context,
        settings: settings,
        available: available,
        onEnabledChanged: onEnabledChanged ?? (enabled) {},
        onPresetChanged: onPresetChanged ?? (presetId) {},
      ),
    );
  }

  /// Opens the panel the settings page opens.
  Future<void> openEditorPanel(
    WidgetTester tester, {
    EqualizerSettings settings = const EqualizerSettings.flat(enabled: true),
    bool available = true,
    ValueChanged<bool>? onEnabledChanged,
    void Function(int band, double gain)? onGainChanged,
    ValueChanged<String>? onPresetChanged,
    VoidCallback? onReset,
  }) {
    return pumpPanel(
      tester,
      open: (context) => showEqualizerEditorPanel(
        context,
        settings: settings,
        available: available,
        onEnabledChanged: onEnabledChanged ?? (enabled) {},
        onGainChanged: onGainChanged ?? (band, gain) {},
        onPresetChanged: onPresetChanged ?? (presetId) {},
        onReset: onReset ?? () {},
      ),
    );
  }

  testWidgets('the quick panel draws four curves and no sliders', (
    tester,
  ) async {
    await openQuickPanel(tester);

    expect(find.text('均衡器'), findsOneWidget);
    expect(find.text('启用均衡器'), findsOneWidget);
    expect(find.text(quickHint), findsOneWidget);
    expect(
      find.text('重置'),
      findsNothing,
      reason: 'resetting a curve belongs to the editor, not to the player',
    );

    for (final label in quickLabels) {
      expect(
        find.descendant(
          of: find.byType(ChoiceChip),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'the curve $label is one tap away from the player',
      );
    }
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    expect(
      find.byType(Slider),
      findsNothing,
      reason: 'ten sliders do not fit beside a track row',
    );
    for (final label in editorOnlyLabels) {
      expect(
        find.text(label),
        findsNothing,
        reason: 'the rest of the curves live in the settings editor',
      );
    }
  });

  testWidgets('a curve picked in the quick panel is reported', (tester) async {
    final picked = <String>[];
    await openQuickPanel(tester, onPresetChanged: picked.add);

    await tester.tap(
      find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('摇滚'),
      ),
    );
    await tester.pumpAndSettle();

    expect(picked, <String>[EqualizerPresets.rockId]);
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((chip) => chip.selected)
        .map((chip) => (chip.label as Text).data);
    expect(
      selected,
      <String>['摇滚'],
      reason: 'the chip keeps the shape it was tapped into',
    );
  });

  testWidgets('a curve moved by hand is marked as custom', (tester) async {
    await openQuickPanel(
      tester,
      settings: const EqualizerSettings(
        enabled: true,
        gains: <double>[3, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    );

    expect(
      find.descendant(of: find.byType(Chip), matching: find.text('自定义')),
      findsOneWidget,
      reason: 'a hand-moved curve matches no chip, and the panel says so',
    );
    expect(
      find.descendant(of: find.byType(ChoiceChip), matching: find.text('平坦')),
      findsOneWidget,
      reason: 'the chips stay available, none of them is lit',
    );
  });

  testWidgets('the editor draws the ten bands and every curve', (
    tester,
  ) async {
    await openEditorPanel(tester);

    expect(find.text('均衡器'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
    expect(find.text('提升的频段会用等量预放抵消，避免削波'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(12));
    expect(find.byType(Slider), findsNWidgets(10));

    for (final label in <String>[...quickLabels, ...editorOnlyLabels]) {
      expect(
        find.descendant(
          of: find.byType(ChoiceChip),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'the curve $label has its own chip',
      );
    }
    for (final frequency in frequencies) {
      expect(
        find.text('$frequency Hz'),
        findsOneWidget,
        reason: 'each band says the frequency it acts on',
      );
    }
  });

  testWidgets('dragging a slider reports the band it belongs to', (
    tester,
  ) async {
    final changes = <(int, double)>[];
    await openEditorPanel(
      tester,
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

  testWidgets('a platform without a backend shows why and takes no change', (
    tester,
  ) async {
    var presetCalls = 0;
    var gainCalls = 0;

    await openEditorPanel(
      tester,
      available: false,
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
    expect(chips.length, 12);
    expect(
      chips.every((chip) => chip.onSelected == null),
      isTrue,
      reason: 'a preset that cannot sound is not offered',
    );

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
