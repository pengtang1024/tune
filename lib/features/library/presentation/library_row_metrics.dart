import 'package:flutter/widgets.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';

/// What a row of the library table shows at a given width and text scale.
///
/// The viewport resolves this once. A row does not ask the layout for its
/// width, does not decide on its own which columns fit, and does not rebuild
/// a layout callback for every track: it reads three booleans and a height.
@immutable
class LibraryRowMetrics {
  /// Whether the artist column fits.
  final bool showArtist;

  /// Whether the facts of the file fit.
  final bool showFacts;

  /// Whether the album column fits.
  final bool showAlbum;

  /// The height the list may assume, or null when the text can grow.
  ///
  /// A fixed extent lets the list compute its offsets without laying out
  /// every row it has not built yet. At a larger text scale the row has to
  /// grow, so the extent steps aside.
  final double? extent;

  const LibraryRowMetrics({
    required this.showArtist,
    required this.showFacts,
    required this.showAlbum,
    this.extent,
  });

  @override
  bool operator ==(Object other) =>
      other is LibraryRowMetrics &&
      other.showArtist == showArtist &&
      other.showFacts == showFacts &&
      other.showAlbum == showAlbum &&
      other.extent == extent;

  @override
  int get hashCode => Object.hash(showArtist, showFacts, showAlbum, extent);

  /// The metrics of a row that is [width] wide at [textScale].
  factory LibraryRowMetrics.at({
    required double width,
    required double textScale,
  }) {
    return LibraryRowMetrics(
      // The album is the first column to go, then the facts of the file.
      // A narrow window keeps the artist and the time, because those are
      // what tell two tracks apart.
      showArtist: width >= 480,
      showFacts: width >= 600,
      showAlbum: width >= 820,
      extent: (textScale - 1.0).abs() < 0.01
          ? CompactTokens.libraryRowHeight
          : null,
    );
  }

  /// The metrics of the viewport that holds [context].
  ///
  /// The width is the width of a row, not of the page: the caller subtracts
  /// the gutter the list keeps on both sides.
  factory LibraryRowMetrics.of(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final strong = CompactTypeScale.strong;
    return LibraryRowMetrics.at(
      width: width,
      textScale: scaler.scale(strong) / strong,
    );
  }
}
