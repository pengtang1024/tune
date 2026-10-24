import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/domain/models/source_health_weights.dart';
import 'package:tune/features/sources/domain/source_scan_health.dart';

/// One source's health, split into the dimensions that built the score.
///
/// Each field is the dimension's own completion percentage (0–100); the score
/// is the weighted sum. The score is a gate, not a second order: a source
/// below [threshold] waits in the folded group even when its manual weight
/// would put it in the main list.
class SourceHealthReport {
  final int availability;
  final int configuration;
  final int scan;
  final int freshness;
  final int output;
  final int speed;
  final int reliability;
  final int stability;
  final int playable;
  final int artwork;
  final int metadata;
  final int activity;
  final int score;
  final bool healthy;

  /// The coarse health band that decides the order of the source list.
  ///
  /// A higher band stands before a lower one; the manual weight decides the
  /// order inside a band. The bands are deliberately coarse so a small health
  /// difference does not override the reader's own order.
  int get band => SourceHealth.bandOf(score);

  const SourceHealthReport({
    required this.availability,
    required this.configuration,
    required this.scan,
    required this.freshness,
    required this.output,
    required this.speed,
    required this.reliability,
    required this.stability,
    required this.playable,
    required this.artwork,
    required this.metadata,
    required this.activity,
    required this.score,
    required this.healthy,
  });

  const SourceHealthReport.unavailable()
    : availability = 0,
      configuration = 0,
      scan = 0,
      freshness = 0,
      output = 0,
      speed = 0,
      reliability = 0,
      stability = 0,
      playable = 0,
      artwork = 0,
      metadata = 0,
      activity = 0,
      score = 0,
      healthy = false;
}

/// Scores how usable a source is right now.
///
/// Twelve dimensions make the score; [SourceHealthWeights] says how much each
/// one matters. The hard gates (unavailable, unconfigured, failed, local) are
/// independent of the weights.
abstract final class SourceHealth {
  static const int threshold = 60;

  /// The lower edge of the top band: sources at or above it stand before
  /// the middle band regardless of their manual weight.
  static const int highBand = 85;

  /// The lower edge of the middle band.
  static const int mediumBand = 70;

  /// The band of a score: 2 for [highBand] and above, 1 for [mediumBand] and
  /// above, 0 for the rest of the main list.
  static int bandOf(int score) {
    if (score >= highBand) return 2;
    if (score >= mediumBand) return 1;
    return 0;
  }

