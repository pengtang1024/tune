// Development tool: writes a picture of the tooltip of the app.
//
//   flutter test tool/tooltip_shots_test.dart --update-goldens
//
// The pictures land in `build/tooltip-shots/`. The scene borrows the colours,
// the faces and the icons of the app, so the hint is seen the way a reader
// meets it and not as a chip on an empty page.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

void main() {
  setUpAll(_loadFaces);

  testWidgets('the tooltip of the light theme', (tester) async {
    await _shoot(tester, Brightness.light, 'tooltip_light.png');
  });

  testWidgets('the tooltip of the dark theme', (tester) async {
    await _shoot(tester, Brightness.dark, 'tooltip_dark.png');
  });
}

/// Puts the faces of the app into the test renderer.
///
/// Without them every word is drawn as a box, and a picture of the app says
/// nothing about how the app looks.
Future<void> _loadFaces() async {
  await _load('Instrument Sans', 'assets/fonts/InstrumentSans/InstrumentSans-Variable.ttf');
  await _load('Noto Sans SC', 'assets/fonts/NotoSansSC/NotoSansSC-Regular.ttf');
  await _load('Fraunces', 'assets/fonts/Fraunces/Fraunces-Variable.ttf');
  await _loadIcons();
}

Future<void> _load(String family, String path) async {
  final loader = FontLoader(family);
  loader.addFont(rootBundle.load(path));
  await loader.load();
}

/// Puts the icons of the framework into the test renderer.
///
/// The icons live in the Flutter SDK, not in the assets of the app, so the
/// face is taken from the SDK that runs the test. The icons carry the name of
/// the package they live in, so both names are registered.
Future<void> _loadIcons() async {
  var root = File(Platform.resolvedExecutable).parent;
  for (var step = 0; step < 4; step++) {
    root = root.parent;
  }

  final file = File(
    '${root.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;

  final bytes = await file.readAsBytes();
  for (final family in ['MaterialIcons', 'packages/flutter/MaterialIcons']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

/// Hovers a button of the player and writes the picture.
Future<void> _shoot(
  WidgetTester tester,
  Brightness brightness,
  String name,
) async {
  tester.view.physicalSize = const Size(560, 320);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final theme =
      brightness == Brightness.dark ? CompactTheme.dark : CompactTheme.light;
  final isDark = brightness == Brightness.dark;

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF191713)
                  : const Color(0xFFFBF7F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2C2822)
                    : const Color(0xFFD9D0C2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2620)
                            : const Color(0xFF2A2620),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '夜曲',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '某歌手 · 2026',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? const Color(0xFFA59B8C)
                                  : const Color(0xFF746C60),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '播放队列',
                      icon: const Icon(Icons.queue_music_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '上一首',
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    TuneTooltip(
                      message: '播放',
                      child: IconButton.filled(
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '下一首',
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(find.byIcon(Icons.skip_next_rounded)));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 200));

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../build/tooltip-shots/$name'),
  );
}
