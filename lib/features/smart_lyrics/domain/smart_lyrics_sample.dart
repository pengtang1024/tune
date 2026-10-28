/// The stratified sample of the accuracy audit (docs/smart-lyrics.md §10,
/// M3): every「9」of the double numbers is verified against a drawn sample,
/// layer by layer — studio, live, rap, non-Chinese — so a mechanism that
/// only works on one kind of singing cannot hide behind the average.
library;

/// The layer a track is sampled into. The layers do not overlap: the
/// performance a voice reads is the stronger fact, then the genre, then the
/// words — the order is fixed, so a redraw puts a track back where it was.
enum SmartLyricsLayer {
  studio,
  live,
  rap,
  nonChinese;

  /// The name the tables store.
  String get id => name;
}

/// One row of the library as the sampling reads it: the facts a layer is
/// judged on, and no more.
class SmartLyricsCandidate {
  final String uri;
  final String title;
  final String artist;
  final String album;
  final String genre;

  /// The language the tags declared, when they did.
  final String? language;

  const SmartLyricsCandidate({
    required this.uri,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    this.language,
  });
}

/// One drawn track: where it sits and who it is, so the verification round
/// can find it without another query.
class SmartLyricsSampleEntry {
  final String uri;
  final SmartLyricsLayer layer;
  final String title;
  final String artist;

  const SmartLyricsSampleEntry({
    required this.uri,
    required this.layer,
    required this.title,
    required this.artist,
  });
}

/// One layer's share of the drawn sample, and how the verification of it
/// stands.
class SmartLyricsSampleRow {
  final SmartLyricsLayer layer;
  final int drawn;
  final int checked;
  final int correct;

  const SmartLyricsSampleRow({
    required this.layer,
    required this.drawn,
    required this.checked,
    required this.correct,
  });
}

/// The whole sample: what was drawn, what a human checked, what passed.
///
/// The rate counts only the checked rows — an unchecked sample is not a
/// perfect one, and the account does not pretend it is.
class SmartLyricsSampleAccount {
  final List<SmartLyricsSampleRow> layers;

  const SmartLyricsSampleAccount({required this.layers});

  static const SmartLyricsSampleAccount empty = SmartLyricsSampleAccount(
    layers: [],
  );

  int get drawn => layers.fold(0, (sum, row) => sum + row.drawn);

  int get checked => layers.fold(0, (sum, row) => sum + row.checked);

  int get correct => layers.fold(0, (sum, row) => sum + row.correct);

  /// The share of the checked rows a human judged right, `null` while
  /// nothing is checked yet.
  double? get rate => checked == 0 ? null : correct / checked;
}

/// The words a live performance answers to.
final RegExp _livePattern = RegExp(
  r'live|现场',
  caseSensitive: false,
);

/// The words a rap record answers to — the standalone words, not a
/// substring inside another genre's name.
final RegExp _rapPattern = RegExp(
  r'\brap\b|\bhip[- ]?hop\b|说唱|嘻哈|饒舌',
  caseSensitive: false,
);

/// Whether a title carries Chinese characters — the cheap proxy for the
/// words when the tags say nothing.
final RegExp _cjkPattern = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff]');

/// The layer [candidate] is sampled into.
SmartLyricsLayer layerOf(SmartLyricsCandidate candidate) {
  final titles = '${candidate.title} ${candidate.album}';
  if (_livePattern.hasMatch(titles)) return SmartLyricsLayer.live;
  if (_rapPattern.hasMatch(candidate.genre)) return SmartLyricsLayer.rap;
  final language = candidate.language;
  final declaredForeign = language != null && language.isNotEmpty
      ? !language.startsWith('zh')
      : null;
  if (declaredForeign ?? !_cjkPattern.hasMatch(candidate.title)) {
    return SmartLyricsLayer.nonChinese;
  }
  return SmartLyricsLayer.studio;
}

/// Draws at most [perLayer] tracks per layer out of [candidates].
///
/// The draw is a function of the pool and [seed] alone: the order a track
/// takes comes from a hash of the seed and its uri — a hash that does not
/// change from run to run — so the same library redraws the same set and a
/// verification round can be continued instead of restarted.
List<SmartLyricsSampleEntry> drawStratified(
  List<SmartLyricsCandidate> candidates, {
  required int perLayer,
  required int seed,
}) {
  final pooled = <SmartLyricsLayer, List<SmartLyricsCandidate>>{};
  for (final candidate in candidates) {
    pooled.putIfAbsent(layerOf(candidate), () => []).add(candidate);
  }

  final drawn = <SmartLyricsSampleEntry>[];
  for (final layer in SmartLyricsLayer.values) {
    final pool = pooled[layer];
    if (pool == null) continue;
    final keyed = [
      for (final candidate in pool)
        (hash: _stableHash('$seed/${candidate.uri}'), candidate: candidate),
    ]..sort((a, b) => a.hash.compareTo(b.hash));
    drawn.addAll([
      for (final keyedEntry in keyed.take(perLayer))
        SmartLyricsSampleEntry(
          uri: keyedEntry.candidate.uri,
          layer: layer,
          title: keyedEntry.candidate.title,
          artist: keyedEntry.candidate.artist,
        ),
    ]);
  }
  return drawn;
}

/// A hash that stays what it is across runs, unlike `Object.hash` — the
/// draw has to survive a restart to be continued.
int _stableHash(String value) {
  var hash = 0xcbf29ce484222325;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash;
}
