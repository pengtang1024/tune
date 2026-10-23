import 'package:tune/domain/models/music_source.dart';

/// The weight scale of the source list.
///
/// A higher number stands earlier. The local music is pinned at [local] and
/// never moves; every other source may be moved. The main list holds the
/// sources at or above [mainThreshold]; the rest wait in the folded
/// "More sources" group.
abstract final class SourceWeights {
  /// The fixed weight of the local music.
  static const int local = 1000;

  /// The boundary between the main list and the folded group.
  static const int mainThreshold = 500;

  /// The default weight of a built-in source that needs nothing from the
  /// reader.
  static const int featured = 800;

  /// The default weight of a source the reader added.
  static const int added = 700;

  /// The default weight of a built-in source that needs a key or a decision.
  static const int more = 400;

  /// The weight the source page uses for a configuration.
  ///
  /// A source that already has an explicit weight keeps it. A configuration
  /// written before the weight existed falls back to the default of its
  /// group, so the first run after the update does not lose the current
  /// placement.
  static int of(MusicSourceConfig source, {required bool isFeatured}) {
    if (source.isLocal) return local;

    final explicit = source.weight;
    if (explicit != null) return explicit.clamp(0, local - 1);

    if (!source.builtIn) return added;
    return isFeatured ? featured : more;
  }

  /// Whether a weight belongs in the folded group.
  static bool inMore(int weight) => weight < mainThreshold;
}
