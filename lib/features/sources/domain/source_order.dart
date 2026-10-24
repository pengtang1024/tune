import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/domain/source_health.dart';

/// Orders [sources] by health band, keeping the input order inside a band.
///
/// The input is expected to be in the reader's weight order (the source
/// controller keeps it that way). A source with no report is treated as the
/// lowest band so an unknown source does not jump ahead of a measured one.
List<MusicSourceConfig> orderSourcesByBand(
  List<MusicSourceConfig> sources,
  Map<String, SourceHealthReport> health,
) {
  final indexed = sources.indexed.toList()
    ..sort((left, right) {
      final byBand = (health[right.$2.id]?.band ?? 0).compareTo(
        health[left.$2.id]?.band ?? 0,
      );
      if (byBand != 0) return byBand;
      return left.$1.compareTo(right.$1);
    });
  return [for (final entry in indexed) entry.$2];
}
