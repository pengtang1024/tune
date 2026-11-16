import 'dart:convert';

/// One slider of the equalizer: a fixed centre frequency and the gain the
/// reader set for it.
class EqualizerBand {
  const EqualizerBand({required this.index, required this.frequency});

  /// Position of the band in the chain, from 0 (lowest) to 9 (highest).
  final int index;

  /// Centre frequency of the band in hertz.
  final double frequency;
}

/// A named curve.
///
/// The curves are constants: a stored `presetId` goes stale the moment one of
/// them is edited, so the panel reads the id back from the gains instead.
class EqualizerPreset {
  const EqualizerPreset({required this.id, required this.gains});

  final String id;

  /// Ten gains, from the lowest band to the highest, in decibels.
  final List<double> gains;
}

/// The ten bands of the equalizer and the curves that come with it.
class EqualizerPresets {
  const EqualizerPresets._();

  static const String flatId = 'flat';
  static const String popId = 'pop';
  static const String rockId = 'rock';
  static const String jazzId = 'jazz';
  static const String classicalId = 'classical';
  static const String bassId = 'bass';
  static const String vocalId = 'vocal';
  static const String electronicId = 'electronic';

  /// The id a curve gets once a slider moved it away from every preset.
  static const String customId = 'custom';

  /// The neutral curve, and the shape the panel resets to.
  static const List<double> flatGains = <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  static const EqualizerPreset flat = EqualizerPreset(
    id: flatId,
    gains: flatGains,
  );

  static const EqualizerPreset pop = EqualizerPreset(
    id: popId,
    gains: <double>[-1, 0, 1, 2, 3, 3, 1, 0, 1, 2],
  );

  static const EqualizerPreset rock = EqualizerPreset(
    id: rockId,
    gains: <double>[4, 3, 2, 1, 0, -1, 1, 2, 3, 4],
  );

  static const EqualizerPreset jazz = EqualizerPreset(
    id: jazzId,
    gains: <double>[3, 2, -1, -1, 1, 2, 2, 1, 2, 3],
  );

  static const EqualizerPreset classical = EqualizerPreset(
    id: classicalId,
    gains: <double>[2, 1, 0, 0, 0, 0, -1, -2, -3, -4],
  );

