/// What the reader did with one track, as far as the discover page needs it.
///
/// The signal is an aggregate, not a history: it says how often the track was
/// played, skipped or finished, and when it was last touched. It never stores
/// a timeline and never leaves the machine.
class TrackListening {
  final int listens;
  final int skips;
  final int completions;
  final int listenedMs;
  final DateTime? lastPlayedAt;

  const TrackListening({
    this.listens = 0,
    this.skips = 0,
    this.completions = 0,
    this.listenedMs = 0,
    this.lastPlayedAt,
  });

  TrackListening recordListen({
    required Duration listened,
    required bool completed,
    required DateTime at,
  }) {
    final milliseconds = listened.inMilliseconds
        .clamp(0, 24 * 60 * 60 * 1000)
        .toInt();
    return TrackListening(
      listens: listens + 1,
      skips: skips,
      completions: completions + (completed ? 1 : 0),
      listenedMs: listenedMs + milliseconds,
      lastPlayedAt: at,
    );
  }

  TrackListening recordSkip({required DateTime at}) {
    return TrackListening(
      listens: listens,
      skips: skips + 1,
      completions: completions,
      listenedMs: listenedMs,
      lastPlayedAt: at,
    );
  }

  Map<String, dynamic> toJson() => {
    'listens': listens,
    'skips': skips,
    'completions': completions,
    'listenedMs': listenedMs,
    'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
  };

  factory TrackListening.fromJson(Map<String, dynamic> data) {
    final playedAt = data['lastPlayedAt'];
    return TrackListening(
      listens: _positiveInt(data['listens']),
      skips: _positiveInt(data['skips']),
      completions: _positiveInt(data['completions']),
      listenedMs: _positiveInt(data['listenedMs']),
      lastPlayedAt: playedAt is num && playedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(playedAt.toInt())
          : null,
    );
  }
}

int _positiveInt(Object? value) {
  if (value is! num || value <= 0) return 0;
  return value.toInt();
}
