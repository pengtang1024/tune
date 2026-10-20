import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/shared/ui/compact_spinner.dart';

/// The ring of the shell has to keep its stroke inside its own box.
///
/// The Material indicator draws the stroke centred on the path, so half of it
/// falls outside of the box and is cut away: the ring is thick on the
/// diagonals and thin at the top, the bottom and the sides. The test reads
/// the pixels of the ring and checks that the stroke has the same width all
/// the way around.
void main() {
  /// How much ink the ring puts on one row, split at the middle.
  ///
  /// The amount is counted in pixels of coverage, so a stroke that is cut
  /// in half by the edge of the box counts less than the stroke it was
  /// asked for.
  Future<(double left, double right)> inkOfRow(
    WidgetTester tester,
    GlobalKey key,
    int row,
  ) async {
    final ink = await tester.runAsync<(double, double)>(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final bytes = data.buffer.asUint8List();
      const width = 64;
      final rowStart = row * width * 4;
      var left = 0.0;
      var right = 0.0;
      for (var x = 0; x < width; x++) {
        final r = bytes[rowStart + x * 4];
        final g = bytes[rowStart + x * 4 + 1];
        final b = bytes[rowStart + x * 4 + 2];
        final a = bytes[rowStart + x * 4 + 3];
        if (a > 0 && !(r > 235 && g > 230 && b > 220)) {
          final cover = a / 255;
          if (x < width ~/ 2) {
            left += cover;
          } else {
            right += cover;
          }
        }
      }
      return (left, right);
    });
    return ink ?? (0.0, 0.0);
  }

  testWidgets('the ring keeps its stroke inside its own box', (tester) async {
    const stroke = CompactTokens.spinnerStrokeSmall;
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: CompactTheme.light,
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 64,
              height: 64,
              // A ring that is filled to the end paints every angle of the
              // circle, so the test reads the same pixels every time.
              child: Center(child: CompactSpinner.small(value: 1)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The middle of the box cuts the ring on its left and on its right.
    final (left, right) = await inkOfRow(tester, key, 32);
    expect(left, greaterThan(0), reason: 'the ring has to be painted');
    expect(
      left,
      closeTo(stroke, 0.4),
      reason: 'the stroke has to be whole on the left of the ring',
    );
    expect(
      right,
      closeTo(stroke, 0.4),
      reason: 'the stroke has to be whole on the right of the ring',
    );
  });

  testWidgets('the ring draws its stroke inside the box', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CompactSpinner.small())),
    );
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.strokeAlign, CircularProgressIndicator.strokeAlignInside);
    expect(indicator.strokeWidth, CompactTokens.spinnerStrokeSmall);
    expect(indicator.strokeCap, StrokeCap.round);
  });

  test('the scale holds one size per role', () {
    final sizes = <double>{
      CompactTypeScale.markDense,
      CompactTypeScale.mark,
      CompactTypeScale.micro,
      CompactTypeScale.label,
      CompactTypeScale.body,
      CompactTypeScale.strong,
      CompactTypeScale.title,
      CompactTypeScale.heading,
    };
    expect(sizes.length, 8, reason: 'two roles may not share a size');
    final sorted = sizes.toList()..sort();
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i] - sorted[i - 1], greaterThan(0));
    }
  });
}
