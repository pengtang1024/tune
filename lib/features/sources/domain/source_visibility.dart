import 'package:tune/features/sources/domain/source_health.dart';

/// The rule that decides which sources stay out of the library page.
///
/// One place decides it: the page, its counts and the source list all read this
/// result, so the header number and the rows can never disagree. The rule is
/// absolute — a score below [threshold] — and never a share of the sources, so
/// adding a healthy source cannot push a working one out.
class SourceVisibility {
  const SourceVisibility({
    this.threshold = defaultThreshold,
    this.alwaysVisible = const {},
    this.playingSourceId,
  });

  /// The score a source must reach to keep its rows in the library.
  ///
  /// A reader can loosen or tighten it in settings; it is stored, not
  /// recomputed from the library, so the same threshold always cuts the same.
  static const double defaultThreshold = 0.55;

  final double threshold;

  /// The sources the reader chose to keep, whatever their score.
  final Set<String> alwaysVisible;

  /// The source playing right now, kept so its row stays findable.
  final String? playingSourceId;

  /// The sources whose rows stay out of the library.
  ///
  /// A source is never hidden for a lack of evidence: a local directory, a
  /// source with no tracks, and one the reader pinned keep their rows even at
  /// a score of zero. An empty library never hides anything — otherwise the
  /// first scan would look like it found nothing.
  Set<String> hiddenOf({
    required Map<String, SourceHealthReport> reports,
    required Set<String> localSourceIds,
    required Set<String> sourcesWithTracks,
    required bool libraryIsEmpty,
    Set<String> sourcesWithEvidence = const {},
    bool enabled = true,
  }) {
    if (!enabled || libraryIsEmpty || threshold <= 0) return const {};
    final hidden = <String>{};
    for (final entry in reports.entries) {
      final id = entry.key;
      if (alwaysVisible.contains(id)) continue;
      if (id == playingSourceId) continue;
      if (localSourceIds.contains(id)) continue;
      if (!sourcesWithTracks.contains(id)) continue;
      // A source nobody scanned this session has no evidence to judge: it
      // waits, it is not hidden. Otherwise a start whose scans are all "not
      // due yet" would empty the page.
      if (sourcesWithEvidence.isNotEmpty &&
          !sourcesWithEvidence.contains(id)) {
        continue;
      }
      if (entry.value.score / 100 < threshold) hidden.add(id);
    }
    return hidden;
  }
}
