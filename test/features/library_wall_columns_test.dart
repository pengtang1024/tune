import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/features/library/presentation/library_wall_columns.dart';

/// 封面墙的列数只有一处算法：页宽窄于 800 固定三列，再宽按封面最长边塞，
/// 上下夹在 2–10 列之间。
void main() {
  test('a narrow page puts three covers in a row', () {
    for (final width in const [560.0, 600.0, 704.0, 799.0]) {
      expect(
        libraryWallColumns(width),
        3,
        reason: '$width 宽的页面挤四列，封面会掉到 110 像素上下',
      );
    }
  });

  test('the wall keeps the cover of a narrow page readable', () {
    // 560 的窗口：整页 560，左右各 24 的内边距，三列两张 12 的缝。
    final cell = wallCellWidth(560, 3);
    expect(cell, greaterThan(150), reason: '窄页的封面不该比手机上的还小');
    expect(
      libraryWallColumns(560) * cell + 12 * 2,
      lessThanOrEqualTo(560 - 48),
    );
  });

  test('a wide page packs the covers by their longest side', () {
    expect(libraryWallColumns(LayoutBreakpoints.railCompactMaxWidth), 6);
    expect(libraryWallColumns(1280), 9);
    // 超宽屏不把封面铺成一条线：列数封顶 10。
    expect(libraryWallColumns(2000), 10);
  });
}