  static const EqualizerPreset bass = EqualizerPreset(
    id: bassId,
    gains: <double>[6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
  );

  static const EqualizerPreset vocal = EqualizerPreset(
    id: vocalId,
    gains: <double>[-2, -1, 0, 2, 4, 4, 2, 0, -1, -2],
  );

  static const EqualizerPreset electronic = EqualizerPreset(
    id: electronicId,
    gains: <double>[4, 3, 0, -1, -2, 0, 1, 2, 3, 4],
  );

  /// Every preset, in the order the panel draws them.
  static const List<EqualizerPreset> all = <EqualizerPreset>[
    flat,
    pop,
    rock,
    jazz,
    classical,
    bass,
    vocal,
    electronic,
  ];

  static EqualizerPreset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// The preset that carries exactly [gains], or null when the reader moved a
  /// slider away from every curve.
  static EqualizerPreset? matching(List<double> gains) {
    for (final preset in all) {
      if (_sameGains(preset.gains, gains)) return preset;
    }
    return null;
  }

  static bool _sameGains(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What the equalizer does to the sound, and that is all that is stored.
///
/// The settings are one truth for the panel, the filter chain and the button
/// that opens it: gains in decibels, and whether the chain is bypassed.
class EqualizerSettings {
  const EqualizerSettings({required this.enabled, required this.gains});

  /// Bypassed, with a flat curve.
  const EqualizerSettings.flat({this.enabled = false})
    : gains = EqualizerPresets.flatGains;

  final bool enabled;

  /// Ten gains, from the lowest band to the highest, in decibels.
  final List<double> gains;

  static const int bandCount = 10;

  /// Version of the stored shape. A shape of another version is discarded
  /// instead of being read with the wrong field meanings.
  static const int schemaVersion = 1;

  static const double minGain = -12;
  static const double maxGain = 12;
  static const double step = 1;

  /// The ISO octave centres, low to high.
  static const List<double> frequencies = <double>[
    31,
    62,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];

  /// The bands, low to high, for the panel.
  static List<EqualizerBand> get bands => <EqualizerBand>[
    for (var i = 0; i < bandCount; i++)
      EqualizerBand(index: i, frequency: frequencies[i]),
  ];

  /// The gain of one band; a band outside the chain reads as neutral.
  double gainAt(int index) =>
      index >= 0 && index < gains.length ? gains[index] : 0;

  /// Whether every band sits at 0 dB.
  bool get isFlat {
    for (final gain in gains) {
      if (gain != 0) return false;
    }
    return true;
  }

  /// The preamp that keeps the boosted bands from clipping.
  ///
  /// The bands are summed after mpv's own volume stage, so a boost of +6 dB
  /// on one band already clips a signal that was near full scale. Lowering
  /// the preamp by the largest boost keeps the loudest band at or below 0 dB;
  /// the whole curve becomes quieter instead of distorted.
  double get preampDb {
    var peak = 0.0;
    for (final gain in gains) {
      if (gain > peak) peak = gain;
    }
    return peak > 0 ? -peak : 0;
  }

  /// The preset the curve matches, or [EqualizerPresets.customId].
  String get presetId =>
      EqualizerPresets.matching(gains)?.id ?? EqualizerPresets.customId;

  EqualizerSettings copyWith({bool? enabled, List<double>? gains}) {
    return EqualizerSettings(
      enabled: enabled ?? this.enabled,
      gains: gains == null ? this.gains : normalizeGains(gains),
    );
  }

  /// Moves one band, keeping the rest. A gain outside the range is clamped to
  /// it, and a gain between two steps snaps to the nearest one.
  EqualizerSettings withGain(int index, double gain) {
    if (index < 0 || index >= bandCount) return this;
    final clamped = clampGain(gain);
    if (gainAt(index) == clamped) return this;
    final next = <double>[
      for (var i = 0; i < bandCount; i++) i == index ? clamped : gainAt(i),
    ];
    return EqualizerSettings(enabled: enabled, gains: next);
  }

  /// The flat curve, keeping the switch as it is.
  EqualizerSettings resetGains() => copyWith(gains: EqualizerPresets.flatGains);

  /// Reads a stored [raw] value.
  ///
  /// Only an unreadable envelope falls back to the flat curve: a version this
  /// build does not know, JSON that is not an object, or a missing / non-list
  /// `gains`. A readable curve is normalized instead of discarded — a short
  /// list is padded with 0 dB, a long one is truncated to [bandCount] bands,
  /// and an out-of-range gain is clamped by [normalizeGains].
  factory EqualizerSettings.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const EqualizerSettings.flat();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const EqualizerSettings.flat();
      }
      if (decoded['version'] != schemaVersion) {
        return const EqualizerSettings.flat();
      }
      final enabled = decoded['enabled'] == true;
      final storedGains = decoded['gains'];
      if (storedGains is! List) return const EqualizerSettings.flat();
      return EqualizerSettings(
        enabled: enabled,
        gains: normalizeGains(<double>[
          for (var i = 0; i < bandCount; i++)
            if (i < storedGains.length && storedGains[i] is num)
              (storedGains[i] as num).toDouble()
            else
              0,
        ]),
      );
    } on FormatException {
      return const EqualizerSettings.flat();
    }
  }

  String toJson() => jsonEncode(<String, Object?>{
    'version': schemaVersion,
    'enabled': enabled,
    'gains': gains,
  });

  /// A gain inside the range, on a step.
  static double clampGain(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    final stepped = (value / step).round() * step;
    return stepped.clamp(minGain, maxGain).toDouble();
  }

  /// Exactly [bandCount] stepped gains, so a truncated or padded stored curve
  /// cannot reach the filter chain.
  static List<double> normalizeGains(List<double> gains) {
    return List<double>.unmodifiable(<double>[
      for (var i = 0; i < bandCount; i++)
        clampGain(i < gains.length ? gains[i] : 0),
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EqualizerSettings) return false;
    if (other.enabled != enabled) return false;
    if (other.gains.length != gains.length) return false;
    for (var i = 0; i < gains.length; i++) {
      if (other.gains[i] != gains[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(gains));
}
