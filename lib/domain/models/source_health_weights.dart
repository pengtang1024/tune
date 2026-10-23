/// How much each dimension of the source health contributes to the score.
///
/// The weights do not have to add up to 100: the score normalizes them. A
/// weight of 0 removes a dimension from the score entirely. The hard gates
/// (unavailable, unconfigured, failed, local) stay independent of this.
class SourceHealthWeights {
  final int availability;
  final int configuration;
  final int scan;
  final int freshness;
  final int output;
  final int speed;
  final int reliability;
  final int stability;
  final int coverage;
  final int activity;

  static const SourceHealthWeights defaults = SourceHealthWeights(
    availability: 10,
    configuration: 15,
    scan: 15,
    freshness: 10,
    output: 10,
    speed: 5,
    reliability: 10,
    stability: 10,
    coverage: 10,
    activity: 5,
  );

  const SourceHealthWeights({
    required this.availability,
    required this.configuration,
    required this.scan,
    required this.freshness,
    required this.output,
    required this.speed,
    required this.reliability,
    required this.stability,
    required this.coverage,
    required this.activity,
  });

  int get total =>
      availability +
      configuration +
      scan +
      freshness +
      output +
      speed +
      reliability +
      stability +
      coverage +
      activity;

  SourceHealthWeights copyWith({
    int? availability,
    int? configuration,
    int? scan,
    int? freshness,
    int? output,
    int? speed,
    int? reliability,
    int? stability,
    int? coverage,
    int? activity,
  }) {
    return SourceHealthWeights(
      availability: availability ?? this.availability,
      configuration: configuration ?? this.configuration,
      scan: scan ?? this.scan,
      freshness: freshness ?? this.freshness,
      output: output ?? this.output,
      speed: speed ?? this.speed,
      reliability: reliability ?? this.reliability,
      stability: stability ?? this.stability,
      coverage: coverage ?? this.coverage,
      activity: activity ?? this.activity,
    );
  }

  factory SourceHealthWeights.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback) {
      final value = json[key];
      if (value is num) return value.toInt().clamp(0, 100);
      return fallback;
    }

    const fallback = defaults;
    return SourceHealthWeights(
      availability: read('availability', fallback.availability),
      configuration: read('configuration', fallback.configuration),
      scan: read('scan', fallback.scan),
      freshness: read('freshness', fallback.freshness),
      output: read('output', fallback.output),
      speed: read('speed', fallback.speed),
      reliability: read('reliability', fallback.reliability),
      stability: read('stability', fallback.stability),
      coverage: read('coverage', fallback.coverage),
      activity: read('activity', fallback.activity),
    );
  }

  Map<String, dynamic> toJson() => {
    'availability': availability,
    'configuration': configuration,
    'scan': scan,
    'freshness': freshness,
    'output': output,
    'speed': speed,
    'reliability': reliability,
    'stability': stability,
    'coverage': coverage,
    'activity': activity,
  };
}
