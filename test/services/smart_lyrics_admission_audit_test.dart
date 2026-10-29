import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission_audit.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';

/// The leave-one-out audit of the admission gate (docs/smart-lyrics.md
/// §7.6, M11b): machines auditing machines — every voice that carried an
/// admission is dropped in turn, and the gate must still stand on the
/// rest. A rotation that settles with different words is a caught miss.
LyricsBallot _ballot(
  String origin,
  BallotKind kind,
  List<String> texts, {
  Duration at = const Duration(seconds: 10),
}) => LyricsBallot(
  origin: origin,
  kind: kind,
  lines: [
    for (var i = 0; i < texts.length; i++)
      BallotLine(start: at + Duration(seconds: i * 2), text: texts[i]),
  ],
);

void main() {
  test('four voices across two classes stand every rotation', () {
    final audit = auditAdmission([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('lrclib-fr', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:whisper-1', BallotKind.machine, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走']),
    ]);

    expect(audit.checked, 1, reason: 'four independent voices are on trial');
    expect(audit.mismatched, 0);
    expect(audit.missRate, 0);
    expect(audit.missRateUpperBound, closeTo(3.0, 0.001),
        reason: 'the rule of three: one audited line with nothing caught');
  });

  test('a two-voice line is not on trial — the gate alone decides it', () {
    final audit = auditAdmission([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走']),
    ]);

    expect(audit.checked, 0, reason: 'no rotation exists with two voices');
  });

  test('a cluster the gate refuses is not on trial', () {
    final audit = auditAdmission([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我叶走']),
    ]);

    expect(audit.checked, 0, reason: 'nothing was admitted; there is '
        'nothing to audit');
  });

  test('an empty pool audits to nothing rather than a crash', () {
    final audit = auditAdmission([]);

    expect(audit.checked, 0);
    expect(audit.missRate, 0);
    expect(audit.missRateUpperBound, 0);
  });

  test('a hundred clean lines bound the miss rate at three-per-N', () {
    final audit = auditAdmission([
      for (var i = 0; i < 100; i++)
        ...[
          _ballot('lrclib', BallotKind.human, ['第$i 行'],
              at: Duration(seconds: 10 + i * 3)),
          _ballot('lrclib-fr', BallotKind.human, ['第$i 行'],
              at: Duration(seconds: 10 + i * 3)),
          _ballot('cloud:whisper-1', BallotKind.machine, ['第$i 行'],
              at: Duration(seconds: 10 + i * 3)),
          _ballot('cloud:paraformer', BallotKind.machine, ['第$i 行'],
              at: Duration(seconds: 10 + i * 3)),
        ],
    ]);

    expect(audit.checked, 100);
    expect(audit.mismatched, 0);
    expect(audit.missRateUpperBound, closeTo(0.03, 0.001),
        reason: 'rule of three: 3/100 — the bound scales with the lines '
            'the machines audited');
  });
}
