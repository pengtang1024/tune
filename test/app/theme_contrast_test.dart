import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';

/// The guard for the colours of the shell.
///
/// The shell is a light one, so the colours that carry words have to be
/// checked against the paper they sit on. The check is the ratio of the
/// contrast of WCAG 2.1: four and a half to one is the line for ordinary
/// text, and three to one is the line for a large one.
///
/// A ratio of the colours alone is not the whole story. A thin stroke never
/// reaches the colour it is drawn in, so a small letter loses a tenth of its
/// contrast on the way to the paper. The bar here is therefore the one of
/// the ratio, and the palette is dark enough that the drawn letter keeps
/// four and a half as well.
void main() {
  group('the light shell', () {
    final scheme = CompactTheme.light.colorScheme;

    test('the text colours clear the bar on every surface', () {
      final surfaces = <String, Color>{
        'the page': scheme.surface,
        'the card': scheme.surfaceContainer,
        'the raised card': scheme.surfaceContainerHigh,
        'the highest card': scheme.surfaceContainerHighest,
        'the sunken card': scheme.surfaceContainerLow,
      };
      final inks = <String, Color>{
        'the text': scheme.onSurface,
        'the second hand text': scheme.onSurfaceVariant,
        'the accent': scheme.primary,
        'the alarm': scheme.error,
      };
      for (final surface in surfaces.entries) {
        for (final ink in inks.entries) {
          expect(
            _contrast(ink.value, surface.value),
            greaterThanOrEqualTo(4.5),
            reason:
                '${ink.key} on ${surface.key} has to clear four and a half to one',
          );
        }
      }
    });

    test('white reads on the accent and on the alarm', () {
      expect(_contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
    });
  });

  group('the dark shell', () {
    final scheme = CompactTheme.dark.colorScheme;

    test('the text colours clear the bar on every surface', () {
      final surfaces = <String, Color>{
        'the page': scheme.surface,
        'the card': scheme.surfaceContainer,
        'the raised card': scheme.surfaceContainerHigh,
        'the highest card': scheme.surfaceContainerHighest,
        'the sunken card': scheme.surfaceContainerLow,
      };
      final inks = <String, Color>{
        'the text': scheme.onSurface,
        'the second hand text': scheme.onSurfaceVariant,
        'the accent': scheme.primary,
        'the alarm': scheme.error,
      };
      for (final surface in surfaces.entries) {
        for (final ink in inks.entries) {
          expect(
            _contrast(ink.value, surface.value),
            greaterThanOrEqualTo(4.5),
            reason:
                '${ink.key} on ${surface.key} has to clear four and a half to one',
          );
        }
      }
    });

    test('the label on the accent and on the alarm reads', () {
      expect(_contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
      expect(_contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
    });
  });
}

/// The contrast of two colours, as WCAG 2.1 counts it.
double _contrast(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

/// The relative luminance of a colour.
///
/// The framework already counts it the way WCAG does, with the sRGB curve
/// and the 0.05 offset of the ratio.
double _luminance(Color color) => color.computeLuminance();
