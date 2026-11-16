import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// How many covers a wall of the library puts in one row.
///
/// The grid packs the covers as tightly as the page allows, bounded by the
/// longest side of a cover ([maxCover]) so a wide window still gets a wall
/// instead of a single card per screen. A page narrower than the rail
/// breakpoint is fixed at three columns: four of them squeeze a cover down to
/// about 110 pixels and every album name ends in "100 Masterpiece…", which is
/// the controls talking louder than the content.
///
/// The page width, not the window width, is what decides: the 600–799 band
/// still carries a 76-pixel icon rail, so the page is narrower than the
/// window. The result is what [wallCellWidth] divides the row into.
int libraryWallColumns(double pageWidth, {double maxCover = 128}) {
  if (pageWidth < LayoutBreakpoints.railCompactMaxWidth) return 3;
  final inner = pageWidth - CompactTokens.pageGutter * 2;
  final spacing = CompactTokens.space12;
  return ((inner + spacing) / (maxCover + spacing)).ceil().clamp(2, 10);
}

/// The width of one cover in a row of [columns] on a page of [pageWidth].
double wallCellWidth(double pageWidth, int columns) {
  final inner = pageWidth - CompactTokens.pageGutter * 2;
  final spacing = CompactTokens.space12;
  return (inner - spacing * (columns - 1)) / columns;
}
