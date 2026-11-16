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
  const EqualizerPreset({required this.id, required this.gains, this.name});

  final String id;

  /// Ten gains, from the lowest band to the highest, in decibels.
  final List<double> gains;

  /// The reader's own label. Built-in curves carry none: their label comes
  /// from the translation file, so renaming a language does not stale it.
  final String? name;
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
  static const String acousticId = 'acoustic';
  static const String hiphopId = 'hiphop';
  static const String liveId = 'live';
  static const String softId = 'soft';

  /// The id a curve gets once a slider moved it away from every preset.
  static const String customId = 'custom';

  /// Prefix of the ids the reader's own presets get.
  static const String userPresetPrefix = 'user-';

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

  static const EqualizerPreset acoustic = EqualizerPreset(
    id: acousticId,
    gains: <double>[4, 3, 2, 1, 1, 1, 1, 2, 2, 2],
  );

  static const EqualizerPreset hiphop = EqualizerPreset(
    id: hiphopId,
    gains: <double>[7, 6, 4, 1, 0, -1, 0, 1, 3, 3],
  );

  static const EqualizerPreset live = EqualizerPreset(
    id: liveId,
    gains: <double>[4, 3, 1, -1, -1, 0, 1, 2, 3, 2],
  );

  static const EqualizerPreset soft = EqualizerPreset(
    id: softId,
    gains: <double>[2, 1, 0, 0, -1, -1, -2, -2, -3, -4],
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
    acoustic,
    hiphop,
    live,
    soft,
  ];

  /// The curves the player panel offers: four a listener picks by mood.
  ///
  /// Ten sliders and twelve curves do not belong beside a track row and a
  /// volume thumb. The rest of [all] lives in the settings editor, and the
  /// panel says so in one line of small print.
  static const List<EqualizerPreset> quick = <EqualizerPreset>[
    flat,
    pop,
    rock,
    bass,
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
      if (sameGains(preset.gains, gains)) return preset;
    }
    return null;
  }

  /// Whether two curves hold the same gains, band by band.
  static bool sameGains(List<double> a, List<double> b) {
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
  const EqualizerSettings({
    required this.enabled,
    required this.gains,
    this.userPresets = const <EqualizerPreset>[],
    this.bandWidth = defaultBandWidth,
    this.preampOverrideDb,
  });

  /// Bypassed, with a flat curve.
  const EqualizerSettings.flat({this.enabled = false})
    : gains = EqualizerPresets.flatGains,
      userPresets = const <EqualizerPreset>[],
      bandWidth = defaultBandWidth,
      preampOverrideDb = null;

  final bool enabled;

  /// Ten gains, from the lowest band to the highest, in decibels.
  final List<double> gains;

  /// The curves the reader saved, oldest first. Each carries a label; built-in
  /// curves do not, because their label comes from the translation file.
  final List<EqualizerPreset> userPresets;

  /// How much of the spectrum one band moves, in octaves. One octave is the
  /// layout the ten centres were chosen for; a third of an octave turns each
  /// band into a narrow notch that leaves its neighbours alone.
  final double bandWidth;

  /// The preamp the reader set by hand, in decibels, or null to follow the
  /// loudest boost. Following the boost is right most of the time; lifting it
  /// by hand is how a quiet recording gets its level back.
  final double? preampOverrideDb;

  /// Built-in curves first, then the reader's own, in the order they are drawn.
  List<EqualizerPreset> get allPresets => <EqualizerPreset>[
    ...EqualizerPresets.all,
    ...userPresets,
  ];

  /// The preset behind [id], whether it ships with the app or the reader saved
  /// it.
  EqualizerPreset? findPreset(String id) {
    for (final preset in allPresets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static const int bandCount = 10;

  /// Version of the stored shape. A shape of another version is discarded
  /// instead of being read with the wrong field meanings.
  static const int schemaVersion = 1;

  static const double minGain = -12;
  static const double maxGain = 12;

  /// Half a decibel per step: a whole decibel is too coarse to hear the last
  /// move of a band, and ffmpeg takes the decimal gain as written.
  static const double step = 0.5;

  /// One octave per band is the ISO layout the ten centres were chosen for.
  static const double defaultBandWidth = 1;

  /// The widths the panel offers, widest first, in octaves.
  static const List<double> bandWidths = <double>[1, 2 / 3, 0.5, 1 / 3];

  static const double minPreampDb = -24;
  static const double maxPreampDb = 0;

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
    final override = preampOverrideDb;
    if (override != null) return clampPreamp(override);
    var peak = 0.0;
    for (final gain in gains) {
      if (gain > peak) peak = gain;
    }
    return peak > 0 ? -peak : 0;
  }

  /// The preset the curve matches, or [EqualizerPresets.customId].
  ///
  /// Built-in curves win a tie: a reader who dragged a curve back onto a
  /// shipped preset sees that preset's name, not one of their own that happens
  /// to be identical.
  String get presetId {
    final builtIn = EqualizerPresets.matching(gains);
    if (builtIn != null) return builtIn.id;
    for (final preset in userPresets) {
      if (EqualizerPresets.sameGains(preset.gains, gains)) return preset.id;
    }
    return EqualizerPresets.customId;
  }

  EqualizerSettings copyWith({
    bool? enabled,
    List<double>? gains,
    List<EqualizerPreset>? userPresets,
    double? bandWidth,
    double? preampOverrideDb,
    bool useAutoPreamp = false,
  }) {
    return EqualizerSettings(
      enabled: enabled ?? this.enabled,
      gains: gains == null ? this.gains : normalizeGains(gains),
      userPresets: userPresets ?? this.userPresets,
      bandWidth: bandWidth == null
          ? this.bandWidth
          : clampBandWidth(bandWidth),
      preampOverrideDb: useAutoPreamp
          ? null
          : (preampOverrideDb == null
                ? this.preampOverrideDb
                : clampPreamp(preampOverrideDb)),
    );
  }

  /// Saves the current curve as [name], keeping every other stored curve.
  ///
  /// A name already in the list is overwritten in place (same id, new gains),
  /// so saving twice under one label does not pile up duplicates. [id] is only
  /// used for a new entry; an overwrite keeps the id it already had.
  EqualizerSettings saveCurrentAsPreset(String name, {required String id}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return this;
    final saved = <EqualizerPreset>[];
    var replaced = false;
    for (final preset in userPresets) {
      if (!replaced && preset.name == trimmed) {
        saved.add(EqualizerPreset(id: preset.id, name: trimmed, gains: gains));
        replaced = true;
      } else {
        saved.add(preset);
      }
    }
    if (!replaced) {
      saved.add(EqualizerPreset(id: id, name: trimmed, gains: gains));
    }
    return copyWith(userPresets: List<EqualizerPreset>.unmodifiable(saved));
  }

  /// Drops one saved curve. The gains stay where they are, so the panel shows
  /// [EqualizerPresets.customId] if the curve was the one being used.
  EqualizerSettings removePreset(String id) {
    if (!userPresets.any((preset) => preset.id == id)) return this;
    return copyWith(
      userPresets: List<EqualizerPreset>.unmodifiable(<EqualizerPreset>[
        for (final preset in userPresets)
          if (preset.id != id) preset,
      ]),
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
    return EqualizerSettings(
      enabled: enabled,
      gains: next,
      userPresets: userPresets,
      bandWidth: bandWidth,
      preampOverrideDb: preampOverrideDb,
    );
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
        userPresets: _readUserPresets(decoded['userPresets']),
        bandWidth: clampBandWidth(
          decoded['bandWidth'] is num
              ? (decoded['bandWidth'] as num).toDouble()
              : defaultBandWidth,
        ),
        preampOverrideDb: decoded['preampDb'] is num
            ? clampPreamp((decoded['preampDb'] as num).toDouble())
            : null,
      );
    } on FormatException {
      return const EqualizerSettings.flat();
    }
  }

  String toJson() => jsonEncode(<String, Object?>{
    'version': schemaVersion,
    'enabled': enabled,
    'gains': gains,
    // Defaults stay unwritten, so a file from before these fields existed
    // reads the same after a save that never touched them.
    if (bandWidth != defaultBandWidth) 'bandWidth': bandWidth,
    if (preampOverrideDb != null) 'preampDb': preampOverrideDb,
    // Written only when there is something to write: a reader who never saved
    // a curve keeps the file it had before this field existed.
    if (userPresets.isNotEmpty)
      'userPresets': <Object?>[
        for (final preset in userPresets)
          <String, Object?>{
            'id': preset.id,
            'name': preset.name,
            'gains': preset.gains,
          },
      ],
  });

  /// Reads the saved curves, dropping the ones that cannot be trusted.
  ///
  /// One bad entry does not cost the reader the others: an entry without a
  /// usable id, label or gain list is skipped, and every kept curve is
  /// normalized like the live one.
  static List<EqualizerPreset> _readUserPresets(Object? raw) {
    if (raw is! List) return const <EqualizerPreset>[];
    final presets = <EqualizerPreset>[];
    final seen = <String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final id = entry['id'];
      final name = entry['name'];
      final gains = entry['gains'];
      if (id is! String || id.isEmpty || !seen.add(id)) continue;
      if (name is! String || name.trim().isEmpty) continue;
      if (gains is! List) continue;
      presets.add(
        EqualizerPreset(
          id: id,
          name: name.trim(),
          gains: normalizeGains(<double>[
            for (var i = 0; i < bandCount; i++)
              if (i < gains.length && gains[i] is num)
                (gains[i] as num).toDouble()
              else
                0,
          ]),
        ),
      );
    }
    return List<EqualizerPreset>.unmodifiable(presets);
  }

  /// A gain inside the range, on a step.
  static double clampGain(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    final stepped = (value / step).round() * step;
    return stepped.clamp(minGain, maxGain).toDouble();
  }

  /// A width the filter can take: one of [bandWidths], or the nearest one.
  static double clampBandWidth(double value) {
    if (value.isNaN || value.isInfinite) return defaultBandWidth;
    var best = bandWidths.first;
    var bestGap = (value - best).abs();
    for (final width in bandWidths) {
      final gap = (value - width).abs();
      if (gap < bestGap) {
        best = width;
        bestGap = gap;
      }
    }
    return best;
  }

  /// A preamp inside [minPreampDb]..[maxPreampDb], on a whole decibel.
  static double clampPreamp(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value.roundToDouble().clamp(minPreampDb, maxPreampDb).toDouble();
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
    if (other.bandWidth != bandWidth) return false;
    if (other.preampOverrideDb != preampOverrideDb) return false;
    if (other.gains.length != gains.length) return false;
    for (var i = 0; i < gains.length; i++) {
      if (other.gains[i] != gains[i]) return false;
    }
    if (other.userPresets.length != userPresets.length) return false;
    for (var i = 0; i < userPresets.length; i++) {
      final mine = userPresets[i];
      final theirs = other.userPresets[i];
      if (mine.id != theirs.id || mine.name != theirs.name) return false;
      if (!EqualizerPresets.sameGains(mine.gains, theirs.gains)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    bandWidth,
    preampOverrideDb ?? -1,
    Object.hashAll(gains),
    Object.hashAll(
      userPresets.map((preset) => Object.hash(preset.id, preset.name)),
    ),
  );
}
