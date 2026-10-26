import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_typography.dart';

/// Guards the font fallbacks of the theme.
///
/// A family the app does not ship is looked up through the font system for
/// every style that names it. On a Linux desktop with a few hundred fonts
/// installed, five such names cost the first frame 1.7 seconds
/// ([performance.md](../../docs/performance.md)), so the lists name the faces
/// that ship with the app and end with one generic family as the last resort.
void main() {
  test('every fallback family ships with the app', () {
    final bundled = _bundledFamilies();

    for (final family in _allFallbacks) {
      if (_genericFamilies.contains(family)) continue;
      expect(
        bundled,
        contains(family),
        reason:
            '$family is not in the fonts of pubspec.yaml: the engine would '
            'ask the desktop for it once per text style on the first frame',
      );
    }
  });

  test('each list ends with one generic family, not a pile of names', () {
    expect(CompactTypography.sansFallback.last, 'sans-serif');
    expect(CompactTypography.serifFallback.last, 'serif');
    expect(CompactTypography.monoFallback.last, 'sans-serif');

    expect(CompactTypography.sansFallback.length, lessThanOrEqualTo(2));
    expect(CompactTypography.serifFallback.length, lessThanOrEqualTo(2));
    expect(CompactTypography.monoFallback.length, lessThanOrEqualTo(2));
  });

  test('the fallback of a kind names the bundled face of that kind', () {
    expect(CompactTypography.sansFallback.first, 'Noto Sans SC');
    expect(CompactTypography.serifFallback.first, 'Noto Serif SC');
    expect(
      CompactTypography.monoFallback.first,
      'Noto Sans SC',
      reason: 'the monospaced labels read Chinese in the interface face',
    );
  });
}

List<String> get _allFallbacks => [
  ...CompactTypography.sansFallback,
  ...CompactTypography.serifFallback,
  ...CompactTypography.monoFallback,
];

const Set<String> _genericFamilies = {'sans-serif', 'serif', 'monospace'};

/// The families the fonts of `pubspec.yaml` ship with the app.
Set<String> _bundledFamilies() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final pattern = RegExp(r'^\s*- family: (.+)$', multiLine: true);
  return {
    for (final match in pattern.allMatches(pubspec)) match.group(1)!.trim(),
  };
}