  static SourceHealthReport report({
    required bool isLocal,
    required bool enabled,
    required bool supported,
    required bool configured,
    required SourceScanSummary? summary,
    required DateTime? lastScanAt,
    required Duration autoScanInterval,
    required Duration scanTimeout,
    SourceHealthWeights weights = SourceHealthWeights.defaults,
    SourceScanHealthHistory? history,
    DateTime? now,
    bool hasTracks = false,
    int? expectedCount,
    double playable = 0.5,
    double artwork = 0.5,
    double metadata = 0.5,
    double activity = 0.5,
  }) {
    if (isLocal) {
      return const SourceHealthReport(
        availability: 100,
        configuration: 100,
        scan: 100,
        freshness: 100,
        output: 100,
        speed: 100,
        reliability: 100,
        stability: 100,
        playable: 100,
        artwork: 100,
        metadata: 100,
        activity: 100,
        score: 100,
        healthy: true,
      );
    }

    if (!supported || !enabled) {
      return const SourceHealthReport.unavailable();
    }

    final availability = 1.0;
    final configuration = configured ? 1.0 : 0.0;
    final scan = switch (summary?.status) {
      SourceScanStatus.success => 1.0,
      SourceScanStatus.skipped => 0.75,
      SourceScanStatus.failed => 0.0,
      SourceScanStatus.needsConfiguration => 0.0,
      null => 0.5,
    };

    // A successful scan that just finished is the freshest fact; a failed
    // one leaves the last success as the timestamp that matters.
    final clock = now ?? DateTime.now();
    final freshnessAt = summary?.status == SourceScanStatus.success
        ? summary!.scannedAt
        : lastScanAt;
    final freshness = _freshness(freshnessAt, autoScanInterval, clock);
    final output = _output(summary, expectedCount);
    final speed = _speed(summary, scanTimeout);
    final reliability = switch (summary?.status) {
      SourceScanStatus.success => 1.0,
      SourceScanStatus.skipped => 0.66,
      SourceScanStatus.failed => 0.0,
      SourceScanStatus.needsConfiguration => 0.0,
      null => lastScanAt == null ? 0.5 : 0.66,
    };
    final stability = history?.stabilityRate ?? 0.5;
    final playableRate = playable.clamp(0.0, 1.0);
    final artworkRate = artwork.clamp(0.0, 1.0);
    final metadataRate = metadata.clamp(0.0, 1.0);
    final activityRate = activity.clamp(0.0, 1.0);

    final totalWeight = weights.total;
    final weighted =
        availability * weights.availability +
        configuration * weights.configuration +
        scan * weights.scan +
        freshness * weights.freshness +
        output * weights.output +
        speed * weights.speed +
        reliability * weights.reliability +
        stability * weights.stability +
        playableRate * weights.playable +
        artworkRate * weights.artwork +
        metadataRate * weights.metadata +
        activityRate * weights.activity;

    var score = totalWeight <= 0 ? 0 : (weighted / totalWeight * 100).round();
    if (!configured) score = score.clamp(0, 40);
    if (summary?.status == SourceScanStatus.failed ||
        summary?.status == SourceScanStatus.needsConfiguration) {
      score = score.clamp(0, 55);
    }
    // A source with tracks but no cover at all waits in More: the main list
    // is a visual list, and a whole row of grey cards is worse than one more
    // fold. One cover is enough to lift the cap.
    if (hasTracks && artworkRate <= 0) {
      score = score.clamp(0, 55);
    }

    return SourceHealthReport(
      availability: _percent(availability),
      configuration: _percent(configuration),
      scan: _percent(scan),
      freshness: _percent(freshness),
      output: _percent(output),
      speed: _percent(speed),
      reliability: _percent(reliability),
      stability: _percent(stability),
      playable: _percent(playableRate),
      artwork: _percent(artworkRate),
      metadata: _percent(metadataRate),
      activity: _percent(activityRate),
      score: score,
      healthy: score >= threshold,
    );
  }

  static int _percent(double rate) => (rate * 100).round();

  static double _freshness(
    DateTime? lastScanAt,
    Duration interval,
    DateTime now,
  ) {
    if (lastScanAt == null) return 0.5;
    if (interval <= Duration.zero) return 1;

    final age = now.difference(lastScanAt);
    if (age <= interval) return 1;
    if (age <= interval * 2) return 0.66;
    if (age <= interval * 4) return 0.33;
    return 0;
  }

  static double _output(SourceScanSummary? summary, int? expectedCount) {
    if (summary == null) return 0.5;
    // A skipped scan means "not due yet", not "returned nothing". Treating
    // it as zero would punish every source that is not refreshed this run.
    if (summary.status == SourceScanStatus.skipped) return 0.5;
    final count = summary.songCount;
    if (count <= 0) return 0;
    // A source that asks for fifteen tracks and returns fifteen is at full
    // output even though fifteen is below the old fixed threshold of twenty.
    if (expectedCount != null && expectedCount > 0) {
      return (count / expectedCount).clamp(0.0, 1.0).toDouble();
    }
    if (count < 5) return 0.4;
    if (count < 20) return 0.66;
    return 1;
  }

  static double _speed(SourceScanSummary? summary, Duration timeout) {
    if (summary == null || summary.elapsed <= Duration.zero) return 0.5;
    if (timeout <= Duration.zero) return 0.5;

    final ratio = summary.elapsed.inMilliseconds / timeout.inMilliseconds;
    if (ratio <= 0.25) return 1;
    if (ratio <= 0.5) return 0.7;
    if (ratio <= 0.75) return 0.4;
    return 0.1;
  }
}
