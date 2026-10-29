import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/channel_health.dart';

/// The health of the smart lyrics channels (docs/smart-lyrics.md §7.2):
/// the same mechanism the music sources live by — recent outcomes weigh
/// the score, a channel under the threshold waits out the round instead
/// of being asked again. Unlike the sources, an unasked channel is
/// healthy by default: one cheap question settles whether it answers, and
/// only real failures take it down.
void main() {
  test('a channel that never failed is trusted', () {
    final health = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 5; i++) ChannelOutcome.success,
    ]);

    expect(health.score, greaterThanOrEqualTo(ChannelHealth.threshold));
  });

  test('a channel that keeps failing falls under the threshold', () {
    final health = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 6; i++) ChannelOutcome.failure,
    ]);

    expect(health.score, lessThan(ChannelHealth.threshold));
  });

  test('the recent past weighs more than the old', () {
    final recovered = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 6; i++) ChannelOutcome.failure,
      for (var i = 0; i < 4; i++) ChannelOutcome.success,
    ]);
    final sinking = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 6; i++) ChannelOutcome.success,
      for (var i = 0; i < 4; i++) ChannelOutcome.failure,
    ]);

    expect(recovered.score, greaterThan(sinking.score),
        reason: 'a source that came back climbs; one that went quiet sinks');
  });

  test('an answer that carried no words is neither success nor failure', () {
    final emptyish = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 6; i++) ChannelOutcome.empty,
    ]);

    expect(emptyish.score, greaterThanOrEqualTo(ChannelHealth.threshold),
        reason: 'silence is an answer — the instrumental is not the '
            'channel\'s fault');
  });

  test('a channel with no history is trusted until it proves otherwise', () {
    expect(ChannelHealth.fromOutcomes([]).score,
        greaterThanOrEqualTo(ChannelHealth.threshold));
  });

  test('the ring keeps only the last outcomes', () {
    final health = ChannelHealth.fromOutcomes([
      for (var i = 0; i < 30; i++) ChannelOutcome.failure,
      ChannelOutcome.success,
    ]);

    expect(health.score, lessThan(ChannelHealth.threshold),
        reason: 'one good answer after a long failure streak does not '
            'whitewash it — recovery takes a streak, and the oldest '
            'failures fall off the ring as the streak grows');
  });
}
