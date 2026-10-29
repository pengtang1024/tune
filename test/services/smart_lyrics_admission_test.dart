import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_admission.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';

/// The admission gate of §7.6 (M10): a line lands in the sheet only when
/// two independent lineage classes read the same words — 宁缺勿错, and the
/// criterion is what guarantees the 99.99%, not an audit.
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
      BallotLine(
        start: at + Duration(seconds: i * 2),
        text: texts[i],
      ),
  ],
);

void main() {
  test('the families know their kin', () {
    expect(asrFamilyOf('whisper-1'), asrFamilyOf('whisper-large-v3'));
    expect(asrFamilyOf('tiny'), asrFamilyOf('whisper-1'),
        reason: 'a local whisper is still whisper — same algorithm, same '
            'blind spots; it cannot cross-prove a cloud whisper');
    expect(asrFamilyOf('paraformer'), isNot(asrFamilyOf('whisper-1')));
    expect(llmFamilyOf('gpt-4o-mini'), llmFamilyOf('gpt-4o'));
    expect(llmFamilyOf('deepseek-chat'), isNot(llmFamilyOf('mimo-v2.6-flash')));
  });

  test('a human sheet plus a second class with two voices admits', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走']),
      _ballot('cloud:sensevoice', BallotKind.machine, ['月亮走我也走']),
    ]);

    final line = consensus.lines.single;
    expect(line.disputed, isFalse);
    expect(line.text, '月亮走我也走');
  });

  test('a single class never admits — even three of a kind', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('lrclib-2', BallotKind.human, ['月亮走我也走']),
    ]);

    expect(consensus.lines.single.disputed, isTrue,
        reason: 'two sources of one lineage can be wrong together — the '
            'product of error rates needs independent classes');
  });

  test('two ASR families alone are still one class — no admission', () {
    final consensus = admit([
      _ballot('cloud:whisper-1', BallotKind.machine, ['我送阿哥到村口']),
      _ballot('cloud:paraformer', BallotKind.machine, ['我送阿哥到村口']),
    ]);

    expect(consensus.lines.single.disputed, isTrue,
        reason: 'one class, however many families inside it — admission '
            'needs two independent classes reading the same words');
  });

  test('two revisions of one ASR family do not admit', () {
    final consensus = admit([
      _ballot('cloud:whisper-1', BallotKind.machine, ['我送阿哥到村口']),
      _ballot('local:tiny', BallotKind.machine, ['我送阿哥到村口']),
    ]);

    expect(consensus.lines.single.disputed, isTrue,
        reason: 'whisper and whisper are one voice wearing two hats');
  });

  test('classes that disagree admit nothing', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我叶走']),
    ]);

    expect(consensus.lines.every((line) => line.disputed), isTrue);
  });

  test('a contested human class falls silent', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('lrclib-2', BallotKind.human, ['月亮走我叶走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我叶走']),
    ]);

    final line = consensus.lines.single;
    expect(line.disputed, isTrue,
        reason: 'the human class is of two voices and falls silent; the '
            'machine class has one family — nobody speaks with a second '
            'independent voice, the line stays a gap');
  });

  test('the wording the reader sees prefers the human sheet', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走 ']),
      _ballot('cloud:SenseVoice', BallotKind.machine, ['月亮走我也走']),
    ]);

    final line = consensus.lines.single;
    expect(line.disputed, isFalse);
    expect(line.text.trim(), '月亮走我也走');
  });

  test('text that agrees but time that does not stays a gap', () {
    final consensus = admit([
      _ballot('lrclib', BallotKind.human, ['月亮走我也走']),
      _ballot(
        'cloud:paraformer',
        BallotKind.machine,
        ['月亮走我也走'],
        at: const Duration(milliseconds: 10800),
      ),
      _ballot(
        'cloud:SenseVoice',
        BallotKind.machine,
        ['月亮走我也走'],
        at: const Duration(milliseconds: 10800),
      ),
    ]);

    final line = consensus.lines.single;
    expect(line.disputed, isTrue,
        reason: 'the two classes read the same words but their measurements '
            'of when the line is sung are 0.8s apart — inside the same cluster, past the 0.5s tolerance — a subtitle that drifts '
            'is wrong even when the words are right');
  });

  test('two LLM families rebuild the same line — the knowledge class speaks', () {
    final consensus = admit(
      [
        _ballot('cloud:whisper-1', BallotKind.machine, ['月亮走我也走']),
        _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走']),
      ],
      knowledge: [
        _ballot('knowledge:gpt-4o', BallotKind.knowledge, ['月亮走我也走']),
        _ballot('knowledge:deepseek-chat', BallotKind.knowledge, ['月亮走我也走']),
      ],
    );

    final line = consensus.lines.single;
    expect(line.disputed, isFalse,
        reason: 'B class forms from two LLM families; C class from two '
            'ASR families — two classes read the same words');
    expect(line.text.trim(), '月亮走我也走');
  });

  test('one LLM family keeps the knowledge class silent', () {
    final consensus = admit(
      [
        _ballot('cloud:whisper-1', BallotKind.machine, ['月亮走我也走']),
        _ballot('cloud:paraformer', BallotKind.machine, ['月亮走我也走']),
      ],
      knowledge: [
        _ballot('knowledge:gpt-4o', BallotKind.knowledge, ['月亮走我也走']),
        _ballot('knowledge:gpt-4o-mini', BallotKind.knowledge, ['月亮走我也走']),
      ],
    );

    final line = consensus.lines.single;
    expect(line.disputed, isTrue,
        reason: 'two gpt revisions are one voice wearing two hats — the '
            'knowledge class needs two families to speak');
  });
}
