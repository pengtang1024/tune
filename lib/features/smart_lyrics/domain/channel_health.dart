/// How one channel of the smart lyrics pipeline answered recently — the
/// mechanism the music sources live by, applied to the channels the pool
/// asks (docs/smart-lyrics.md §7.2).
///
/// A channel under the threshold waits out the round instead of being
/// asked again: LRCLIB unreachable, a dead endpoint, a binary that keeps
/// exiting — each failure lands here and the pool stops spending on it.
/// Unlike the sources, an unasked channel starts healthy: one cheap
/// question settles whether it answers, and only real failures take it
/// down — a channel's silence is not evidence, its failures are.
library;

/// One answer a channel gave.
enum ChannelOutcome {
  /// The channel answered with words.
  success,

  /// The channel answered, but with no words — an instrumental, not a
  /// broken channel.
  empty,

  /// The channel did not answer: a transport error, a crash, a timeout.
  failure,
}

/// A channel's health, weighted from the recent ring of its answers.
class ChannelHealth {
  /// The score a channel needs to keep being asked.
  static const int threshold = 60;

  /// The outcomes the ring keeps — the past that still counts.
  static const int ringSize = 10;

  /// The weights of the ring, most recent first: the recent past weighs
  /// more than the old, so a channel that came back climbs and one that
  /// went quiet sinks.
  static const List<double> _weights = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

  final int score;

  const ChannelHealth(this.score);

  /// The health of a channel from its answers, newest last.
  ///
  /// No history is full health: the mechanism forgives the unasked and
  /// judges only what answered. The ring holds the last [ringSize]
  /// outcomes; older ones fall off, so a failure is never forever.
  factory ChannelHealth.fromOutcomes(List<ChannelOutcome> outcomes) {
    if (outcomes.isEmpty) return const ChannelHealth(100);
    final recent = outcomes.length > ringSize
        ? outcomes.sublist(outcomes.length - ringSize)
        : outcomes;

    var weighted = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < recent.length; i++) {
      // The newest outcome takes the heaviest slot of the ring.
      final weight = _weights[recent.length - 1 - i];
      weighted += _valueOf(recent[i]) * weight;
      totalWeight += weight;
    }
    return ChannelHealth(((weighted / totalWeight) * 100).round());
  }

  static double _valueOf(ChannelOutcome outcome) => switch (outcome) {
    ChannelOutcome.success => 1,
    // Silence is an answer: the track may have no voice at all.
    ChannelOutcome.empty => 0.8,
    ChannelOutcome.failure => 0,
  };

  /// Whether the channel keeps being asked.
  bool get usable => score >= threshold;
}
