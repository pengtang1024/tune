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
  final int playable;
  final int artwork;
  final int metadata;
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
    playable: 6,
    artwork: 10,
    metadata: 2,
    activity: 5,
  );

  /// The default preset: every dimension keeps its balanced weight.
  static const SourceHealthWeights balanced = defaults;

  /// A source that answers and plays is worth more than one with pretty
  /// covers: setup, scan, reliability and playable carry the score.
  static const SourceHealthWeights playableFirst = SourceHealthWeights(
    availability: 20,
    configuration: 15,
    scan: 15,
    freshness: 5,
    output: 5,
    speed: 5,
    reliability: 15,
    stability: 10,
    playable: 10,
    artwork: 0,
    metadata: 0,
    activity: 0,
  );

  /// A fresh catalogue matters more than the artwork: the new sources rise.
  static const SourceHealthWeights freshFirst = SourceHealthWeights(
    availability: 10,
    configuration: 5,
    scan: 5,
    freshness: 25,
    output: 15,
    speed: 5,
    reliability: 5,
    stability: 5,
    playable: 5,
    artwork: 10,
    metadata: 5,
    activity: 10,
  );

  static const List<SourceHealthWeights> presets = [
    balanced,
    playableFirst,
    freshFirst,
  ];

  const SourceHealthWeights({
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
      playable +
      artwork +
      metadata +
      activity;

  @override
  bool operator ==(Object other) =>
      other is SourceHealthWeights &&
      other.availability == availability &&
      other.configuration == configuration &&
      other.scan == scan &&
      other.freshness == freshness &&
      other.output == output &&
      other.speed == speed &&
      other.reliability == reliability &&
      other.stability == stability &&
      other.playable == playable &&
      other.artwork == artwork &&
      other.metadata == metadata &&
      other.activity == activity;

  @override
  int get hashCode => Object.hash(
    availability,
    configuration,
    scan,
    freshness,
    output,
    speed,
    reliability,
    stability,
    playable,
    artwork,
    metadata,
    activity,
  );

  SourceHealthWeights copyWith({
    int? availability,
    int? configuration,
    int? scan,
    int? freshness,
    int? output,
    int? speed,
    int? reliability,
    int? stability,
    int? playable,
    int? artwork,
    int? metadata,
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
      playable: playable ?? this.playable,
      artwork: artwork ?? this.artwork,
      metadata: metadata ?? this.metadata,
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
    // A configuration written before the split stored one `coverage` weight
    // for playable + artwork + metadata together. Keep the old 6/2/2 split
    // so a reader who had tuned it does not lose that tuning.
    final legacyCoverage = json['coverage'];
    int readFact(String key, int fallback, double share) {
      if (json.containsKey(key)) return read(key, fallback);
      if (legacyCoverage is num) {
        return (legacyCoverage.toInt().clamp(0, 100) * share).round();
      }
      return fallback;
    }

    return SourceHealthWeights(
      availability: read('availability', fallback.availability),
      configuration: read('configuration', fallback.configuration),
      scan: read('scan', fallback.scan),
      freshness: read('freshness', fallback.freshness),
      output: read('output', fallback.output),
      speed: read('speed', fallback.speed),
      reliability: read('reliability', fallback.reliability),
      stability: read('stability', fallback.stability),
      playable: readFact('playable', fallback.playable, 0.6),
      artwork: readFact('artwork', fallback.artwork, 0.2),
      metadata: readFact('metadata', fallback.metadata, 0.2),
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
    'playable': playable,
    'artwork': artwork,
    'metadata': metadata,
    'activity': activity,
  };
}
